@isTest
private class TestSchedulerEnvioBooking 
{
    
    @isTest static void testSchedulerEnvioBooking()
    {
        test.startTest();
        SchedulerBatchEnvioBooking sbeb = new SchedulerBatchEnvioBooking();
        String chron = '0 0 23 * * ?';
        System.schedule('TestSBEB', chron, sbeb);
        test.stopTest();
    }
    
}