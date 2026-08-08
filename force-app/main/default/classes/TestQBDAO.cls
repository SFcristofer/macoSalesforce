@isTest
private class TestQBDAO {

    @isTest static void testQBDAOmethods() {
        QBDAO.fetchQBConfigMetadata('QBConfig');
        QBDAO.getTriggerConfiguration('AccountTrigger');
    }

    
}