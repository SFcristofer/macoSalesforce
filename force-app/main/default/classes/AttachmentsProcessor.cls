/**
*	Processes Email Attachments and Inserts Them As a Documento_DO__c linked to a particular
*	Order (Pedido__c).
*/
public class AttachmentsProcessor {
	
    public static final String RT_ORDER = 'Documentacion_Pedido';
	/**
	*	Inserts a new Documento_DO__c with the type and subtype specified by the given
	*	parameters and containing files for all email attachments.
    *   TODO: Create Documento__c instead of Attachment
	*/
	public static void processDocsDO(Id pedidoId, Messaging.InboundEmail email) {
        map<String, RecordType> recordTypes = new map<String, RecordType>();
        for(RecordType rt : [SELECT Id,
    							DeveloperName
                                FROM RecordType
                             WHERE sObjectType = 'Documento__c']){
        	recordTypes.put(rt.DeveloperName, rt);           
        }

		if(email.textAttachments != null)
        {
            // Save attachments, if any
            for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
              Attachment attachment = new Attachment();
             
              attachment.Name = tAttachment.fileName;
              attachment.Body = Blob.valueOf(tAttachment.body);
              attachment.ParentId = pedidoId;
              insert attachment;
            }
        }
        if(email.binaryAttachments != null)
        {
            for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                Documento__c doc = new Documento__c();
                doc.RecordTypeId = recordTypes.get(RT_ORDER).Id;
                doc.PedidoDeCompra__c = pedidoId;
                doc.Proceso__c = 'Documentación del Cliente';
                doc.Tipo_de_Documento__c = 'Packing List';
                doc.Name = doc.Tipo_de_Documento__c;
			    insert doc;
                ContentVersion cv = new ContentVersion();
			    cv.ContentLocation = 'S';
        		cv.VersionData = bAttachment.body;
        		cv.Title = bAttachment.fileName;
        		cv.PathOnClient = bAttachment.fileName;
                insert cv;
                cv = [SELECT ContentDocumentId
                            FROM ContentVersion
                            WHERE Id = :cv.Id];
                ContentDocumentLink cdl = new ContentDocumentLink();
			    cdl.ContentDocumentId = cv.ContentDocumentId;
        	    cdl.LinkedEntityId = doc.Id;
        	    cdl.ShareType = 'I';
            }
        }
	}
}