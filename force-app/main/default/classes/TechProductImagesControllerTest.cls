@isTest(SeeAllData=true)
private class TechProductImagesControllerTest {
    @isTest
    static void testSaveImagesSuccess() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Test.startTest();
        TechProductImagesController.saveImages(
            prod.Id, 
            'https://onedrive.live.com/test', 
            'data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=', 
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=', 
            null, 
            null
        );
        Test.stopTest();
    }

    @isTest
    static void testSaveImagesException() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        String longLink = '';
        for (Integer i = 0; i < 260; i++) {
            longLink += 'a';
        }
        Test.startTest();
        try {
            TechProductImagesController.saveImages(prod.Id, longLink, null, null, null, null);
        } catch (Exception e) {}
        Test.stopTest();
    }
}
