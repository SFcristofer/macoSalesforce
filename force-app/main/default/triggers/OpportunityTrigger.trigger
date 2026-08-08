/**
 * Opportinuty
 */
trigger OpportunityTrigger on Opportunity (before update, after update) 
//trigger OpportunityTrigger on Opportunity (after update) 
{
   OpportunityTriggerHelper oppth;
   if(trigger.isUpdate && trigger.isBefore) {
       System.debug('OpportunityTrigger - update - before');
       oppth = new OpportunityTriggerHelper(OpportunityTriggerHelper.B4UPD, Trigger.oldMap, Trigger.newMap);
   }
   if(trigger.isUpdate && trigger.isAfter) {
       System.debug('OpportunityTrigger - update - after');
       oppth = new OpportunityTriggerHelper(OpportunityTriggerHelper.AUPD, Trigger.oldMap, Trigger.newMap);       
   }
   oppth.execute();
}