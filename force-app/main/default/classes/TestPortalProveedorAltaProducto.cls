@isTest
private class TestPortalProveedorAltaProducto {
    @isTest static void testPortalProveedorAlta() {
        Account fabrica;
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();
        fabrica = tu.getFabrica();

        ApexPages.currentPage().getParameters().put('dbrToken', '123456');

        PortalProveedorAltaProductoController pptc1 = new PortalProveedorAltaProductoController();
        pptc1.loadPage();

        ApexPages.currentPage().getParameters().put('dbrToken', '12345');

        PortalProveedorAltaProductoController pptc = new PortalProveedorAltaProductoController();
        pptc.loadPage();

        pptc.product.Name = 'tst';
        pptc.saveProduct();
        pptc.finish();
        pptc.saveChanges();

    }

}