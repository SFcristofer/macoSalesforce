/*
 * Check https://developer.intuit.com/app/developer/qbo/docs/api/accounting/most-commonly-used/customer
 */
public class QBCustomerPayload {

    public QBCustomerPayload() {
    }
    
    public String DisplayName {get; set;}
    public String CompanyName {get; set;}    
    public QBCustomerEmailPayload PrimaryEmailAddr {get; set;}
    public QBCustomerPhonePayload PrimaryPhone {get; set;}

}