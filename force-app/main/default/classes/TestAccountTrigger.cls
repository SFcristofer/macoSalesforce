@isTest
public class TestAccountTrigger {

    @isTest static void testAccountChangeAuthCredit() {
        Account parent;
        TestUtil tu = new TestUtil();
        tu.initCliente();
        parent = tu.getClienteCred();

        parent.Credito_autorizado__c = 4000;

        update parent;

        parent = [SELECT Name, Credito_autorizado__c, Balance_Cuenta__c FROM Account WHERE Codigo_rapido__c = '22233'];
        System.debug(parent.Balance_Cuenta__c);
        //System.assert(parent.Balance_Cuenta__c == 4000);
    }

}