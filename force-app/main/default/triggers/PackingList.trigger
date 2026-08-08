/**
*   Processes approved Packing Lists
*/
trigger PackingList on PackingList__c (before update) {
    PackingListTriggerHelper plth = new PackingListTriggerHelper(trigger.new, trigger.oldMap);
    plth.execute();
}