@isTest
private class TestContainerPLPDFController {

    @isTest static void testContainerController() {
        Container__c cntr;
        Container_Pedido_Line_Item__c cntrItem;
        List<Container__c> cntrs;        
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();
        PedidoDeCompra__c pedido;

        pedido = tu.pedido1;
        cntr = new Container__c(Name = 'TSTCNTR1',
                                Fecha_Carga_Contenedor__c = Date.today(),
                                Pedido__c = pedido.Id,
                                SEAL__c = 'SL123',
                                Type__c = '40 HQ');
                                             
        insert cntr;
        
        cntrItem = new Container_Pedido_Line_Item__c(Name = 'Item1',
                                                     Container__c = cntr.Id,
                                                     CBM__c = 5,
                                                     Gross_Weight__c = 5,
                                                     Net_Weight__c = 5);
                                                     
        insert cntrItem;
        
        ContainerPLPDFController ctrlr = new ContainerPLPDFController(new ApexPages.StandardController(tu.pedido1));        
    }

}