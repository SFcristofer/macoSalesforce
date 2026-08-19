List<FacturaDeCliente__c> invoices = [SELECT Id, Estado__c FROM FacturaDeCliente__c WHERE Name >= 'FC26070510' AND Name <= 'FC26070523'];
for(FacturaDeCliente__c inv : invoices) {
    inv.Estado__c = 'Enviada';
}
update invoices;
