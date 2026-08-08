trigger Pedido on PedidoDeCompra__c (before insert, before delete, after update, after insert) {
    Map<String, Boolean> actionsConfig;
    String triggerName;
    String[] triggerNameTokens;
    Boolean isTriggerEnabled;
    PedidoTriggerHelper pth = null;
    
    triggerName = String.valueOf(this);
    triggerNameTokens = triggerName.split(':');
    triggerName = triggerNameTokens[0];
    System.debug('Executing [' + triggerName + ']');

    actionsConfig = QBDAO.getTriggerConfiguration(triggerName);
    
    isTriggerEnabled = actionsConfig.get('main');

    if(isTriggerEnabled != null && isTriggerEnabled) {
        System.debug('trigger pedido');    
        if(trigger.isInsert && trigger.isBefore) {
            pth = new PedidoTriggerHelper(Trigger.new, PedidoTriggerHelper.INS, PedidoTriggerHelper.BEF, actionsConfig);
            System.debug('trigger pedido insert before');
        }
        if(trigger.isInsert && trigger.isAfter) {
            pth = new PedidoTriggerHelper(Trigger.new, PedidoTriggerHelper.INS, PedidoTriggerHelper.AFT, actionsConfig);
            System.debug('trigger pedido insert after');
        }
        if(trigger.isDelete) {
            pth = new PedidoTriggerHelper(trigger.old, PedidoTriggerHelper.DEL, PedidoTriggerHelper.BEF, actionsConfig);
        }
        if(trigger.isUpdate) {
            pth = new PedidoTriggerHelper(Trigger.new, PedidoTriggerHelper.UPD, trigger.oldMap, actionsConfig); 
            System.debug('trigger pedido update');
        }

        System.debug('trigger pedido exec');
        pth.execute();
    }
}