public class PurchaseOrder {
    private PedidoDeCompra__c c;
    public Decimal totalCost {get;set;}
    public String razonSocial {get;set;}
    public String calle {get;set;}
    public String ciudad {get;set;}
    public String pais {get;set;}
    public String division {get;set;}
    public String telefono {get;set;}
    public String correo {get;set;}
    private PedidoDeCompra__c pedido;    

    public PurchaseOrder(ApexPages.StandardController std){
        
        String sociedad;

        pedido = (PedidoDeCompra__c)std.getRecord();
        System.debug('pedidoId: ' + pedido.Id);
        sociedad = DOBrandsDAO.getSociedadFromOrder(pedido.Id);

        c = [SELECT Id,
                    (SELECT CostoOrigen__c,
                            Unidades__c
                       FROM PedidoLineItems__r)
                FROM PedidoDeCompra__c
               WHERE Id = :std.getId()];
        totalCost = 0;
        for(PedidoLineItem__c ip : c.PedidoLineItems__r){
            totalCost += (ip.CostoOrigen__c * ip.Unidades__c);
        }
        getSociedadInfo(sociedad);
    }


    public void getSociedadInfo(String sociedad)
    {
        Sociedades__mdt mdt = DOBrandsDAO.getSociedadInfo(sociedad);
        razonSocial = mdt.Razon_Social__c;
        calle = mdt.Calle__c;
        ciudad = mdt.Ciudad__c;
        pais = mdt.Pais__c;
        division = mdt.Division__c;
        telefono = mdt.Telefono__c;
        correo = mdt.Correo_Electronico__c;
    }

}