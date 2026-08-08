@isTest
private class TechOneDriveServiceTest {
    
    private class OneDriveHttpCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Mock Microsoft Graph API response for thumbnails
            String jsonRes = '{ "value": [ ' +
                             '{ "thumbnails": [ { "large": { "url": "https://test.large.url" } } ] },' +
                             '{ "thumbnails": [ { "medium": { "url": "https://test.medium.url" } } ] }' +
                             '] }';
            
            res.setBody(jsonRes);
            res.setStatusCode(200);
            return res;
        }
    }

    private class OneDriveHttpCalloutMockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "error": "test error" }');
            res.setStatusCode(400);
            return res;
        }
    }

    @isTest
    static void testGetFolderThumbnailsSuccess() {
        Test.setMock(HttpCalloutMock.class, new OneDriveHttpCalloutMock());
        
        Test.startTest();
        List<String> urls = TechOneDriveService.getFolderThumbnails('https://1drv.ms/f/s!TestLink123');
        Test.stopTest();
        
        System.assertEquals(2, urls.size(), 'Should return 2 URLs');
        System.assertEquals('https://test.large.url', urls[0]);
        System.assertEquals('https://test.medium.url', urls[1]);
    }

    @isTest
    static void testGetFolderThumbnailsBlank() {
        Test.startTest();
        List<String> urls = TechOneDriveService.getFolderThumbnails('');
        Test.stopTest();
        System.assertEquals(0, urls.size());
    }

    @isTest
    static void testGetFolderThumbnailsError() {
        Test.setMock(HttpCalloutMock.class, new OneDriveHttpCalloutMockError());
        
        Test.startTest();
        try {
            TechOneDriveService.getFolderThumbnails('https://1drv.ms/f/s!TestLink123');
            System.assert(false, 'Expected an exception due to 400 status');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Error API Microsoft'));
        }
        Test.stopTest();
    }
}