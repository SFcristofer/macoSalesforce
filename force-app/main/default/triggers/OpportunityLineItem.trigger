/**
 * Modified to add the fields needed to get the last price for any Client/Products (on before insert)
 * Removed the after insert action (review)
 */
trigger OpportunityLineItem on OpportunityLineItem (before delete, before insert, before update) {
    String oper;
    list<OpportunityLineItem> olis;
    if(trigger.isBefore && trigger.isInsert) {
        olis = trigger.new;
        oper = OLITriggerHelper.B4INS;
    }else if(trigger.isUpdate){
        olis = trigger.new;
        oper = OLITriggerHelper.UPD;
    }else if(trigger.isDelete){
        olis = trigger.old;
        oper = OLITriggerHelper.DEL;
    }
    OLITriggerHelper oth = new OLITriggerHelper(olis, trigger.oldMap, oper);
    oth.execute();
}