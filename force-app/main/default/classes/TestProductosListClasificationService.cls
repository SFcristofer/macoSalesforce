@IsTest
private class TestProductosListClasificationService {

    @isTest static void testGetCaseById() {
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = 'https://pacificglobal.salesforce.com/services/apexrest/products/listclasification';
        
        request.httpMethod = 'GET';
        RestContext.request = request;
        // Call the method to test
        ProductosListClasificationService.doGet();
        // Verify results
    }

}