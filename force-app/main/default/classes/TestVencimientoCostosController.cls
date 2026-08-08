@isTest
private class TestVencimientoCostosController {

    @isTest static void testVencimientoCostosCtrlr() {
        Opportunity opportunity;
        String idFactory;

        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        opportunity = tu.getOpportunity();

        VencimientoCostosController vcpCtrlr = new VencimientoCostosController();

        for (VencimientoCostoProduct vcp : vcpCtrlr.productsVC) {
            vcp.isMarkedForVerification = true;
        }
    
        vcpCtrlr.verification();
        vcpCtrlr.manualVerification();
    }
}