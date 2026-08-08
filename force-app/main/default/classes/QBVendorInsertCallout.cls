/**
 * QB Call - Insert vendor
 */
public class QBVendorInsertCallout extends QBCallout {

    /*
     * metadataName - Check QBRESTConfiguration__mdt
     */
    public QBVendorInsertCallout(String metadataName) {
        super(metadataName, QBCallout.HTTP_METHOD_POST);
        QB_RESOURCE_NAME = 'vendor';
    }

    public String buildPayload(String name, String razonSocial, String taxIdentifier, String email, String phone, String mobile) {
        QBVendorPayload objPayload;
        QBVendorEmailPayload mailPayload;
        QBVendorPhonePayload phonePayload;
        QBVendorMobilePayload mobilePayload;        
        String payload;
        
        objPayload = new QBVendorPayload();
        mailPayload = new QBVendorEmailPayload();
        phonePayload = new QBVendorPhonePayload();
        mobilePayload = new QBVendorMobilePayload();
        
        objPayload.DisplayName = name;
        objPayload.CompanyName = razonSocial;
        objPayload.TaxIdentifier = taxIdentifier;
        if(taxIdentifier != null && taxIdentifier.length() > 20) {
            objPayload.TaxIdentifier = taxIdentifier.substring(0,20);
        }

        mailPayload.Address = email;
        phonePayload.FreeFormNumber = phone;
        mobilePayload.FreeFormNumber = mobile;
        
        objPayload.PrimaryEmailAddr = mailPayload;
        objPayload.PrimaryPhone = phonePayload;
        objPayload.Mobile = mobilePayload;
        
        payload = JSON.serialize(objPayload);

        return payload;        
    }

    public override String buildPayload(Object param) {
        Account provider;
        String payload;
        
        provider = (Account)param;
        
        payload = buildPayload(provider.Name, provider.RazonSocial__c ,provider.NroIdFiscal__c, provider.EmailComercial__c , provider.Phone, '');
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
        
       QBVendorCreateResponse responseQB;

        if(response == null) {
            return 'error: QB bad response, please verify the log and contact to your administrator';
        }

        try {
            responseQB = (QBVendorCreateResponse)JSON.deserialize(response, QBVendorCreateResponse.class);
            if(responseQB.Vendor == null) {
                return 'error: QB bad response in add vendor operation.Verify the log and contact your administrator';
            }
            if(responseQB.Vendor.Id == null) {
                return 'error: QB bad response in add vendor operation. Id param. Verify the log and contact your administrator';
            }
        } catch(JSONException je) {
            System.debug(je.getMessage());
            return 'error: QB bad response ' + je.getMessage() + '. Contact your administrator';
        }
        return responseQB;
    }
    
}