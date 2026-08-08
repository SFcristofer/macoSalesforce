/**
*   When a Pricebook's Margen is updated, all PricebookEntries must be corrected accordingly.
*   Version 1.0
*   @author lcosta@infolastic.com
*/
trigger Pricebook on Pricebook2 (before update) {
    PricebookTriggerHelper pth = new PricebookTriggerHelper(trigger.newMap, trigger.oldMap);
    pth.execute();
}