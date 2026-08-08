public class PortalPedidoLineItem {
    public PedidoLineItem__c pli;
    public String productoImagen {set; get;}
    public String productoCodigoProveedor {set; get;}
    public String productoName {set; get;}
    public String productoPrecioFabrica {set; get;}
    public String productoCodigoEAN {set; get;}
    public String productoCodigoProductoBase {set; get;}
    public String quantity {set; get;}
    public String totalCnts {set; get;}
    public String netWeight {set; get;}
    public String grossWeight {set; get;}
    public String cbm {set; get;}
    public String containerNUmber {set; get;}
    public String sealNumber {set; get;}

    public PortalPedidoLineItem(PedidoLineItem__c ppli) {
        pli = ppli;

        productoImagen = ppli.Producto__r.ProductoBase__r.IDImagen1__c;
        productoCodigoProveedor = ppli.Producto__r.Codigo_Proveedor2__c;
        productoName = ppli.Producto__r.ProductoBase__r.ProductName__c;
        //productoPrecioFabrica = Decimal d = Decimal.valueOf(!String.isEmpty(ppli.Producto__r.PrecioDeFabrica__c) ? ppli.Producto__r.PrecioDeFabrica__c. : '0');
        productoPrecioFabrica = String.valueOf(ppli.Producto__r.PrecioDeFabrica__c);
        productoCodigoEAN = ppli.Producto__r.Codigo_EAN2__c;
        productoCodigoProductoBase = ppli.Producto__r.CodigoDeProductoBase__c;
        quantity = String.valueOf(ppli.Quantity__c);
        totalCnts = String.valueOf(ppli.Total_Cnts__c);
        netWeight = String.valueOf(ppli.Net_Weight__c);
        grossWeight = String.valueOf(ppli.Gross_Weight__c);
        cbm = String.valueOf(ppli.CBM__c);
        containerNUmber = ppli.Container_Number__c;
        sealNumber = ppli.SEAL_Number__c;
    }

    public void updateValues() {
        pli.Quantity__c = Decimal.valueOf(!String.isEmpty(quantity) ? quantity : '0');
        pli.Total_Cnts__c = Decimal.valueOf(!String.isEmpty(totalCnts) ? totalCnts : '0');
        pli.Net_Weight__c = Decimal.valueOf(!String.isEmpty(netWeight) ? netWeight : '0');
        pli.Gross_Weight__c = Decimal.valueOf(!String.isEmpty(grossWeight) ? grossWeight : '0');
        pli.CBM__c = Decimal.valueOf(!String.isEmpty(cbm) ? cbm : '0');
        pli.Container_Number__c = containerNUmber;
        pli.SEAL_Number__c = sealNumber;
    }
}