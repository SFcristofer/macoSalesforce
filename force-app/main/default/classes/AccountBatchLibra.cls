public class AccountBatchLibra {

    public Account account {set; get;}
    public String identifierSociedad {set; get;}
    public String codigoRapido {set; get;}
    public String numeroSecuencia {set; get;}

    public AccountBatchLibra(Account cuenta, String sociedad, String pcodigoRapido, String psecuencia) {
        account = cuenta;
        identifierSociedad = sociedad;
        codigoRapido = pcodigoRapido;
        numeroSecuencia = psecuencia;
        if(account.NroIdFiscal__c != null) {
            account.NroIdFiscal__c = (account.NroIdFiscal__c.length() > 15 ? account.NroIdFiscal__c.substring(0, 14) : account.NroIdFiscal__c);
        }
        if(account.Name != null) {
            account.Name = (account.Name.length() > 40 ? account.Name.substring(0, 39) : account.Name);
        }
        if(account.RazonSocial__c != null) { 
            account.RazonSocial__c = (account.RazonSocial__c.length() > 40 ? account.RazonSocial__c.substring(0, 39) : account.RazonSocial__c);
        }
        if(account.BillingStreet != null) {
            account.BillingStreet = (account.BillingStreet.length() > 50 ? account.BillingStreet.substring(0, 49) : account.BillingStreet);
        }
        if(account.BillingCity != null) {
            account.BillingCity = (account.BillingCity.length() > 50 ? account.BillingCity.substring(0, 49) : account.BillingCity);
        }
        account.BillingPostalCode = (account.BillingPostalCode == null || account.BillingPostalCode.equals('')) ? '11111' : account.BillingPostalCode;
    }
}