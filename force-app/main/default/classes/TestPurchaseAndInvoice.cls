/**
 * This class test the controllers associated to generate PDF files for orders
 * - invoice
 * - purchase order
 */
@isTest
private class TestPurchaseAndInvoice 
{
	
    @isTest static void testPurchase() {
        PedidoDeCompra__c pedido;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        tu.initPedidoPurchaseInvoice();
        pedido = tu.getPedidoCompra();

        System.debug('pedido[' + pedido + ']');

        ApexPages.StandardController stdOrder = new ApexPages.StandardController(pedido);
		PurchaseOrder purchaseOrdr = new PurchaseOrder(stdOrder);
    }
 
    @isTest static void testInvoice() {
        PedidoDeCompra__c pedido;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        tu.initPedidoPurchaseInvoice();
        pedido = tu.getPedidoCompra();

        System.debug('pedido-invoice[' + pedido + ']');

        ApexPages.StandardController stdOrder = new ApexPages.StandardController(pedido);
		CommercialInvoice invoiceOrdr = new CommercialInvoice(stdOrder);
    }

    @isTest static void testInvoiceFinal() {
        PedidoDeCompra__c pedido;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        tu.initPedidoPurchaseInvoice();
        pedido = tu.getPedidoCompra();

        System.debug('pedido-invoiceN[' + pedido + ']');

        ApexPages.StandardController stdOrder = new ApexPages.StandardController(pedido);
		OrderInvoiceDocument invoiceOrdr = new OrderInvoiceDocument(stdOrder);
    }

    @isTest static void testPackingList() {
        PedidoDeCompra__c pedido;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        tu.initPedidoPurchaseInvoice();
        pedido = tu.getPedidoCompra();

        System.debug('pedido-invoiceN[' + pedido + ']');

        ApexPages.StandardController stdOrder = new ApexPages.StandardController(pedido);
		OrderPackingListDocument invoiceOrdr = new OrderPackingListDocument(stdOrder);
    }

}