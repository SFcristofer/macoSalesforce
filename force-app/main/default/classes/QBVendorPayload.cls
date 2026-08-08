/*
 * Check https://developer.intuit.com/app/developer/qbo/docs/api/accounting/all-entities/vendor
 */
public class QBVendorPayload {

    public QBVendorPayload() {
    }
    
    public String DisplayName {get; set;}
    public String CompanyName {get; set;}
    public String TaxIdentifier {get; set;}
    public QBVendorEmailPayload PrimaryEmailAddr {get; set;}
    public QBVendorPhonePayload PrimaryPhone {get; set;}
    public QBVendorMobilePayload Mobile {get; set;}

}