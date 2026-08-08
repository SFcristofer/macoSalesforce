/*
 * Batch execution
 * Id batchInstanceId = Database.executeBatch(new QBBillBatch());
 */
global class QBBillBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //get facturas
        return Database.getQueryLocator([SELECT Id,
                                                Name,
                                                Estado__c,
                                                IdQbo__c,
                                                Total__c,
                                                FechaDeFactura__c,
                                                FechaVencimiento__c,
                                                FechaVencimientoActualizada__c,
                                                Proveedor__r.Name,
                                                Proveedor__r.IdQbo__c,
                                                (SELECT Id,
                                                        Name,
                                                        Descripcion__c,
                                                        Total__c
                                                   FROM ItemsDeFacturaDeProveedor__r)
                                           FROM FacturaDeProveedor__c
                                          WHERE Estado__c = 'Creada']);

    }

    global void execute(Database.BatchableContext BC, List<FacturaDeProveedor__c> facturasProveedor) {
        QBBillSyncController qbBillCtrlr;
        QBBillSyncResult result;
        List<JSON_LOG__c> jsonLogs;
        List<FacturaDeProveedor__c> facturas;

        System.debug('Executing QBBatchFacturasProveedor Batch registers[' + facturasProveedor.size() + ']');

        jsonLogs = new List<JSON_LOG__c>();
        facturas = new List<FacturaDeProveedor__c>();

        for(FacturaDeProveedor__c facturaProveedor : facturasProveedor) {
            qbBillCtrlr = new QBBillSyncController(facturaProveedor, QBBillSyncController.SF_BATCH_MODE);
            result = qbBillCtrlr.sendToQB();
            jsonLogs.add(result.jsonLog);
            if(result.factura != null) {
                facturas.add(result.factura);
            }
        }

        insert jsonLogs;
        update facturas;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finish QBBatchFacturasProveedor Batch');
    }

}