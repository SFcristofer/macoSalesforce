@isTest
private class TestVerificacionCostoController {

    @isTest static void testVerCostCtrllr() {

        Opportunity opportunity;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        opportunity = tu.getOpportunity();

        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        OppCostVerificationController  ocp = new OppCostVerificationController(sc);

        for(ProductCostVerification pcv : ocp.prods) {
            pcv.isMarkedForVerification = true;
        }

        ocp.manualVerification();

        String strTest;
        Integer intTest;
        Date dateTest;
        Decimal decimalTest;
        Boolean booleanTest;
        VerificacionCostoController vcc = new VerificacionCostoController();
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
    }    
}