/**
 * @description 공장 그룹 생성·구성원 맞춤(CMN-00-SEC-002 BR-2). 설정 DML이라 업무 트랜잭션과 분리해 비동기로 실행한다.
 * @group CMN-00-SEC-002
 */
public with sharing class CMN_PlantGroupJob implements Queueable {
  private final Set<Id> plantIds;
  private final Set<Id> userIds;

  /**
   * @description 대상.
   * @param plantIds 그룹을 보장할 공장
   * @param userIds 구성원을 맞출 사용자
   */
  public CMN_PlantGroupJob(Set<Id> plantIds, Set<Id> userIds) {
    this.plantIds = plantIds ?? new Set<Id>();
    this.userIds = userIds ?? new Set<Id>();
  }

  /**
   * @description 실행.
   * @param context Queueable 문맥
   */
  public void execute(QueueableContext context) {
    CMN_PlantGroupService.ensureGroups(plantIds);
    CMN_PlantGroupService.syncMembers(userIds);
  }
}
