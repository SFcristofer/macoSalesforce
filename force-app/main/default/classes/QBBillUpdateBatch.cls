/*
 * Batch execution
 * Id batchInstanceId = Database.executeBatch(new QBBillUpdateBatch());
 */
global class QBBillUpdateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //get facturas
        return Database.getQueryLocator([SELECT Id,
                                                Name,
                                                Estado__c,
                                                IdQbo__c,
                                                Total__c,
                                                QB_SyncToken__c,
                                                FechaDeFactura__c,
                                                FechaVencimiento__c,
                                                FechaVencimientoActualizada__c,
                                                Proveedor__r.IdQbo__c,
                                                (SELECT Id,
                                                        Name,
                                                        Descripcion__c,
                                                        Total__c
                                                   FROM ItemsDeFacturaDeProveedor__r)
                                           FROM FacturaDeProveedor__c
                                          WHERE Estado__c = 'Contabilizada'
                                            AND QB_SyncToken__c != null
                                            AND FechaVencimientoActualizada__c = true]);
    }

    global void execute(Database.BatchableContext BC, List<FacturaDeProveedor__c> facturasProveedor) {
        QBBillUpdateController qbBillCtrlr;
        QBBillSyncResult result;
        List<JSON_LOG__c> jsonLogs;
        List<FacturaDeProveedor__c> facturas;

        System.debug('Executing QBBatchFacturasProveedor Batch registers[' + facturasProveedor.size() + ']');

        jsonLogs = new List<JSON_LOG__c>();
        facturas = new List<FacturaDeProveedor__c>();

        for(FacturaDeProveedor__c facturaProveedor : facturasProveedor) {
            qbBillCtrlr = new QBBillUpdateController(facturaProveedor, QBBillUpdateController.SF_BATCH_MODE);
            result = qbBillCtrlr.sendToQB();
            jsonLogs.add(result.jsonLog);
            facturas.add(result.factura);
        }

        insert jsonLogs;
        update facturas;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finish QBBatchFacturasProveedor Batch');
    }

}