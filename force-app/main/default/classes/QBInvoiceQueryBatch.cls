/*
 * Batch execution
 * Id batchInstanceId = Database.executeBatch(new QBInvoiceQueryBatch());
 */
global class QBInvoiceQueryBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //get facturas
        return Database.getQueryLocator([SELECT Id,
                                                Name,
                                                Estado__c,
                                                IdQbo__c,
                                                Total__c,
                                                FechaDeFactura__c,
                                                FechaVencimiento__c,
                                                Cliente__r.Parent.IdQbo__c
                                           FROM FacturaDeCliente__c
                                          WHERE Estado__c = 'Contabilizada']);
    }

    global void execute(Database.BatchableContext BC, List<FacturaDeCliente__c> facturasCliente) {
        QBInvoiceQueryController controller;
        System.debug('Executing QBInvoiceQueryBatch Batch registers[' + facturasCliente.size() + ']');
        
        controller = new QBInvoiceQueryController(facturasCliente);
        controller.sendToQB();
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finish QBInvoiceQueryBatch Batch');
    }
    
}