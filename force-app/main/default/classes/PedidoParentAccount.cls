public class PedidoParentAccount 
{
    public PedidoDeCompra__c pedido {set; get;}
    public Account parentAccount {set; get;}
    public List<PedidoLineItem__history> pliHistoryList {set; get;}
    public String alertMsg {set; get;}
    public Boolean selected {set; get;}
    public Integer consecutivo {set; get;}
    public String exchangeRateCliente {set; get;}
    public String exchangeRateProveedor {set; get;}
    public String prefixInvoiceDoAmerica {set; get;}
    public String prefixInvoiceDoCore {set; get;}
    public Boolean hasValidDate {set; get;}
    public String urlOrder {set; get;}
    public Boolean isCancel {set; get;}    

    public PedidoParentAccount() {
        hasValidDate = true;
        isCancel = false;
    }

    public void getAlertMessages() {
       PedidoLineItem__history plih;
       if(pedido.PedidoLineItems__r != null) {
           for(PedidoLineItem__c pli : pedido.PedidoLineItems__r) {
               plih = findPLIH(pli.Id);
               if(plih != null) {
                  alertMsg = alertMsg + '\n' + ' Contiene elementos de pedido modificados en costo o número de cajas'; 
               }
           }
       }
    }

    private PedidoLineItem__history findPLIH(String pliID) {
       for(PedidoLineItem__history plih : pliHistoryList) {
           if(pliID.equals(plih.Parent.Id)) {
               return plih;
           }
       }
       return null;
    }

}