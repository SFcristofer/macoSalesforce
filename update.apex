List<FacturaDeCliente__c> facturas = [SELECT Id FROM FacturaDeCliente__c WHERE Name >= 'FC26070510' AND Name <= 'FC26070523' AND Estado__c = 'Enviada'];
for(FacturaDeCliente__c f : facturas){
    f.Estado__c = 'Contabilizada';
}
update facturas;
