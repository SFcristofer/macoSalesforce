@isTest
public class TestGenerateCatalogue {
    @isTest
    public static void TestGenerateCatalogue() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        Account c = [SELECT Id FROM Account 
                        WHERE RecordType.DeveloperName = 'ClienteContacto' 
                        LIMIT 1];

        test.startTest();
        GenerateCatalogue gc = new GenerateCatalogue(new ApexPages.StandardController(c));
        gc.forward();
        gc.currentCat = GenerateCatalogue.Category.FAM;
        gc.forward();
        //add assertions after each function call
        gc.getFamSelectionStep();
        gc.back();
        gc.getFamSelectionStep();
        gc.forward();
        gc.getSubSelectionStep();
        gc.forward();
        gc.getClaSelectionStep();
        gc.saveCatalogue();
        gc.finish();
        test.stopTest();        
    }

}