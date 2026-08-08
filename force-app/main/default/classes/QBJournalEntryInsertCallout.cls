/**
 * QB Call - Insert Journal Entry
 */
public class QBJournalEntryInsertCallout extends QBCallout {
    private static final String JOURNAL_TYPE_CRED = 'Credit';
    private static final String JOURNAL_TYPE_DEB = 'Debit';
    private static final String JOURNAL_ENTITY_TYPE_VENDOR = 'Vendor';

    /*
     * metadataName - Check QBRESTConfiguration__mdt
     */
    public QBJournalEntryInsertCallout(String metadataName) {
        super(metadataName, QBCallout.HTTP_METHOD_POST);
        QB_RESOURCE_NAME = 'journalentry';
    }

    public override String buildPayload(Object param) {
        QBJournalPayloadEntry objPayload;
        List<QBJournalPayloadEntryLine> lines;

        QBJournalPayloadEntity entity;
        QBJournalPayloadEntityRef entityRef;
        
        List<ItemDeFacturaDeProveedor__c> itemsFactura;
        String payload;
        FacturaDeProveedor__c factura;

        factura = (FacturaDeProveedor__c)param;

        objPayload = new QBJournalPayloadEntry();
        objPayload.DocNumber = factura.QboJournalEntryNo__c;
        objPayload.PrivateNote = factura.QboJournalEntryDescription__c;
        objPayload.TxnDate = String.valueOf(factura.FechaDeFactura__c);//yyyy-mm-dd
        
        entityRef = new QBJournalPayloadEntityRef();
        entityRef.value = factura.Proveedor__r.IdQbo__c;
        
        entity = new QBJournalPayloadEntity();
        entity.Type = JOURNAL_ENTITY_TYPE_VENDOR;
        entity.EntityRef = entityRef;    
        
        lines = new List<QBJournalPayloadEntryLine>();
        objPayload.Line = lines;
        
        createLine(JOURNAL_TYPE_DEB, factura, lines, entity);
        createLine(JOURNAL_TYPE_CRED, factura, lines, entity);

        payload = JSON.serialize(objPayload);
        return payload;
    }
    
    
    private void createLine(String type, FacturaDeProveedor__c factura, List<QBJournalPayloadEntryLine> lines, QBJournalPayloadEntity entity) {
        QBJournalPayloadEntryLine line;
        QBJournalPayloadEntryLineDetail lineDetail;
        QBJournalPayloadAccRef apAccRef;
        
        line = new QBJournalPayloadEntryLine();
        line.Description = factura.QboJournalEntryDescription__c;
        line.Amount = String.valueOf(factura.Total__c);
        lineDetail = new QBJournalPayloadEntryLineDetail();
        lineDetail.PostingType = type;
        
        apAccRef = new QBJournalPayloadAccRef();
        
        if(type.equals('Credit')) {
            apAccRef.value = QB_JOURNAL_ACC_REF_CRED;
        }
        if(type.equals('Debit')) {
            apAccRef.value = QB_JOURNAL_ACC_REF_DEB;
        }
        
        lineDetail.AccountRef = apAccRef;        
        lineDetail.Entity = entity;
        line.JournalEntryLineDetail = lineDetail;
        lines.add(line);
    }

    public override String buildEndpoint(Object param) {
        //'callout:testQBNC/v3/company/9341451964358547/journalentry?minorversion=65'
        String endpoint;
        endpoint = SF_NAMEDC_SCHEMA + SF_NAMED_CREDENTIAL + QB_URI_CONTEXT + QB_COMPANY_ID + '/' + QB_RESOURCE_NAME;
        return endpoint;
    }


    public override Object processResponse(String response) {
        QBJournalCreateResponse responseQB;
        System.debug('CALL RESULT[' + response + ']');

        if(response == null) {
            return 'error: QB bad response, please verify the log and contact to your administrator';
        }

        try {
            responseQB = (QBJournalCreateResponse)JSON.deserialize(response, QBJournalCreateResponse.class);
            if(responseQB.JournalEntry == null) {
                return 'error: QB bad response in add journal entry operation.Verify the log and contact your administrator';
            }
            if(responseQB.JournalEntry.Id == null) {
                return 'error: QB bad response in add journal entry operation. Id param. Verify the log and contact your administrator';
            }
        } catch(JSONException je) {
            System.debug(je.getMessage());
            return 'error: QB bad response ' + je.getMessage() + '. Contact your administrator';
        }

        return responseQB;
    }

}