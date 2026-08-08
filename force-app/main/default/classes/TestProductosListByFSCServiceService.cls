@IsTest
private class TestProductosListByFSCServiceService {

    @isTest static void testLBFSCService() {
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = 'https://pacificglobal.salesforce.com/services/apexrest/products/listbyfsc?from=1&to=4';
        
        request.httpMethod = 'GET';
        RestContext.request = request;
        // Call the method to test
        ProductosListByFSCServiceService.doGet();

    }

}