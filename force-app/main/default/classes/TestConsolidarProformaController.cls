@isTest
private class TestConsolidarProformaController {

    @isTest static void testShowingItems() {
        List<ConsolidarProformaController.ProformaWrapper> prfag;
        Proforma__c pr;
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();

        pr = tu.getProformaCred();

        ApexPages.currentPage().getParameters().put('id', pr.Id);
        ConsolidarProformaController cpc = new ConsolidarProformaController(new ApexPages.StandardController(pr));

        prfag = cpc.proformasPorAgrupar;

        for(ConsolidarProformaController.ProformaWrapper pw : prfag) {
            pw.selected = true;
        }

        cpc.mostrarProformasAgrupadas();
        cpc.agruparProformas();

    }

}