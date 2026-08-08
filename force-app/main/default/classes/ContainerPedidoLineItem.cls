public class ContainerPedidoLineItem {

    public PedidoLineItem__c pedidoLineItem {set; get;}
    public Decimal cantidadTotalItems {set; get;}
    public Decimal cantidadTotalCajas {set; get;}
    public Decimal cantidadCajasCntr {set; get;}
    public Decimal netWeight {set; get;}
    public Decimal grossWeight {set; get;}
    public Decimal cbm {set; get;}

    public ContainerPedidoLineItem() {
        cantidadTotalItems = 0;
        cantidadTotalCajas = 0;
    }


    public ContainerPedidoLineItem(PedidoLineItem__c ppli) {
        cantidadTotalItems = 0;
        cantidadTotalCajas = 0;
        pedidoLineItem = ppli;
        cantidadTotalItems = ppli.Unidades__c;
        cantidadTotalCajas = ppli.NumeroDeCajas__c;
    }
    
    
    public void addNumberItems(PedidoLineItem__c ppli) {
        cantidadTotalItems = cantidadTotalItems + ppli.Unidades__c;
        cantidadTotalCajas = cantidadTotalCajas + ppli.NumeroDeCajas__c;
    }
    
}