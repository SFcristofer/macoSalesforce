@isTest
private class TestApplyChangesCloseSimulation {
	
	@isTest static void testApplyChanges() {
		TestUtil tu = new TestUtil();
        tu.initProformaTest('PR10000');
        GenDraftOrder gdo = new GenDraftOrder(new ApexPages.standardController(tu.getProforma()));
        test.startTest();
        gdo.generateDraft();
        PedidoDeCompra__c pe1 = tu.createPedidoDeCompra('volume');
        tu.createPedidoLineItems(pe1);
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
                                    FROM PedidoDeCompra__c where id =: pe1.id 
                                    limit 1];
        
        PedidoLineItem__c pli = pe.PedidoLineItems__r[0];
        //system.assertEquals(pli.CostoExtraUnitario__c, 499.521479);
        //system.assertEquals(pli.ProformaLineItem__r.CostoFabrica__c, 24);
       // system.assertEquals(pli.ProformaLineItem__r.PrecioUnitario__c, 38.54);
        //system.assertEquals(pli.ProformaLineItem__r.NumeroDeCajas__c, 1);
        pli.CostoOrigen__c = 20;
        pli.PrecioDeVenta__c = 40;
        pli.NumeroDeCajas__c = 2;
        update pli;

        ApplyChangesCloseSimulation accs = new ApplyChangesCloseSimulation(new ApexPages.standardController(pe));
        accs.execute();
        
        //ProformaLineItem__c pri = [SELECT CostoFabrica__c,
         //                           PrecioUnitario__c,
        //                            NumeroDeCajas__c
         //                           FROM ProformaLineItem__c
          //                          WHERE id = :pli.ProformaLineItem__c];
        
        //system.assertEquals(pri.CostoFabrica__c, 20);
        //system.assertEquals(pri.PrecioUnitario__c, 40);
        //system.assertEquals(pri.NumeroDeCajas__c, 2);

        list<PedidoDeCompra__c> pedidos = [SELECT Id
                                                FROM PedidoDeCompra__c];
        //system.assertEquals(pedidos.size(), 1);

        Proforma__c pr = tu.getProforma();
        pr.ConfirmacionCliente__c = true;
        update pr;
        test.stopTest();

	}
	
}