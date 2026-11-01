# LWC 참조 (예시)

`.claude/rules/sf-dev.md` 6절의 규칙을 코드로 보여준다.

## 1. 기본: Apex 컨트롤러 호출

```javascript
import { LightningElement, api, wire } from 'lwc';
import getQueue from '@salesforce/apex/QMS_IqcWorkbenchController.getQueue';
import LBL_EMPTY from '@salesforce/label/c.QMS_IqcWorkbench_Empty';
import LBL_ERROR from '@salesforce/label/c.CMN_Common_LoadError';

export default class QmsIqcWorkbench extends LightningElement {
    @api plantId;
    rows = [];
    state = 'loading'; // loading | ready | empty | error
    labels = { empty: LBL_EMPTY, error: LBL_ERROR };

    @wire(getQueue, { plantId: '$plantId', pageSize: 50 })
    wiredQueue({ data, error }) {
        if (data) {
            this.rows = data.rows;
            this.state = data.rows.length ? 'ready' : 'empty';
        } else if (error) {
            this.state = 'error'; // 서버 메시지를 그대로 보여주지 않는다
        }
    }

    get isLoading() { return this.state === 'loading'; }
    get isEmpty() { return this.state === 'empty'; }
    get isError() { return this.state === 'error'; }
}
```

```html
<template>
    <template lwc:if={isLoading}><lightning-spinner alternative-text={labels.loading}></lightning-spinner></template>
    <template lwc:elseif={isError}><p class="slds-text-color_error">{labels.error}</p></template>
    <template lwc:elseif={isEmpty}><p>{labels.empty}</p></template>
    <template lwc:else>
        <template for:each={rows} for:item="row">
            <c-qms-iqc-lot-card key={row.id} lot={row}></c-qms-iqc-lot-card>
        </template>
    </template>
</template>
```

## 2. 예외: 단일 레코드 LDS

서버 업무 규칙이 없는 단일 레코드 조회·편집에만 쓴다. FLS는 LDS가 자동으로 적용한다.

```javascript
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import GAUGE_NO from '@salesforce/schema/QMS_Gauge__c.GaugeNo__c';
import NEXT_CAL from '@salesforce/schema/QMS_Gauge__c.NextCalibrationDate__c';

export default class QmsGaugeBadge extends LightningElement {
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields: [GAUGE_NO, NEXT_CAL] }) gauge;
    get gaugeNo() { return getFieldValue(this.gauge.data, GAUGE_NO); }
}
```

상태 전이(판정, 결재 상신 등)는 LDS `updateRecord`로 하지 않는다. 서비스 Apex를 호출한다.

## 3. 승인 목록 외부 라이브러리 로딩

```javascript
import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CHART_JS from '@salesforce/resourceUrl/cmnChartJs';

export default class QmsSpcChart extends LightningElement {
    chart;
    libLoaded = false;

    async renderedCallback() {
        if (this.libLoaded) return;
        this.libLoaded = true;
        try {
            await loadScript(this, CHART_JS);
            this.initChart();
        } catch (e) {
            this.state = 'error';
        }
    }

    initChart() {
        const canvas = this.refs.chartCanvas; // <canvas lwc:ref="chartCanvas">
        // eslint-disable-next-line no-undef
        this.chart = new window.Chart(canvas.getContext('2d'), this.buildConfig());
    }

    disconnectedCallback() {
        this.chart?.destroy();
    }
}
```

정적 리소스는 버전을 파일명 또는 리소스 설명에 고정하고, 갱신은 WI로 한다. LWS 환경에서 실제 동작을 Scratch Org로 확인한 뒤 승인 목록에 올린다.

## 4. Lightning Message Service

```javascript
import { publish, subscribe, MessageContext } from 'lightning/messageService';
import ASK from '@salesforce/messageChannel/QMS_AskQualityChannel__c';
// 구독은 connectedCallback, 해제는 disconnectedCallback에서. 채널 계약은 WI 정의(QMS-07-DSH-012) 그대로.
```

## 5. 토스트와 오류 표시

```javascript
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LBL_SAVED from '@salesforce/label/c.CMN_Common_Saved';

showSaved() {
    this.dispatchEvent(new ShowToastEvent({ title: LBL_SAVED, variant: 'success' }));
}

showError(error) {
    // 서버 AuraHandledException 메시지는 이미 라벨 문구. 그 밖의 오류는 공통 라벨로.
    const msg = error?.body?.message ?? this.labels.error;
    this.dispatchEvent(new ShowToastEvent({ title: this.labels.errorTitle, message: msg, variant: 'error' }));
}
```

## 6. Jest 목

```javascript
import { createElement } from 'lwc';
import QmsIqcWorkbench from 'c/qmsIqcWorkbench';
import getQueue from '@salesforce/apex/QMS_IqcWorkbenchController.getQueue';
import QUEUE_OK from '../../../../../../data/demo/mocks/apex/qmsIqcWorkbench.ok.json';

jest.mock('@salesforce/apex/QMS_IqcWorkbenchController.getQueue',
    () => ({ default: jest.fn() }), { virtual: true });

it('AC-7 대기열 50건 렌더링', async () => {
    getQueue.mockResolvedValue(QUEUE_OK);
    const el = createElement('c-qms-iqc-workbench', { is: QmsIqcWorkbench });
    document.body.appendChild(el);
    // @wire Apex는 sfdx-lwc-jest의 테스트 wire 어댑터(createApexTestWireAdapter)로 emit한다.
});
```

데모 목 JSON의 상대 경로는 컴포넌트 위치에 따라 달라진다. jest.config.js에 `moduleNameMapper`로 `^@demo/(.*)$` → `<rootDir>/data/demo/$1`를 추가해 `@demo/mocks/...`로 가져오는 것을 권장한다(ARC-001 구성 시 반영).
