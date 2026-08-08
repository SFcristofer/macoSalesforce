@isTest
public class TestQBSyncAccountController {

    public static testMethod void testQBSyncCustomerController() {
        List<JSON_LOG__c> jsonLogList;     
        Account cliente;
        TestQBUtil tu = new TestQBUtil();
        tu.createCliente();
        

        cliente = [SELECT Id, Name, Codigo_rapido__c FROM Account WHERE Codigo_rapido__c = '22233'];

        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBCustomer'));          
        ApexPages.StandardController stdController = new ApexPages.StandardController(cliente);
        Test.startTest();
        QBSyncAccountController controller = new QBSyncAccountController(stdController);
        controller.syncQB();
        Test.stopTest();        
        
        cliente = [SELECT Id, Name, IdQbo__c, Codigo_rapido__c FROM Account WHERE Codigo_rapido__c = '22233'];
        
        System.debug('idQB [' + cliente.IdQbo__c + ']');
        
        jsonLogList = [SELECT Id, Name, Endpoint__c, json__c, Response_JSON__c FROM JSON_LOG__c];
        for(JSON_LOG__c l : jsonLogList) {
            System.debug('[' + l.Name + '] [' + l.Endpoint__c + '] [' + l.json__c + '] [' + l.Response_JSON__c + ']');
        }
    }
}