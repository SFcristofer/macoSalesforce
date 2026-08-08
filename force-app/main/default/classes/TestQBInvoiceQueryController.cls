@isTest
public class TestQBInvoiceQueryController {

    public static testMethod void testInvoiceCobrado() {
        List<JSON_LOG__c> jsonLogList;
        List<FacturaDeCliente__c> facturas;
        //FacturaDeCliente__c facturaCliente;
        QBInvoiceQueryController controller;

        System.debug('TEST INVOICE COBRADO');

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaCliente('Contabilizada');

        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           Cliente__r.Parent.IdQbo__c
                      FROM FacturaDeCliente__c
                     WHERE Estado__c = 'Contabilizada'];
                      
        for(FacturaDeCliente__c fc : facturas) {
            System.debug('F-ORIG idFact[' + fc.Id + '] idQb[' + fc.IdQbo__c + '] estado[' + fc.Estado__c + ']');
        } 

        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('invoiceCobrada'));          

        Test.startTest();
        controller = new QBInvoiceQueryController(facturas);
        controller.sendToQB();
        Test.stopTest();        
        
        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           Cliente__r.Parent.IdQbo__c
                      FROM FacturaDeCliente__c
                     WHERE Estado__c = 'Cobrada'];
                      
        for(FacturaDeCliente__c fc : facturas) {
            System.debug('F-UPD idFact[' + fc.Id + '] idQb[' + fc.IdQbo__c + '] estado[' + fc.Estado__c + ']');
        } 
        
        jsonLogList = [SELECT Id, Name, Endpoint__c, json__c, Response_JSON__c FROM JSON_LOG__c];
        for(JSON_LOG__c l : jsonLogList) {
            System.debug('[' + l.Name + '] [' + l.Endpoint__c + '] [' + l.json__c + '] [' + l.Response_JSON__c + ']');
        }
    }
    
    
    public static testMethod void testInvoiceCancelado() {
        List<JSON_LOG__c> jsonLogList;
        List<FacturaDeCliente__c> facturas;
        //FacturaDeCliente__c facturaCliente;
        QBInvoiceQueryController controller;
        
        System.debug('TEST INVOICE CANCELADO');

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaCliente('Contabilizada');

        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           Cliente__r.Parent.IdQbo__c
                      FROM FacturaDeCliente__c
                     WHERE Estado__c = 'Contabilizada'];
                      
        for(FacturaDeCliente__c fc : facturas) {
            System.debug('F-ORIG idFact[' + fc.Id + '] idQb[' + fc.IdQbo__c + '] estado[' + fc.Estado__c + ']');
        } 

        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('invoiceCancelada'));

        Test.startTest();
        controller = new QBInvoiceQueryController(facturas);
        controller.sendToQB();
        Test.stopTest();        
        
        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           Cliente__r.Parent.IdQbo__c
                      FROM FacturaDeCliente__c
                     WHERE Estado__c = 'Cancelada'];
                      
        for(FacturaDeCliente__c fc : facturas) {
            System.debug('F-UPD idFact[' + fc.Id + '] idQb[' + fc.IdQbo__c + '] estado[' + fc.Estado__c + ']');
        } 
        
        jsonLogList = [SELECT Id, Name, Endpoint__c, json__c, Response_JSON__c FROM JSON_LOG__c];
        for(JSON_LOG__c l : jsonLogList) {
            System.debug('[' + l.Name + '] [' + l.Endpoint__c + '] [' + l.json__c + '] [' + l.Response_JSON__c + ']');
        }
    }
    
}


/*

        FacturaDeCliente__c facturaCliente;
        QBInvoiceSyncController qbSyncCtrlr;

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaCliente('Enviada');
        
        facturaCliente = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           FechaDeFactura__c,
                           FechaVencimiento__c,
                           Cliente__r.Parent.IdQbo__c,
                           (SELECT Id,
                                   Name,
                                   PrecioDeVenta__c,
                                   Descripcion__c,
                                   Total__c,
                                   Cantidad__c
                              FROM ItemsDeFacturaDeCliente__r)
                      FROM FacturaDeCliente__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBInvoice'));
        Test.startTest();
        qbSyncCtrlr = new QBInvoiceSyncController(facturaCliente);
        qbSyncCtrlr.sendToQB();
        Test.stopTest();


*/