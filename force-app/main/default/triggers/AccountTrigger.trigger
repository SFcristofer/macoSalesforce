trigger AccountTrigger on Account (before update) {
    Map<String, Boolean> actionsConfig;
    String triggerName;
    String[] triggerNameTokens;
    Boolean isTriggerEnabled;

    triggerName = String.valueOf(this);
    triggerNameTokens = triggerName.split(':');
    triggerName = triggerNameTokens[0];
    System.debug('Executing [' + triggerName + ']');

    actionsConfig = QBDAO.getTriggerConfiguration(triggerName);
    
    isTriggerEnabled = actionsConfig.get('main');
    
    if(isTriggerEnabled != null && isTriggerEnabled) {
        System.debug('Trigger [' + triggerName + '] enabled');
        if(isTriggerEnabled) {
            if(trigger.isUpdate && trigger.isBefore) {
                AccountTriggerHelper.executeUpdateBefore(Trigger.new, trigger.oldMap, AccountTriggerHelper.UPD, AccountTriggerHelper.BEF);                
            }
        }
    } else {
        System.debug('Trigger [' + triggerName + '] not enabled');
    }
}