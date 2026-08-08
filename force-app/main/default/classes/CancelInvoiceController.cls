/**
 * This controller send a Libra callout in order to cancel an order invoice
 */
public class CancelInvoiceController {
    private String idOrder;
    private List<String> idsOrders;
    private LibraSimpleAltaFactura libraSimpleOrderCallout;
    public List<PedidoParentAccount> orderParentAccounts {set; get;}
    private List<PedidoDeCompra__c> orders;
    
    public CancelInvoiceController(ApexPages.StandardController stdController) {
        idOrder = ApexPages.CurrentPage().getparameters().get('id');
        idsOrders = new List<String>();
        idsOrders.add(idOrder);
        libraSimpleOrderCallout = new LibraSimpleAltaFactura(idsOrders, true);
    }


    public PageReference genereateInvoiceToSend() {
        orderParentAccounts = libraSimpleOrderCallout.buildPedidoParentAccount();
        return null;
    }

    public PageReference executeLibraCallout() {
        orders = new List<PedidoDeCompra__c>();
        for(PedidoParentAccount ppa : orderParentAccounts) {
            if(ppa.pedido.Fecha_Cancelacion_Factura__c == null) {
                ppa.pedido.Fecha_Cancelacion_Factura__c = Date.today();
            }
            orders.add(ppa.pedido);
        }

        update orders;
        libraSimpleOrderCallout.executeLibraCallout();
        return new PageReference('/' + idOrder);
    }

}