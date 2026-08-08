/*
 * Batch execution
 * Id batchInstanceId = Database.executeBatch(new QBInvoiceBatch());
 */
global class QBInvoiceBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //get facturas
        System.debug('Init Invoice Batch');
        return Database.getQueryLocator([SELECT Id,
                                                Name,
                                                Estado__c,
                                                IdQbo__c,
                                                Total__c,
                                                Cliente__r.Parent.IdQbo__c,
                                                Cliente__r.Parent.Name,
                                                FechaDeFactura__c,
                                                FechaVencimiento__c,
                                                (SELECT Id,
                                                        Name,
                                                        PrecioDeVenta__c,
                                                        Descripcion__c,
                                                        Total__c,
                                                        Cantidad__c
                                                   FROM ItemsDeFacturaDeCliente__r)
                                           FROM FacturaDeCliente__c
                                          WHERE Estado__c = 'Enviada']);

    }

    global void execute(Database.BatchableContext BC, List<FacturaDeCliente__c> facturasCliente) {
        QBInvoiceSyncController qbInvoiceCtrlr;
        QBInvoiceSyncResult result;
        List<JSON_LOG__c> jsonLogs;
        List<FacturaDeCliente__c> facturas;
        System.debug('Executing QBBatchFacturasCliente Batch registers[' + facturasCliente.size() + ']');
        
        jsonLogs = new List<JSON_LOG__c>();
        facturas = new List<FacturaDeCliente__c>();

        for(FacturaDeCliente__c facturaCliente : facturasCliente) {
            qbInvoiceCtrlr = new QBInvoiceSyncController(facturaCliente, QBInvoiceSyncController.SF_BATCH_MODE);
            result = qbInvoiceCtrlr.sendToQB();
            jsonLogs.add(result.jsonLog);
            if(result.factura != null) {
                facturas.add(result.factura);
            }
        }
        
        insert jsonLogs;
        update facturas;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finish QBBatchFacturasCliente Batch');
    }
    
}