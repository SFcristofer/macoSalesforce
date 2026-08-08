@isTest
private class TestExchangeRateClient {

    @isTest static void testExchangeRateClient() {
        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('exchangeRate'));
        Test.startTest();
        ExchangeRateClient erc = ExchangeRateClient.getInstance();
        erc.getExchangeRate('https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml', 'USD');
        Test.stopTest();
    }

}