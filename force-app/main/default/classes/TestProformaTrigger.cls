@isTest
public class TestProformaTrigger
{

    @isTest static void testProforma() 
    {
        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        Test.startTest();
        proForma = tu.getProforma();
        proForma.ConfirmacionCliente__c = true;
        
        update proForma;
        test.stopTest();
    }

    @isTest static void testProformaConsecutivo() 
    {
        TestUtil tu = new TestUtil();
        tu.initProformaTest('Autogenerado');
        Test.startTest();        
        PedidoDeCompra__c pedido = tu.createPedidoDeCompra('volume');
        test.stopTest();
    }
    
}