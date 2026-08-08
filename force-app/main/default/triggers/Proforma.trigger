trigger Proforma on Proforma__c (before insert, before update, after update) {
    ProformaTriggerHelper pth;
    if(trigger.isUpdate){
        pth = new ProformaTriggerHelper(Trigger.new, Trigger.oldMap, ProformaTriggerHelper.UPD, trigger.isBefore);
    }else if(trigger.isInsert){
        pth = new ProformaTriggerHelper(Trigger.new, Trigger.oldMap, ProformaTriggerHelper.INS, trigger.isBefore);
    }
    pth.execute();
}