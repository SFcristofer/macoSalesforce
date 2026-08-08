/**
 * This controller belongs to <code>SolicitudTransferenciaInternacional.page<code>
 * The page generates international transfer request file
 */
public class SolicitudTransferenciaInternacional {
    public String sociedad {get;set;}
    public String idProveedor {get;set;}
    public String currentRecordId {get;set;}
    public String proveedorName {get;set;}    
    public PedidoDeCompra__c order {get;set;}    
    public List<PedidoDeCompra__c> orderList {get;set;}    
    public String typeOrder {get;set;}
    public Integer fechaConfirmacionDay {get;set;}
    public Integer fechaConfirmacionMonth {get;set;}
    public Integer fechaConfirmacionYear {get;set;}
    public String importeFormat {get;set;}
    public String transferType {get;set;}
    public String concept {get;set;}
    public String htmlSociedadText {get;set;}

    public Decimal importeDec;
    public String importe {get;set;}
    public String beneficiary {get;set;}
    public String billingStreet {get;set;}
    public String billingCity {get;set;}
    public String billingState {get;set;}
    public String billingPostalCode {get;set;}
    public String billingCountry {get;set;}
    public String bankAccount {get;set;}
    public String bankName {get;set;}
    public String bankAddress {get;set;}
    public String swift {get;set;}

	private String ADELANTO = 'adelanto';
	private String REMANENTE = 'remanente';

    public SolicitudTransferenciaInternacional() {
        idProveedor = ApexPages.CurrentPage().getparameters().get('idProv');
        sociedad  = ApexPages.CurrentPage().getparameters().get('soc');
        typeOrder = ApexPages.CurrentPage().getparameters().get('typeOrdr');

        importe = ApexPages.CurrentPage().getparameters().get('importe');
        importeDec = importe == null ? 0 : Decimal.valueOf(importe);
        concept = ApexPages.CurrentPage().getparameters().get('concept');
        beneficiary = ApexPages.CurrentPage().getparameters().get('beneficiary');
        billingStreet = ApexPages.CurrentPage().getparameters().get('billingSt'); 
        billingCity = ApexPages.CurrentPage().getparameters().get('billingCty');
        billingState = ApexPages.CurrentPage().getparameters().get('billingStt');
        billingPostalCode = ApexPages.CurrentPage().getparameters().get('billingPC');
        billingCountry = ApexPages.CurrentPage().getparameters().get('billingCtry'); 
        bankAccount = ApexPages.CurrentPage().getparameters().get('bankAcc');
        bankName = ApexPages.CurrentPage().getparameters().get('bankNm');
        bankAddress = ApexPages.CurrentPage().getparameters().get('bankAddr');
        swift = ApexPages.CurrentPage().getparameters().get('swift');
 
        if(sociedad.equals('Do Core')) {
            htmlSociedadText = 'DO <strong>Core</strong> Brands Company S.L.';
        } else {
            htmlSociedadText = 'DO Brands <strong>América</strong> Company S.A.';
        }
        if(typeOrder != null) {
          init();
        }
    }

    public void init() {
        List<String> args = new String[]{'0','number','Currency'};
        importeFormat = String.format(importeDec.format(), args);

        fechaConfirmacionDay = Date.today().day();
        fechaConfirmacionMonth = Date.today().month();
        fechaConfirmacionYear = Date.today().year();

        proveedorName = beneficiary;
    }

}