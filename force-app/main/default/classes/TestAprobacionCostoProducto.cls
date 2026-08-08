@isTest
private class TestAprobacionCostoProducto {


    @isTest static void testApprobacion() {

        Opportunity opportunity;
        String idFactory;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        opportunity = tu.getOpportunity();

        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        OppCostVerificationController  ocp = new OppCostVerificationController(sc);

        for(ProductCostVerification pcv : ocp.prods) {
            pcv.isMarkedForVerification = true;
            idFactory = pcv.idFactory;
        }

        ocp.manualVerification();
        

        String strTest;
        Integer intTest;
        Date dateTest;
        Decimal decimalTest;
        Boolean booleanTest;
        ApexPages.currentPage().getParameters().put('idFct', idFactory);
        AprobacionCostoProducto vcc = new AprobacionCostoProducto();

        for(OppFactProdVerification ofpvm : vcc.verifications) {
            ofpvm.isCostApproved = true;
            ofpvm.newCostProduct = 15.5;
        }

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