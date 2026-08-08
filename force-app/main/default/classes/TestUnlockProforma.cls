@isTest
private class TestUnlockProforma {
	
	@isTest static void testUnlock() {
		TestUtil tu = new TestUtil();
        tu.initProformaTest('PR10000'); //Should be init under threshold
        GenDraftOrder gdo = new GenDraftOrder(new ApexPages.standardController(tu.getProforma()));
        test.startTest();
        gdo.generateDraft();
        PedidoDeCompra__c pe = [SELECT Name,
                                    RecordType.DeveloperName,
                                    Proforma__c,
                                    (SELECT Id,
                                        CostoExtraUnitario__c,
                                        CostoOrigen__c,
                                        NumeroDeCajas__c,
                                        PrecioDeVenta__c,
                                        ProformaLineItem__c,
                                        ProformaLineItem__r.CostoFabrica__c,
                                        ProformaLineItem__r.PrecioUnitario__c,
                                        ProformaLineItem__r.NumeroDeCajas__c
                                        FROM PedidoLineItems__r)
                                    FROM PedidoDeCompra__c
                                    limit 1];
        for( PedidoLineItem__c pli : pe.PedidoLineItems__r){
            pli.CostoOrigen__c = 10;
            pli.PrecioDeVenta__c = 4000;
            pli.NumeroDeCajas__c = 2;
            system.debug('look here: ' + pli.ProformaLineItem__r.CostoFabrica__c + ' ' + pli.ProformaLineItem__r.PrecioUnitario__c);
        }
        update pe.PedidoLineItems__r;

        ApplyChangesCloseSimulation accs = new ApplyChangesCloseSimulation(new ApexPages.standardController(pe));
        accs.execute();


        UnlockProforma up = new UnlockProforma(new ApexPages.standardController(tu.createProforma(true,'name')));
        up.unlock();
        test.stopTest();
        //Assertions go here
        
	}
	
}