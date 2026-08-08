@isTest
private class TestGenDraftOrder {
	
	@isTest static void testDraftNameAndRecordType() {
		TestUtil tu = new TestUtil();
        tu.initProformaTest('PR10000');
        Test.startTest();
        GenDraftOrder gdo = new GenDraftOrder(new ApexPages.standardController(tu.getProforma()));
        gdo.generateDraft();
        test.stopTest();
        PedidoDeCompra__c pe = [SELECT Name,
                                    RecordType.DeveloperName,
                                    Proforma__c
                                    FROM PedidoDeCompra__c
                                    limit 1];
        system.assertEquals(pe.Name, 'SIMULACION [PR10000]');
        system.assertEquals(pe.RecordType.DeveloperName, 'Simulacion');
        system.assertEquals(pe.Proforma__c, tu.getProforma().Id);

	}

    @isTest static void testDraftUnique() {
		TestUtil tu = new TestUtil();
        tu.initProformaTest('PR10000');
        Test.startTest();
        Proforma__c pr = tu.getProforma();
        GenDraftOrder gdo = new GenDraftOrder(new ApexPages.standardController(pr));
        gdo.generateDraft();
        gdo.generateDraft();
        gdo.generateDraft();
        test.stopTest();
        list<PedidoDeCompra__c> lPe = [SELECT Id,
                                    Name
                                    FROM PedidoDeCompra__c
                                    WHERE Proforma__c = :pr.Id];
        system.assertEquals(1, lPe.size());

	}
	
}