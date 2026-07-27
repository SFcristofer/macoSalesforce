@isTest(SeeAllData=true)
private class TechProductOrderHistoryCtrlTest {
    @isTest
    static void testGetOrderHistoryWithData() {
        List<PedidoLineItem__c> existingLines = [SELECT Producto__c FROM PedidoLineItem__c WHERE Producto__c != null LIMIT 1];
        
        Test.startTest();
        if (!existingLines.isEmpty()) {
            TechProductOrderHistoryController.getOrderHistory(existingLines[0].Producto__c);
        } else {
            Product2 dummy = [SELECT Id FROM Product2 LIMIT 1];
            TechProductOrderHistoryController.getOrderHistory(dummy.Id);
        }
        Test.stopTest();
    }
}
