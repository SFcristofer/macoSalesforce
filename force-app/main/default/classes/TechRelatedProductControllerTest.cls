@isTest(SeeAllData=true)
private class TechRelatedProductControllerTest {
    @isTest
    static void testGetRelatedProducts() {
        Product2 parentProd = [SELECT Id FROM Product2 LIMIT 1];
        Test.startTest();
        TechRelatedProductController.getRelatedProducts(parentProd.Id);
        Test.stopTest();
    }
}
