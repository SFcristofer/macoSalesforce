@isTest
private class TestFacturasLibraAprobacion 
{
    
    @isTest static void testFacturasLibraAprobacion() 
    {
        List<PedidoDeCompra__c> pedidos;
        List<PedidoParentAccount> pedidosParentAccountsTest;
        PedidoParentAccount ppa;
        FacturasLibraAprobacion flac;
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        test.startTest();
        tu.initPedidoFacturas();
        pedidos = tu.getPedidosAgente();

        flac = new FacturasLibraAprobacion();
        //pedidosParentAccountsTest = flac.pedidosParentList;
        //for(PedidoParentAccount ppac : pedidosParentAccountsTest)
        //{
        //    ppac.selected = true;
        //}
        //flac.selectInvoices();        
        //flac.aprobar();
        test.stopTest();

    }
        
}