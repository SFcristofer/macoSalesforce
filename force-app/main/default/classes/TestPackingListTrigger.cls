@isTest
private class TestPackingListTrigger {
    @isTest
    private static void testPackingListOK() {
        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        
        test.startTest();        
            proForma = tu.getProforma();
            proForma.ConfirmacionCliente__c = true;
            update proForma;

            PedidoDeCompra__c order = [SELECT Id,
                                            (SELECT Id,
                                                    NumeroDeCajas__c,
                                                    UnidadesPorMasterbox__c,
                                                    Quantity__c,
                                                    Unidades__c
                                                    FROM PedidoLineItems__r)
                                            FROM PedidoDeCompra__c
                                            WHERE Proforma__c = :proForma.Id];
            PackingList__c pl = new PackingList__c(Pedido__c = order.Id);
            insert pl;
            for(PedidoLineItem__c pli : order.PedidoLineItems__r) {
                pli.PackingList__c = pl.Id;
                pli.Quantity__c = pli.Unidades__c;
            }
            update order.PedidoLineItems__r;
            pl.Estado__c = 'Aprobado';
            update pl;
        test.stopTest();
            PedidoDeCompra__c updOrder = [SELECT Id,
                                            (SELECT Id,
                                                    NumeroDeCajas__c
                                                    FROM PedidoLineItems__r)
                                            FROM PedidoDeCompra__c
                                            WHERE Proforma__c = :proForma.Id];
            Integer i = 0;
            for(PedidoLineItem__c pli : updOrder.PedidoLineItems__r) {
                system.assertEquals(pli.NumeroDeCajas__c, order.PedidoLineItems__r[i].NumeroDeCajas__c);
                i++;
            }
    }

    @isTest
    private static void testPackingListChanges() {
        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        
        test.startTest();        
            proForma = tu.getProforma();
            proForma.ConfirmacionCliente__c = true;
            update proForma;


            PedidoDeCompra__c order = [SELECT Id,
                                            (SELECT Id,
                                                    NumeroDeCajas__c,
                                                    UnidadesPorMasterbox__c,
                                                    Quantity__c,
                                                    Unidades__c
                                                    FROM PedidoLineItems__r)
                                            FROM PedidoDeCompra__c
                                            WHERE Proforma__c = :proForma.Id];
            PackingList__c pl = new PackingList__c(Pedido__c = order.Id);
            insert pl;
            Integer i = 0;
            for(PedidoLineItem__c pli : order.PedidoLineItems__r) {
                pli.PackingList__c = pl.Id;
                pli.Quantity__c = pli.Unidades__c + 4;
            }
            update order.PedidoLineItems__r;
            pl.Estado__c = 'Aprobado';
            update pl;
        test.stopTest();
            PedidoDeCompra__c updOrder = [SELECT Id,
                                            (SELECT Id,
                                                    NumeroDeCajas__c
                                                    FROM PedidoLineItems__r)
                                            FROM PedidoDeCompra__c
                                            WHERE Proforma__c = :proForma.Id];
            i = 0;
            for(PedidoLineItem__c pli : updOrder.PedidoLineItems__r) {
                system.assertEquals(pli.NumeroDeCajas__c, 3);
                i++;
            }
    }

    @isTest
    private static void testException() {
        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        
        test.startTest();        
            proForma = tu.getProforma();
            proForma.ConfirmacionCliente__c = true;
            update proForma;


            PedidoDeCompra__c order = [SELECT Id,
                                            (SELECT Id,
                                                    NumeroDeCajas__c,
                                                    UnidadesPorMasterbox__c,
                                                    Quantity__c,
                                                    Unidades__c
                                                    FROM PedidoLineItems__r)
                                            FROM PedidoDeCompra__c
                                            WHERE Proforma__c = :proForma.Id];
            PackingList__c pl = new PackingList__c(Pedido__c = order.Id);
            insert pl;
            
            for(PedidoLineItem__c pli : order.PedidoLineItems__r) {
                pli.PackingList__c = pl.Id;
                pli.Quantity__c = pli.Unidades__c + 6;
            }
            update order.PedidoLineItems__r;
            pl.Estado__c = 'Aprobado';
            update pl;
        test.stopTest();
        PedidoDeCompra__c updOrder = [SELECT Id,
                                        (SELECT Id,
                                                NumeroDeCajas__c
                                                FROM PedidoLineItems__r)
                                        FROM PedidoDeCompra__c
                                        WHERE Proforma__c = :proForma.Id];
        //system.assertEquals(updOrder.PedidoLineItems__r.size(), 2);
        //changes applied
        for(Integer i = 0; i < updOrder.PedidoLineItems__r.size(); i++) {
            system.assertEquals(updOrder.PedidoLineItems__r[i].NumeroDeCajas__c, order.PedidoLineItems__r[i].NumeroDeCajas__c + 3);
        }
    }
}