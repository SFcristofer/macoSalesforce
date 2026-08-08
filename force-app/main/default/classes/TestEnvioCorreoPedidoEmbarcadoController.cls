@isTest
private class TestEnvioCorreoPedidoEmbarcadoController {

    @isTest static void testEnvioCorreoController() {

        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        Test.startTest();        
        PedidoDeCompra__c pedido = tu.createPedidoDeCompraStatus('Embarcado');
        pedido.Documentos_Embarcado_Completos__c = true;
        pedido.Correo_Documentos_Embarcado__c = false;
        update pedido;
        tu.createDocumentPedido(pedido.Id, 'BL', 'Documentación del Cliente');
        tu.createDocumentPedido(pedido.Id, 'Factura', 'Documentación del Cliente');
        tu.createDocumentPedido(pedido.Id, 'Packing List', 'Documentación del Cliente');                

        System.debug('orderId [' + pedido.Id + '] ');

        ApexPages.currentPage().getParameters().put('id', pedido.Id);
        EnvioCorreoPedidoEmbarcadoController ecpec = new EnvioCorreoPedidoEmbarcadoController(new ApexPages.StandardController(pedido));
        ecpec.sendEmail();

        Test.stopTest();

    }    
}