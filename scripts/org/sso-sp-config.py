#!/usr/bin/env python3
"""CMN-00-TDO-002 포털 SSO — Salesforce(SP) SAML 설정을 IdP 메타데이터 XML로 만들어 배포한다.

사용:
  python3 scripts/org/sso-sp-config.py <sp-alias> <idp-metadata.xml> [--name CMN_PortalSso] [--error-url URL] [--dry-run]

- 사용자 매칭: 어설션 Subject NameID = User.FederationIdentifier(= 사번, BR-1).
- JIT: CMN_SamlJitHandler(사용자를 만들지 않고 언어만 갱신, BR-3). 실행 사용자 = SP Org 관리자.
- 인증서·엔드포인트는 환경마다 달라 저장소에 메타데이터로 두지 않는다. 이 스크립트가 임시 폴더(mdapi 형식)에 만들어 배포한다
  (프로젝트 밖 경로를 소스 형식으로 배포하면 소스 추적이 깨지므로 --metadata-dir을 쓴다).
- 오류 URL(--error-url): 권한 없음 안내 페이지(Visualforce CMN_SsoNoAccess)를 공개 사이트로 노출한 주소(BR-3, AC-3).
"""
import argparse
import json
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.sax.saxutils import escape

NS = {'md': 'urn:oasis:names:tc:SAML:2.0:metadata', 'ds': 'http://www.w3.org/2000/09/xmldsig#'}
API = '66.0'


def sf(args):
    out = subprocess.run(['sf', *args, '--json'], capture_output=True, text=True)
    data = json.loads(out.stdout or '{}')
    if data.get('status', 1) != 0:
        failures = (data.get('result') or {}).get('details', {}).get('componentFailures') or []
        if isinstance(failures, dict):
            failures = [failures]
        detail = '; '.join(f"{f.get('fullName')}: {f.get('problem')}" for f in failures)
        sys.exit(f"sf {' '.join(args[:3])} 실패: {data.get('message') or detail or out.stderr[:300]}")
    return data['result']


def idp_values(path):
    root = ET.parse(path).getroot()
    idp = root.find('md:IDPSSODescriptor', NS)
    if idp is None:
        sys.exit('IDPSSODescriptor가 없습니다(IdP 메타데이터가 아님)')
    cert = None
    for kd in idp.findall('md:KeyDescriptor', NS):
        if kd.get('use') in (None, 'signing'):
            cert = kd.find('.//ds:X509Certificate', NS).text.strip().replace('\n', '')
            break
    redirect = post = None
    for s in idp.findall('md:SingleSignOnService', NS):
        if s.get('Binding', '').endswith('HTTP-Redirect'):
            redirect = s.get('Location')
        elif s.get('Binding', '').endswith('HTTP-POST'):
            post = s.get('Location')
    if not cert or not (redirect or post):
        sys.exit('서명 인증서 또는 SSO 엔드포인트가 없습니다')
    return root.get('entityID'), redirect or post, redirect is not None, cert


def ensure_certificate(alias, name):
    """SP 요청 서명용 자체 서명 인증서(없으면 만든다). 반환: 15자 Id."""
    q = f"SELECT Id FROM Certificate WHERE DeveloperName = '{name}'"
    rows = sf(['data', 'query', '-o', alias, '--use-tooling-api', '-q', q])['records']
    if not rows:
        with tempfile.TemporaryDirectory() as tmp:
            d = Path(tmp)
            (d / 'certs').mkdir()
            (d / 'certs' / f'{name}.crt-meta.xml').write_text(
                '<?xml version="1.0" encoding="UTF-8"?>\n<Certificate xmlns="http://soap.sforce.com/2006/04/metadata">\n'
                '    <caSigned>false</caSigned>\n    <encryptedWithPlatformEncryption>false</encryptedWithPlatformEncryption>\n'
                f'    <keySize>2048</keySize>\n    <masterLabel>{name}</masterLabel>\n'
                '    <privateKeyExportable>false</privateKeyExportable>\n</Certificate>\n', encoding='utf-8')
            (d / 'package.xml').write_text(
                '<?xml version="1.0" encoding="UTF-8"?>\n<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n'
                f'    <types><members>{name}</members><name>Certificate</name></types>\n'
                f'    <version>{API}</version>\n</Package>\n', encoding='utf-8')
            sf(['project', 'deploy', 'start', '--metadata-dir', str(d), '-o', alias, '-w', '10'])
        rows = sf(['data', 'query', '-o', alias, '--use-tooling-api', '-q', q])['records']
    return rows[0]['Id'][:15]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('alias')
    ap.add_argument('metadata')
    ap.add_argument('--name', default='CMN_PortalSso')
    ap.add_argument('--error-url', default='')
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()

    issuer, login_url, redirect, cert = idp_values(a.metadata)
    org = sf(['org', 'display', '-o', a.alias])
    sp = org['instanceUrl']
    # JIT 핸들러·실행 사용자는 15자 Id로 지정한다
    jit = sf(['data', 'query', '-o', a.alias, '-q', "SELECT Id FROM ApexClass WHERE Name = 'CMN_SamlJitHandler'"])['records']
    runner = sf(['data', 'query', '-o', a.alias, '-q', f"SELECT Id FROM User WHERE Username = '{org['username']}'"])['records']
    if not jit or not runner:
        sys.exit('CMN_SamlJitHandler 또는 실행 사용자를 찾을 수 없습니다')
    signing = ensure_certificate(a.alias, a.name + 'Sp')
    body = {
        'name': a.name,
        'errorUrl': a.error_url,
        'executionUserId': runner[0]['Id'][:15],
        'identityLocation': 'SubjectNameId',
        'identityMapping': 'FederationId',
        'issuer': issuer,
        'loginUrl': login_url,
        'redirectBinding': 'true' if redirect else 'false',
        'requestSignatureMethod': 'RSA-SHA256',
        'requestSigningCertId': signing,
        'samlEntityId': sp,
        'samlJitHandlerId': jit[0]['Id'][:15],
        'samlVersion': 'SAML2_0',
        'userProvisioning': 'true',
        'validationCert': cert,
    }
    xml = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<SamlSsoConfig xmlns="http://soap.sforce.com/2006/04/metadata">']
    xml += [f'    <{k}>{escape(v)}</{k}>' for k, v in sorted(body.items()) if v]
    xml.append('</SamlSsoConfig>')
    with tempfile.TemporaryDirectory() as tmp:
        d = Path(tmp)
        (d / 'samlssoconfigs').mkdir()
        (d / 'samlssoconfigs' / f'{a.name}.samlssoconfig').write_text('\n'.join(xml) + '\n', encoding='utf-8')
        (d / 'package.xml').write_text(
            '<?xml version="1.0" encoding="UTF-8"?>\n<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n'
            f'    <types><members>{a.name}</members><name>SamlSsoConfig</name></types>\n'
            f'    <version>{API}</version>\n</Package>\n', encoding='utf-8')
        args = ['project', 'deploy', 'start', '--metadata-dir', str(d), '-o', a.alias, '-w', '10']
        if a.dry_run:
            args.append('--dry-run')
        sf(args)
    print(f'{a.name} 배포 완료: IdP {issuer} → SP {sp}')
    print(f'SP 로그인(ACS) URL: {sp}?so={org["id"][:15]}')
    print('다음: 설정 > 내 도메인 > 인증 구성에서 이 SSO를 선택(로그인 양식 해제), IdP에 ACS·Entity ID 등록')


if __name__ == '__main__':
    main()
