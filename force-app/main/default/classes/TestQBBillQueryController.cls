@isTest
public class TestQBBillQueryController {

    public static testMethod void testBillPagado() {
        List<JSON_LOG__c> jsonLogList;
        List<FacturaDeProveedor__c> facturas;
        FacturaDeProveedor__c facturaProveedor;
        QBBillQueryController controller;

        System.debug('TEST BILL PAGADO');

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Contabilizada');

        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           Proveedor__r.IdQbo__c
                      FROM FacturaDeProveedor__c
                     WHERE Estado__c = 'Contabilizada'];
                      
        for(FacturaDeProveedor__c fp : facturas) {
            System.debug('F-ORIG idFact[' + fp.Id + '] idQb[' + fp.IdQbo__c + '] estado[' + fp.Estado__c + ']');
        } 

        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('billPagado'));          

        Test.startTest();
        controller = new QBBillQueryController(facturas);
        controller.sendToQB();
        Test.stopTest();        
        
        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           Proveedor__r.IdQbo__c
                      FROM FacturaDeProveedor__c
                     WHERE Estado__c = 'Pagada'];
                      
        for(FacturaDeProveedor__c fp : facturas) {
            System.debug('F-UPD idFact[' + fp.Id + '] idQb[' + fp.IdQbo__c + '] estado[' + fp.Estado__c + ']');
        } 
        
        jsonLogList = [SELECT Id, Name, Endpoint__c, json__c, Response_JSON__c FROM JSON_LOG__c];
        for(JSON_LOG__c l : jsonLogList) {
            System.debug('[' + l.Name + '] [' + l.Endpoint__c + '] [' + l.json__c + '] [' + l.Response_JSON__c + ']');
        }
    }
    
    
    public static testMethod void testBillCancelado() {
        List<JSON_LOG__c> jsonLogList;
        List<FacturaDeProveedor__c> facturas;
        FacturaDeProveedor__c facturaProveedor;
        QBBillQueryController controller;
        
        System.debug('TEST BILL CANCELADO');

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Contabilizada');

        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           Proveedor__r.IdQbo__c
                      FROM FacturaDeProveedor__c
                     WHERE Estado__c = 'Contabilizada'];
                      
        for(FacturaDeProveedor__c fp : facturas) {
            System.debug('F-ORIG idFact[' + fp.Id + '] idQb[' + fp.IdQbo__c + '] estado[' + fp.Estado__c + ']');
        } 

        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('billCancelado'));

        Test.startTest();
        controller = new QBBillQueryController(facturas);
        controller.sendToQB();
        Test.stopTest();        
        
        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           Proveedor__r.IdQbo__c
                      FROM FacturaDeProveedor__c
                     WHERE Estado__c = 'Cancelada'];
                      
        for(FacturaDeProveedor__c fp : facturas) {
            System.debug('F-UPD idFact[' + fp.Id + '] idQb[' + fp.IdQbo__c + '] estado[' + fp.Estado__c + ']');
        } 
        
        jsonLogList = [SELECT Id, Name, Endpoint__c, json__c, Response_JSON__c FROM JSON_LOG__c];
        for(JSON_LOG__c l : jsonLogList) {
            System.debug('[' + l.Name + '] [' + l.Endpoint__c + '] [' + l.json__c + '] [' + l.Response_JSON__c + ']');
        }
    }
    
}


/*
        FacturaDeProveedor__c facturaProveedor;
        QBBillSyncController qbSyncCtrlr;

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Recibida');
        
        facturaProveedor = [SELECT Id,
                                   Name,
                                   Estado__c,
                                   IdQbo__c,
                                   Total__c,
                                   Proveedor__r.IdQbo__c,
                                   (SELECT Id,
                                           Name,
                                           Descripcion__c,
                                           Total__c
                                      FROM ItemsDeFacturaDeProveedor__r)
                              FROM FacturaDeProveedor__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBBill'));
        Test.startTest();
        qbSyncCtrlr = new QBBillSyncController(facturaProveedor);
        qbSyncCtrlr.sendToQB();
        Test.stopTest();
*/