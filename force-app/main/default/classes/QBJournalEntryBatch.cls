/*
 * Batch execution
 * Id batchInstanceId = Database.executeBatch(new QBBillBatch());
 */
global class QBJournalEntryBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //get facturas
        return Database.getQueryLocator([SELECT Id,
                                                Name,
                                                Estado__c,
                                                IdQbo__c,
                                                IdQboJournalEntry__c,
                                                JournalEntryCreadoEnQbo__c,
                                                QboJournalEntryNo__c,
                                                QboJournalEntryDescription__c,
                                                Total__c,
                                                QB_SyncToken__c,
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
                                          WHERE Estado__c = 'Contabilizada'
                                            AND JournalEntryCreadoEnQbo__c = false]);

    }

    global void execute(Database.BatchableContext BC, List<FacturaDeProveedor__c> facturasProveedor) {
        QBJournalEntrySyncController qbJournalCtrlr;
        QBJournalSyncResult result;
        List<JSON_LOG__c> jsonLogs;
        List<FacturaDeProveedor__c> facturas;

        System.debug('Executing QB Journal Entry Batch registers[' + facturasProveedor.size() + ']');

        jsonLogs = new List<JSON_LOG__c>();
        facturas = new List<FacturaDeProveedor__c>();

        for(FacturaDeProveedor__c facturaProveedor : facturasProveedor) {
            qbJournalCtrlr = new QBJournalEntrySyncController(facturaProveedor, QBJournalEntrySyncController.SF_BATCH_MODE);
            result = qbJournalCtrlr.sendToQB();
            jsonLogs.add(result.jsonLog);
            if(result.factura != null) {
                facturas.add(result.factura);
            }
        }

        insert jsonLogs;
        update facturas;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finish QB Journal Entry Batch Batch');
    }

}