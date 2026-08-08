trigger PlanificacionComercial on PlanificacionComercial__c (after update) {
    PlanificacionComercialTriggerHelper handle = new PlanificacionComercialTriggerHelper(Trigger.new, Trigger.oldMap);
    if(trigger.isAfter) {
        if(trigger.isUpdate) {
            handle.afterUpdate();
        }
    }
}