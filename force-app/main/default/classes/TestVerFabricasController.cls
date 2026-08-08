@isTest
private class TestVerFabricasController {

    @isTest static void testApprobacion() {
        Product2 factoryProduct;
        String baseProdId;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();

        factoryProduct = tu.parrilla;
        baseProdId = factoryProduct.ProductoBase__c;

        ApexPages.currentPage().getParameters().put('idBaseProduct', baseProdId);
        VerFabricasController  vfc = new VerFabricasController();
    }
}