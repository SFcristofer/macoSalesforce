public class CommercialInvoice {
    public String razonSocial {get;set;}
    public String calle {get;set;}
    public String ciudad {get;set;}
    public String pais {get;set;}
    public String division {get;set;}
    public String telefono {get;set;}
    public String correo {get;set;}
    public String beneficiario {get;set;}
    public String numeroDeCuenta {get;set;}
    public String bancoBeneficiario {get;set;}
    public String direccionBanco {get;set;}
    public String swiftCode {get;set;}
    private PedidoDeCompra__c pedido;

    public List<DisplayLineItem> items {get;set;}
    public Decimal orderTotal {get;set;}

    public CommercialInvoice(ApexPages.StandardController stdController) {
        String sociedad;
        pedido = (PedidoDeCompra__c)stdController.getRecord();
        System.debug('pedidoId-cuenta: ' + pedido.Proforma__r.Cuenta__r);
        sociedad = DOBrandsDAO.getSociedadFromOrder(pedido.Id);
        getSociedadInfo(sociedad);
        generateDisplayItems();
    }

    public void getSociedadInfo(String sociedad) {
        Sociedades__mdt mdt;
        mdt = [SELECT Id, 
                    MasterLabel,
                    Banco_Beneficiario__c,
                    Beneficiario__c,
                    Calle__c,
                    Calle_2__c,
                    Ciudad__c,
                    Correo_Electronico__c,
                    Direccion_Banco__c,
                    Division__c,
                    Nombre__c,
                    Numero_De_Cuenta__c,
                    Pais__c,
                    Razon_Social__c,
                    SWIFT_Code__c,
                    Telefono__c
                FROM Sociedades__mdt 
                WHERE MasterLabel = :sociedad];
        razonSocial = mdt.Razon_Social__c;
        calle = mdt.Calle__c;
        ciudad = mdt.Ciudad__c;
        pais = mdt.Pais__c;
        division = mdt.Division__c;
        telefono = mdt.Telefono__c;
        correo = mdt.Correo_Electronico__c;
        beneficiario = mdt.Beneficiario__c;
        numeroDeCuenta = mdt.Numero_De_Cuenta__c;
        bancoBeneficiario = mdt.Banco_Beneficiario__c;
        direccionBanco = mdt.Direccion_Banco__c;
        swiftCode = mdt.SWIFT_Code__c;
    }

    public String getSociedad(String accId) {
        String sociedad;
        Account cuenta;
        cuenta = [SELECT Id, 
                        Sociedad__c, 
                        RecordTypeId, 
                        Name 
                    FROM Account
                    WHERE Id = :accId];
        
        sociedad = cuenta.Sociedad__c;
        return sociedad;
    }

    /**
     * Calculates line total prices in the currency of the Customer Order (Proforma)
     */
    public void generateDisplayItems() {
        items = new List<DisplayLineItem>();
        orderTotal = 0;
        for(PedidoLineItem__c li : [SELECT Id,
                                        ProformaLineItem__r.producto__r.CodigoDeProductoBase__c,
                                        ProformaLineItem__r.producto__r.Marca2__c,
                                        ProformaLineItem__r.producto__r.Descripcion_Larga__c,
                                        Unidades__c,
                                        ProformaLineItem__r.PrecioUnitario__c
                                        FROM PedidoLineItem__c
                                        WHERE PedidoDeCompra__c = :pedido.Id]) {
            Decimal lineTotal = li.ProformaLineItem__r.PrecioUnitario__c * li.Unidades__c;
            items.add(new DisplayLineItem(li, lineTotal));
            orderTotal += lineTotal;
        }
   }

   public class DisplayLineItem {
       public PedidoLineItem__c item {get;set;}
       public Decimal itemTotalPrice {get;set;}
       public DisplayLineItem(PedidoLineItem__c i, Decimal iTotalPrice) {
           item = i;
           itemTotalPrice = iTotalPrice;
       }
   }

}