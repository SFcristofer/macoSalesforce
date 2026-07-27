List<String> vals = new List<String>();
for(Schema.PicklistEntry pe : Product2.PlazoDeFabricacion__c.getDescribe().getPicklistValues()) {
    vals.add(pe.getValue());
}
System.debug('--- PLAZO DE FABRICACION VALUES ---');
System.debug(String.join(vals, ', '));
