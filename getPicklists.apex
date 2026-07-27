List<String> familyVals = new List<String>();
for(Schema.PicklistEntry pe : Product2.Family.getDescribe().getPicklistValues()) {
    familyVals.add(pe.getValue());
}
System.debug('--- FAMILY VALUES ---');
System.debug(String.join(familyVals, ', '));

List<String> subfamilyVals = new List<String>();
for(Schema.PicklistEntry pe : Product2.Subfamilia__c.getDescribe().getPicklistValues()) {
    subfamilyVals.add(pe.getValue());
}
System.debug('--- SUBFAMILIA VALUES ---');
System.debug(String.join(subfamilyVals, ', '));

List<String> claseVals = new List<String>();
for(Schema.PicklistEntry pe : Product2.Clase__c.getDescribe().getPicklistValues()) {
    claseVals.add(pe.getValue());
}
System.debug('--- CLASE VALUES ---');
System.debug(String.join(claseVals, ', '));
