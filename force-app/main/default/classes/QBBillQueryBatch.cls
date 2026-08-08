/*
 * Batch execution
 * Id batchInstanceId = Database.executeBatch(new QBBillQueryBatch());
 */
global class QBBillQueryBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //get facturas
        return Database.getQueryLocator([SELECT Id,
                                                Name,
                                                Estado__c,
                                                IdQbo__c,
                                                Total__c,
                                                Proveedor__r.IdQbo__c
                                           FROM FacturaDeProveedor__c
                                          WHERE Estado__c = 'Contabilizada']);
    }

    global void execute(Database.BatchableContext BC, List<FacturaDeProveedor__c> facturasProveedor) {
        QBBillQueryController controller;
        System.debug('Executing QBBillQueryBatch Batch registers[' + facturasProveedor.size() + ']');
        
        controller = new QBBillQueryController(facturasProveedor);
        controller.sendToQB();
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finish QBBillQueryBatch Batch');
    }
    
}