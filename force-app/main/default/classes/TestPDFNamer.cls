@isTest
private class TestPDFNamer{
    @isTest
    private static void testNamer(){
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        Proforma__c pr = tu.getProforma();
        PDFNamer pdfNamer = new PDFNamer(new ApexPages.StandardController(pr));
        system.assertEquals(Apexpages.currentPage().getHeaders().get('content-disposition'),
                            'inline; filename=' + pr.Name + '.pdf' );
    }
}