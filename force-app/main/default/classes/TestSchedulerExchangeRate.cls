@isTest
private class TestSchedulerExchangeRate {
  
  @isTest static void testScheduler() {
         test.startTest();
         SchedulerExchangeRate sxr = new SchedulerExchangeRate();
         String chron = '0 0 23 * * ?';
         System.schedule('TestSXR', chron, sxr);
         test.stopTest();
  }  
  
}