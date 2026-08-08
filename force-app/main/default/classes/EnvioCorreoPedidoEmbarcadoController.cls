/**
 * Extension controller for <code>PedidoDeCompra__c</code>
 * 
 */
public class EnvioCorreoPedidoEmbarcadoController {
    private String idOrder;
    private List<String> tiposDocumento;

    private static String DOC_BL = 'BL';
    private static String DOC_FACTURA = 'Factura';
    private static String DOC_PACKING_LIST = 'Packing List';
    private static String CLIENT_DOC_PROCESS = 'Documentación del Cliente';
    private static String EMAIL_TEMPLATE_NAME = 'Final Documents POCliente';

    public static String LABEL_MAIL_SUBJECT = Label.ORDER_MAIL_SUBJECT;
    public static String LABEL_MAIL_BODY = Label.ORDER_MAIL_BODY;

    private static final String DOCUMENTOS_INCOMPLETOS = Label.SHIPPED_ORDER_DOC_INCOMPLETE;
    private static final String CORREO_PREVIAMENTE_ENVIADO = Label.SHIPPED_ORDER_EMAIL_ALREADY_SENT;
    private static final String CORREO_ENVIADO = Label.SHIPPED_ORDER_EMAIL_SENT;

    /**
     * Constructor used by <code>PedidoDeCompra__c</code> custom Object
     */
    public EnvioCorreoPedidoEmbarcadoController(ApexPages.StandardController stdController) {
        idOrder = ApexPages.CurrentPage().getparameters().get('id');
        tiposDocumento = new List<String>{DOC_BL, DOC_FACTURA, DOC_PACKING_LIST};
    }

    /**
     * Send email to the customer contact.
     * The mail is sent when the order has the complete documents
     */
    public PageReference sendEmail() {
        PedidoDeCompra__c shippedOrder;        
        List<String> orderIds;
        List<PedidoDeCompra__c> ordersResult;
        List<String> proformaCuentaIds = new List<String>();
        List<Documento__c> documents;
        List<ContentDocumentLink> docLinks;
        List<String> idsContentVersion = new List<String>();
        List<ContentVersion> contentsVersions;
        List<String> idsDocumentos = new List<String>();        
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment att;
        Blob blobPDFFactura;
        Blob blobPDFPacking;
        Blob blobPDFBL;
        Map<String, OrderDocuments> mapCVOrderDoc = new Map<String, OrderDocuments>();
        Map<String, String> accountContactMap;
        OrderDocuments orderDoc;
        String idContact;

        orderIds = new List<String>();
        orderIds.add(idOrder);

        ordersResult = DOBrandsDAO.getOrdersDocuments(orderIds, tiposDocumento);
        shippedOrder = ordersResult.get(0);
        if(shippedOrder.Documentos_Embarcado_Completos__c == true) {

            if(shippedOrder.Correo_Documentos_Embarcado__c == false) {
                orderDoc = new OrderDocuments(shippedOrder);
    
                proformaCuentaIds.add(shippedOrder.Proforma__r.Cuenta__c);
        
                documents = shippedOrder.Documentos__r;
                if(!documents.isEmpty()) {
                    for(Documento__c doc : documents) {
                        processDocument(doc, orderDoc, idsDocumentos, mapCVOrderDoc);
                    }
                }
    
                if(!idsDocumentos.isEmpty()) {
                    docLinks = DOBrandsDAO.getContentDocumentLink(idsDocumentos);
                }
        
                if(docLinks != null ) {
                    for(ContentDocumentLink dLink : docLinks) {
                        idsContentVersion.add(dLink.ContentDocumentId);
                    }
                }
        
                contentsVersions = DOBrandsDAO.getContentVersions(idsContentVersion);
        
                for(ContentVersion cv : contentsVersions) {
                    orderDoc = mapCVOrderDoc.get(cv.ContentDocumentId);
                    if(orderDoc != null) {
                        orderDoc.addBlob(cv.ContentDocumentId, cv);
                    }
                }
        
                accountContactMap = getAccountContactMap(proformaCuentaIds);
        
                LABEL_MAIL_SUBJECT = LABEL_MAIL_SUBJECT.replace('{0}', orderDoc.order.Name);
                LABEL_MAIL_BODY = LABEL_MAIL_BODY.replace('{0}', orderDoc.order.Name);
            
                blobPDFFactura = orderDoc.documentFacturaFile;
                att = createEmailFileAttachment('INV-' + orderDoc.order.Numero_de_Factura__c + '.pdf', blobPDFFactura);
                attachments.add(att);
                blobPDFPacking = orderDoc.documentPackingListFile;
                att = createEmailFileAttachment('PL-' + orderDoc.order.Numero_de_Factura__c + '.pdf', blobPDFPacking);
                attachments.add(att);
                blobPDFBL = orderDoc.documentBLFile;
                att = createEmailFileAttachment('BL-' + orderDoc.order.Numero_de_Factura__c + '.pdf', blobPDFPacking);
                attachments.add(att);
    
                idContact = accountContactMap.get(orderDoc.order.Proforma__r.Cuenta__c);
                buildAndSendMessage(orderDoc.order.Id, idContact, LABEL_MAIL_SUBJECT, LABEL_MAIL_BODY, attachments);
    
                orderDoc.order.Correo_Documentos_Embarcado__c = true;
                update orderDoc.order;

                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM , CORREO_ENVIADO));                
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING , CORREO_PREVIAMENTE_ENVIADO));
            }
        } else {
            //message , order with incomplete docs
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, DOCUMENTOS_INCOMPLETOS));
        }

        return null;
    }


    /**
     * Build the Email message and send the message
     */
    private static void buildAndSendMessage(String orderId, String contactId, String subject, String textBody, List<Messaging.EmailFileAttachment> attachments) {
        EmailTemplate emailTemplate;
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

        emailTemplate = getEmailTemplate();
        message.setTargetObjectId(contactId);
        message.setWhatId(orderId);
        message.setTemplateId(emailTemplate.Id);

        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        if(attachments != null && attachments.size() > 0) {
            message.setFileAttachments(attachments);
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }

   /**
    * Creates an EmailFileAttachment object
    */
    private static Messaging.EmailFileAttachment createEmailFileAttachment(String fileName, Blob file) {
        Messaging.EmailFileAttachment fileAtt = new Messaging.EmailFileAttachment();
        fileAtt.setFileName(fileName);
        fileAtt.setInline(false);
        fileAtt.setBody(file);
        return fileAtt;
    }


    /**
     * Get the email template
     */
    private static EmailTemplate getEmailTemplate() {
        EmailTemplate emailTemplate = [SELECT Id, Name 
                                         FROM EmailTemplate 
                                        WHERE Name = :EMAIL_TEMPLATE_NAME];
        return emailTemplate;
    }


    /**
     * Get an Account Id - ContactId map
     * The Contact Id associated to Account Id is the newest created contact
     */
    private static Map<String, String> getAccountContactMap(List<String> idAccounts) {
        List<Contact> contacts;
        List<Account> accounts;        
        Map<String, String> accountContact = new Map<String, String>();

        accounts = [SELECT Account.Id, 
                           (SELECT Contact.Id 
                              FROM Contacts 
                          ORDER BY CreatedDate DESC LIMIT 1) 
                      FROM Account 
                     WHERE Account.Id IN (SELECT Contact.accountId 
                                            FROM Contact 
                                           WHERE AccountId IN :idAccounts)];

        for(Account account : accounts) {
            contacts = account.contacts;
            for(Contact contact : contacts) {
                accountContact.put(account.Id, contact.Id);
            }
        }

        return accountContact;
    }

    /**
     * Process the Document__c objetc associated to PedidoDeCompra__c.
     * Group the document by document type and procces 
     */
    public static void processDocument(Documento__c doc, OrderDocuments orderDoc, List<String> idsDocumentos, Map<String, OrderDocuments> mapCVOrderDoc) {
        if(doc.Tipo_de_Documento__c != null && 
           doc.Proceso__c.equals(CLIENT_DOC_PROCESS) && 
           (doc.Tipo_de_Documento__c.equals(DOC_BL) || 
            doc.Tipo_de_Documento__c.equals(DOC_FACTURA) || 
            doc.Tipo_de_Documento__c.equals(DOC_PACKING_LIST)) ) {

            orderDoc.addDocument(doc);
            idsDocumentos.add(doc.Id);
            mapCVOrderDoc.put(doc.Archivo_Principal__c, orderDoc);
        }
    }    
}