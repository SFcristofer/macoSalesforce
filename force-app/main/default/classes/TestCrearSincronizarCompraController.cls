@isTest
public class TestCrearSincronizarCompraController {

    public static testMethod void testMyController() { 
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        
        Opportunity opp = tu.getOpportunity();
        Product2 prod = tu.getFirstPDF();
        OpportunityLineItem oli = tu.getOLI4Prod(prod);

        opp = [SELECT Name, (SELECT Product2Id, CostoProducto__c, Quantity FROM OpportunityLineItems) FROM Opportunity WHERE Id =: opp.id];        
        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
        CreateSyncEstudioOportunidad controller = new CreateSyncEstudioOportunidad(stdController);
        controller.execute();
        
        List<EstudioOportunidad__c> estudios = [SELECT Name, 
                                                (SELECT Id, 
                                                Product2Id,
                                                Quantity
                                                FROM ProductosDeOportunidad__r) 
                                            FROM EstudioOportunidad__c 
                                            WHERE Oportunidad__c = :opp.Id];
            
        System.assertEquals(1, estudios.size());
        System.assertEquals(2, estudios.get(0).ProductosDeOportunidad__r.size());
        System.assertEquals(prod.id, estudios.get(0).ProductosDeOportunidad__r.get(0).Product2Id);
            
    }
}