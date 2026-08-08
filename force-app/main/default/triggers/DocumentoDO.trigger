trigger DocumentoDO on Documento__c (before insert) {
    DocumentoDOTriggerHelper ddth = new DocumentoDOTriggerHelper(trigger.new);
    ddth.execute();
}