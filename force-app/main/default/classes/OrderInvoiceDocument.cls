public class OrderInvoiceDocument {

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
    public String numberSpell {get;set;}
 
    public String LABEL_FOOTER = Label.ORDER_INVOICE_FOOTER;
    public String labelFooter {get;set;}
 
    public OrderInvoiceDocument (ApexPages.StandardController stdController) {
       String sociedad;
       pedido = (PedidoDeCompra__c)stdController.getRecord();
 
       System.debug('pedidoId-cuenta: ' + pedido);
       System.debug('pedidoId-cuenta: ' + pedido.Proforma__r.Cuenta__r);
 
       String strPT = String.valueOf(pedido.Precio_Total__c);
       numberSpell = Util.dobleToWord(strPT).toUpperCase();
       System.debug(numberSpell);
             
       sociedad = DOBrandsDAO.getSociedadFromOrder(pedido.Id);
       getSociedadInfo(sociedad);
       labelFooter = LABEL_FOOTER;
    }
 
    public void getSociedadInfo(String sociedad) {
       Sociedades__mdt mdt = DOBrandsDAO.getSociedadInfo(sociedad);
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
 
 }