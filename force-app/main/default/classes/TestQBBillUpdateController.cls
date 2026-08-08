@isTest
public class TestQBBillUpdateController {

    public static testMethod void testBillUpdateQB() {
        List<JSON_LOG__c> jsonLogList;
        List<FacturaDeProveedor__c> facturas;
        FacturaDeProveedor__c facturaProveedor;
        QBBillUpdateController controller;

        System.debug('TEST BILL PAGADO');

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Contabilizada');

        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           FechaDeFactura__c,
                           FechaVencimiento__c,
                           FechaVencimientoActualizada__c,
                           QB_SyncToken__c,
                           Proveedor__r.IdQbo__c
                      FROM FacturaDeProveedor__c
                     WHERE Estado__c = 'Contabilizada'];
                      
        for(FacturaDeProveedor__c fp : facturas) {
            System.debug('F-ORIG idFact[' + fp.Id + '] idQb[' + fp.IdQbo__c + '] estado[' + fp.Estado__c + ']');
        }

        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('bill'));

        Test.startTest();
        controller = new QBBillUpdateController(facturas.get(0), QBBillUpdateController.SINGLE_MODE);
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

}