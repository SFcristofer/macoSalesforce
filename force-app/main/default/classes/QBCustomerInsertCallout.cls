/**
 * QB Call - Insert customer
 */
public class QBCustomerInsertCallout extends QBCallout {

    /*
     * metadataName - Check QBRESTConfiguration__mdt
     */
    public QBCustomerInsertCallout(String metadataName) {
        super(metadataName, QBCallout.HTTP_METHOD_POST);
        QB_RESOURCE_NAME = 'customer';
    }

    public String buildPayload(String name, String razonSocial, String email, String phone) {
        QBCustomerPayload objPayload;
        QBCustomerEmailPayload mailPayload;
        QBCustomerPhonePayload phonePayload;
        String payload;
        
        objPayload = new QBCustomerPayload();
        mailPayload = new QBCustomerEmailPayload(); 
        phonePayload = new QBCustomerPhonePayload();   
        
        objPayload.DisplayName = name;
        objPayload.CompanyName = razonSocial;
        mailPayload.Address = email;
        phonePayload.FreeFormNumber = phone;
        objPayload.PrimaryEmailAddr = mailPayload;
        objPayload.PrimaryPhone = phonePayload;
        
        payload = JSON.serialize(objPayload);

        return payload;        
    }

    public override String buildPayload(Object param) {
        Account customer;
        String payload;
        
        customer = (Account)param;
        
        payload = buildPayload(customer.Name, customer.RazonSocial__c, customer.EmailComercial__c , customer.Phone);
        return payload;
    }

    public override String buildEndpoint(Object param) {
        //'callout:testQBNC/v3/company/9341451964358547/customer?minorversion=65'
        String endpoint;
        endpoint = SF_NAMEDC_SCHEMA + SF_NAMED_CREDENTIAL + QB_URI_CONTEXT + QB_COMPANY_ID + '/' + QB_RESOURCE_NAME;
        return endpoint;
    }

    public override Object processResponse(String response) {
        System.debug('CALL RESULT[' + response + ']');
        QBCustomerCreateResponse responseQB;

        if(response == null) {
            return 'error: QB bad response, please verify the log and contact to your administrator';
        }

        try {
            responseQB = (QBCustomerCreateResponse)JSON.deserialize(response, QBCustomerCreateResponse.class);
            if(responseQB.Customer == null) {
                return 'error: QB bad response in add customer operation.Verify the log and contact your administrator';
            }
            if(responseQB.Customer.Id == null) {
                return 'error: QB bad response in add customer operation. Id param. Verify the log and contact your administrator';
            }
        } catch(JSONException je) {
            System.debug(je.getMessage());
            return 'error: QB bad response ' + je.getMessage() + '. Contact your administrator';
        }
        return responseQB;
    }
    
}