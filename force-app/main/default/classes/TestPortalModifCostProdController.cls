@isTest

private class TestPortalModifCostProdController {

    @isTest static void testPortalVerif() {
        Account fabrica;
        Opportunity opportunity;
        String idFactory;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        opportunity = tu.getOpportunity();
        fabrica = tu.getFabrica();

        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        OppCostVerificationController  ocp = new OppCostVerificationController(sc);

        for(ProductCostVerification pcv : ocp.prods) {
            pcv.isMarkedForVerification = true;
            idFactory = pcv.idFactory;
        }

        ocp.manualVerification();


        //ApexPages.currentPage().getParameters().put('dbrToken', '123456');
        //PortalProveedorAltaProductoController pptc1 = new PortalProveedorAltaProductoController();
        //pptc1.loadPage();



        //PortalProveedorAltaProductoController pptc = new PortalProveedorAltaProductoController();
        //pptc.loadPage();

        

        String strTest;
        Integer intTest;
        Date dateTest;
        Decimal decimalTest;
        Boolean booleanTest;
        ApexPages.currentPage().getParameters().put('dbrToken', '12345');

        PortalModifCostProdController vcc = new PortalModifCostProdController();
        vcc.loadPage();

        for(OppFactProdVerification ofpv : vcc.verifications) {
            strTest = ofpv.englishProductDescription;
            intTest = ofpv.oppRev;
            dateTest = ofpv.fechaStatus;
            strTest = ofpv.imageInfo;
            strTest = ofpv.supplierCodeProduct;
            decimalTest = ofpv.oldCostProduct;
            strTest = ofpv.estado;
            booleanTest = ofpv.isCostApproved;
        }

        vcc.aprobar();
    }      

}