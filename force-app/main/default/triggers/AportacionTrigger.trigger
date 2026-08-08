trigger AportacionTrigger on Aportacion__c (before insert) 
{
    AportacionTriggerHelper ath = null;
    System.debug('trigger aportacion');    
    if(trigger.isInsert)
    {
      ath = new AportacionTriggerHelper(Trigger.new, AportacionTriggerHelper.INS);
      System.debug('trigger aportacion insert');
    }

    System.debug('trigger aportacion exec');
    ath.execute();
}