@isTest
private class TestChangeProvider {
    
    @isTest static void testChangeProvider() {
        //Confirm Proforma so it generates a Pedido with the same Items
        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        tu.createAltProdDeFabrica(true); //Create alternatives for all Products
        Test.startTest();
        proForma = tu.getProforma();
        proForma.ConfirmacionCliente__c = true;


        update proForma;        
        tu.createPedidoDeCompra('volume');
        PedidoDeCompra__c p = tu.getPedidos()[0];
        ChangeProvider cp = new ChangeProvider(new ApexPages.StandardController(p));
        //cp.selectedProvider = cp.altProviders[0].provider.Id;
        cp.changeProvider();
        Test.stopTest();
    }
    
    @isTest static void testNOFullMatchProvider() {
        //Confirm Proforma so it generates a Pedido with the same Items
        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        tu.createAltProdDeFabrica(false); //Create alternatives for all (but one) Products
        Test.startTest();
        proForma = tu.getProforma();
        proForma.ConfirmacionCliente__c = true;

        update proForma;
        PedidoDeCompra__c pedido = tu.createPedidoDeCompra('volume');       
        PedidoDeCompra__c p = tu.getPedidos()[0];
        ChangeProvider cp = new ChangeProvider(new ApexPages.StandardController(p));
        Test.stopTest();
    }

    @isTest static void testNOAltProvider() {
        //Confirm Proforma so it generates a Pedido with the same Items
        Account proveedor;
        Proforma__c proForma;
        TestUtil tu = new TestUtil();

        tu.initProformaTest();
        proveedor = tu.createFabrica();
        
        Test.startTest();       
        proForma = tu.getProforma();
        proForma.ConfirmacionCliente__c = true;
        update proForma;

        PedidoDeCompra__c c = new PedidoDeCompra__c(Proforma__c = proForma.Id, Email_Facturacion_Cliente__c = 'test@test.com', Proveedor__c = proveedor.Id);
        insert c;
        PedidoDeCompra__c p = tu.getPedidos()[0];
        ChangeProvider cp = new ChangeProvider(new ApexPages.StandardController(p));
        Test.stopTest();
    }
    
    
}