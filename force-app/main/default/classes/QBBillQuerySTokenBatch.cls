/*
 * Batch execution
 * Id batchInstanceId = Database.executeBatch(new QBBillQuerySTokenBatch());
 */
global class QBBillQuerySTokenBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

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
                                          WHERE FechaVencimientoActualizada__c = true
                                            AND Estado__c = 'Contabilizada'
                                            AND QB_SyncToken__c = null]);
    }

    global void execute(Database.BatchableContext BC, List<FacturaDeProveedor__c> facturasProveedor) {
        QBBillQuerySTokenController controller;
        System.debug('Executing QBBillQuerySTokenBatch Batch registers[' + facturasProveedor.size() + ']');
        
        controller = new QBBillQuerySTokenController(facturasProveedor);
        controller.sendToQB();
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finish QBBillQuerySTokenBatch Batch');
    }

}