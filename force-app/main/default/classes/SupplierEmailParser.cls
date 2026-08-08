/**
*  iestrada   2020-06-24    Add the link un audit report mail to 
*                           PedidoDeCompra__c.URL_Informe_Audiroria__c
* 
*  Parses & Processes a Supplier Email Request
*  @author lcosta@infolastic.com
*  @version 1.0
*/
public class SupplierEmailParser{
    public static final String BOOKING_AGENT = 'Agente';
    public static final String OK = '200';
    public static final String POD_ERROR = 'El POD recibido: [{0}], no coincide con el del pedido: [{1}]\n';
    public static final String POL_ERROR = 'El POL recibido: [{0}], no coincide con el del pedido: [{1}]\n';

    private static String SUBJECT_VALIDATION_BOOKING_C = 'BOOKING CONFIRMATION';    

    public Enum SupplierType{BOOKING_AGENT, FACTORY, OTHER, ERROR}
    private SupplierType supplier;

    public Enum RequestType{BOOKING_CONFIRMATION, ORIGIN_CERTIFICATE, AUDIT, OTHER}
    private RequestType request;
  
    private String senderEmail;
    private String emailSubject;
    private String emailBody;
    private EmailParserConfig__mdt emailParserMdt;
    
    private Messaging.InboundEmail.BinaryAttachment[] attachments;
    private static final String TIPO_DOCUMENTO_AUDITORIA = 'Informe de Auditoría de Calidad';
    private static final String PROCESO_DOCUMENTO_AUDITORIA = 'Producción';
    private Map<String, String> auditReportIncomingMails;

   /**
    *  Initializes the Parser
    */
    public SupplierEmailParser(Messaging.InboundEmail email) {
        List<Envio_Correos__c> ecSCList;
        senderEmail = email.fromAddress;
        emailSubject = email.subject;
        emailBody = email.plainTextBody;
        system.debug('EMAIL BODY: ' + emailBody);
        //Add the Attachments list here
        attachments = email.binaryAttachments;
        // map with accepted incoming e-mail for audit report
        auditReportIncomingMails = new Map<String, String>();
        ecSCList = Util.getCSCorreosTransferencia('informeAuditoria');
        for(Envio_Correos__c eccs : ecSCList) {
            auditReportIncomingMails.put(eccs.correo_electronico__c, eccs.correo_electronico__c);
        }
        emailParserMdt = DOBrandsDAO.getEmailParserMetadatos('Audit');
    }

    /**
    *  Identifies Supplier and Request Type for the email
    *  and processes the request modifying the Order (Pedido__c) accordingly
    *  and attaching any Documents (Documento_DO__c) that may correspond to it
    */
    public void parse(){
        supplier = getSupplierType();
        request = getRequestType();
        List<String> orderRef = getOrderNumbers();

        System.debug('Sender[' + senderEmail + ']');

        //Processing the different types of request
        if(supplier == SupplierType.BOOKING_AGENT && request == RequestType.BOOKING_CONFIRMATION){
            processBookingConfirmation(orderRef);
        } else if (request == RequestType.AUDIT && isValidAuditSender(senderEmail)) {
            //process audit email body 
            processAudit(orderRef);
        }
    }

    /**
    *   Parses the email subject and body to match Order Numbers in the form of PE12345 or PE123456
    *   Returns all parsed Order Numbers if any.
    *
    */
    public list<String> getOrderNumbers(){
        Pattern orderPattern = Pattern.compile('(PE[0-9]{5}[0-9]?)');
        Matcher subjectMatcher = orderPattern.matcher(emailSubject);
        
        set<String> result = new set<String>();
        while(subjectMatcher.find()){
            system.debug('Subject Match: ' + subjectMatcher.group(1));
            result.add(subjectMatcher.group(1));
        }

        if(emailBody != null){
            Matcher bodyMatcher = orderPattern.matcher(emailBody);
            while(bodyMatcher.find()){
                system.debug('Body Match: ' + bodyMatcher.group(1));
                result.add(bodyMatcher.group(1));
            }
        }
        return new list<String>(result);
    }

    /*********************************************************************************************/
    /*********************************** Supplier Type Parsers ***********************************/
    /*********************************************************************************************/

    /**
    *  Returns the Supplier Type for the email based on its sender and content
    *   Enhancement option: Return a structure containing the Account & Contact of the sender
    *   for richer processing, e.g. Verifying if an Agent sending a booking confirmation is actually linked to the Order.
    */  
    private SupplierType getSupplierType(){
        String domainWcard = '%' + getSenderDomain() + '%';

        list<Account> senderAccount = [SELECT Id,
                                        RecordType.DeveloperName
                                        FROM Account
                                        WHERE website like :domainWcard];

        if(!senderAccount.isEmpty()){
            if(isBookingAgent(senderAccount[0])){
                return SupplierType.BOOKING_AGENT;
            }else if(isFactory(senderAccount[0])){
                return SupplierType.FACTORY;
            }
            return SupplierType.OTHER;
        }
        list<Contact> senderContact = [SELECT AccountId,
                                    Account.RecordType.DeveloperName
                                    FROM Contact
                                    WHERE email = :senderEmail
                                    LIMIT 1];
        if(!senderContact.isEmpty()){
            if(isBookingAgent(senderContact[0].Account)){
                return SupplierType.BOOKING_AGENT;
            }else if(isFactory(senderContact[0].Account)){
                return SupplierType.FACTORY;
            }
            return SupplierType.OTHER;
        }
        return SupplierType.ERROR;
    }

    private Boolean isBookingAgent(Account senderAccount){
        if(senderAccount != null){
            if(senderAccount.RecordType.DeveloperName == BOOKING_AGENT){
                return true;
            }
            return false;
        }
        return false;
    }

    private Boolean isFactory(Account senderAccount) {
        return false;
    }

    /**
    *   Given the sender's email gets the domain
    */
    private String getSenderDomain(){
        Pattern p = Pattern.compile('.*@(.*)');
        Matcher m = p.Matcher(senderEmail);
        m.find();
        System.debug('Sender Domain: ' + m.group(1));
        return m.group(1);
    }

    /*
     * Verifies if the sender is a valid incoming e-mail for audit report
     */
    private Boolean isValidAuditSender(String sender) {
        Boolean result = false;

        if(sender != null) {
            if(auditReportIncomingMails.get(sender) != null) {
                result = true;
            }
        }
        return result;
    }

  /*********************************************************************************************/
  /************************************ Request Type Parsers ***********************************/
  /*********************************************************************************************/
  
  /**
  *  Returns the Request Type for the email based on its content
  */  
    private RequestType getRequestType() {
        if(isBookingConfirmation()){
            return RequestType.BOOKING_CONFIRMATION;
        } else if(isOriginCertificate()) {
            return RequestType.ORIGIN_CERTIFICATE;
        } else if(isAudit()) {
            return RequestType.AUDIT;
        }
        return RequestType.OTHER;
    }

    private Boolean isBookingConfirmation() {
        String mailSubject;
        Boolean result = false;
 
        mailSubject = emailSubject;
        mailSubject = mailSubject.toUpperCase();
        if(mailSubject.contains(SUBJECT_VALIDATION_BOOKING_C)) {
            result = true;
        }
        return result;
    }

    private Boolean isOriginCertificate(){
        return false;
    }

    private Boolean isAudit() {
       //subject 
       String mailSubject;
       Boolean result = false;

       mailSubject = emailSubject;
       mailSubject = mailSubject.toUpperCase();
       if(mailSubject.contains(emailParserMdt.Subject_audit__c)) {
           result = true;
       }
       return result;

    }

  /*********************************************************************************************
  *************************** Specific Supplier-Request Processors ****************************
  *********************************************************************************************/

    private void processBookingConfirmation(list<String> orderRef){
        Task tsk = new Task();
        tsk.Subject = 'El Agente ha respondido a la solicitud de Booking';
        tsk.Description = '';
        PedidoDeCompra__c p;
        if(orderRef.size() == 1){
            p = [SELECT Id,
                    Puerto_de_origen__c,
                    Puerto_de_destino__c,
                    OwnerId
                    FROM PedidoDeCompra__c
                    WHERE Name = :orderRef
                    LIMIT 1];
            tsk.WhatId = p.Id;
            //Process the email body
            String result = processBookingConfirmationBody(p, emailBody);
            if(result != OK){
                tsk.Subject += '(con ERROR)';
                tsk.Description += result + '\n\n';
            }
        }else if(orderRef.isEmpty()){
            tsk.Subject = 'Email recibido desde el agente. No se pudo identificar un Pedido';
        }else{
            tsk.Subject = 'Email recibido desde el agente. Varios Pedidos Mencionados';
        }
        //Create the task alerting the booking handler
        tsk.OwnerId = p.OwnerId;
        tsk.Status = 'Open';
        tsk.Type = 'Other';
        tsk.ActivityDate = Date.today();
        tsk.isReminderSet = true;
        tsk.reminderDateTime = Datetime.now();
        tsk.Description += emailSubject + '\n\n' + emailBody;
        insert tsk;
    }

    /**
    *   Extract valuable information from the booking confirmation and validates it against the Order
    *   If Ports match, adds the additional info, otherwise 
    **/
    private String processBookingConfirmationBody(PedidoDeCompra__c p, String emailBody){
            //Check if ports match

            //Get CARRIER, HBL, MBL, VOYAGE/VESSEL and update Order
            Pattern orderPattern = Pattern.compile('.*HBL:(.*)\\n'); //.*MBL:(.*)\\n.*POL:(.*)\\n.*POD:(.*)\\n.*CARRIER:(.*)\\n.*VESSEL/VOYAGE:(.*)\\n.*ETD:(.*)\\n');

            if(emailBody != null){
                Matcher bodyMatcher = orderPattern.matcher(emailBody);
                if(bodyMatcher.find()){
                    system.debug('HBL Match: ' + bodyMatcher.group(1));
                    p.HBL__c = bodyMatcher.group(1).trim();
                }
                orderPattern = Pattern.compile('.*MBL:(.*)\\n');
                bodyMatcher = orderPattern.matcher(emailBody);
                if(bodyMatcher.find()){
                    system.debug('MBL Match: ' + bodyMatcher.group(1));
                    p.MBL__c = bodyMatcher.group(1).trim();
                }
                orderPattern = Pattern.compile('.*CARRIER:(.*)\\n');
                bodyMatcher = orderPattern.matcher(emailBody);
                if(bodyMatcher.find()){
                    system.debug('Carrier Match: ' + bodyMatcher.group(1));
                    p.Carrier__c = bodyMatcher.group(1).trim();
                }
                orderPattern = Pattern.compile('.*VESSEL/VOYAGE:(.*)\\n');
                bodyMatcher = orderPattern.matcher(emailBody);
                if(bodyMatcher.find()){
                    system.debug('VESSEL/VOYAGE Match: ' + bodyMatcher.group(1));
                    p.vessel_voyage__c = bodyMatcher.group(1).trim();
                }
                orderPattern = Pattern.compile('.*ETD:(.*)\\n');
                bodyMatcher = orderPattern.matcher(emailBody);
                if(bodyMatcher.find()){
                    system.debug('ETD Match: ' + bodyMatcher.group(1));
                    p.etd__c = Date.valueOf(bodyMatcher.group(1).trim());
                }
                orderPattern = Pattern.compile('.*POL:(.*)\\n');
                bodyMatcher = orderPattern.matcher(emailBody);
                if(bodyMatcher.find()){
                    system.debug('POL Match: ' + bodyMatcher.group(1));
                    if(!p.Puerto_de_origen__c.trim().toUpperCase().equals(bodyMatcher.group(1).trim().toUpperCase())){
                        return POL_ERROR.replace('{0}', bodyMatcher.group(1)).replace('{1}', p.Puerto_de_origen__c);
                    }
                }
                orderPattern = Pattern.compile('.*POD:(.*)\\n');
                bodyMatcher = orderPattern.matcher(emailBody);
                if(bodyMatcher.find()){
                    system.debug('POD Match: ' + bodyMatcher.group(1));
                    if(!p.Puerto_de_destino__c.trim().toUpperCase().equals(bodyMatcher.group(1).trim().toUpperCase())){
                        return POD_ERROR.replace('{0}', bodyMatcher.group(1)).replace('{1}', p.Puerto_de_destino__c);
                    }
                }
                system.debug('Updating Pedido with booking info..');
                update p;
                system.debug('The pedido was updated');

            }

            return OK;
    }

    /**
     * Process e-mail audit
     */
    private void processAudit(List<String> orderRef) {
        List<InfolasticEmailInboundAttachment> inboundAttachments;
        InfolasticEmailInboundAttachment inboundAttachment;
        RecordType rt;        
        List<PedidoDeCompra__c> pedidos;
        List<PedidoDeCompra__c> pedidosToUpdate;
        Documento__c doc;
        String urlReporte;

        Task tsk;
        List<Task> tasksToInsert;

        String rgpat = emailParserMdt.Regex_Report_URL__c;
        Pattern orderPattern = Pattern.compile(rgpat);

        pedidosToUpdate = new List<PedidoDeCompra__c>();
        tasksToInsert = new List<Task>();

        if(emailBody != null) {
            String match;
            Integer matchesn = 0;
            Matcher bodyMatcher = orderPattern.matcher(emailBody);
            //we extract the hyperlink to autit report
            if(bodyMatcher.find()){
                urlReporte = bodyMatcher.group(0);
            }
        }

        if(orderRef.size() > 0) {

            tsk = new Task();
    
            rt = DOBrandsDAO.getRecordType('Documentacion_Pedido', 'Documento__c');
            pedidos = [SELECT Id,
                    Puerto_de_origen__c,
                    Puerto_de_destino__c,
                    Name,
                    OwnerId
                    FROM PedidoDeCompra__c
                    WHERE Name IN :orderRef];

            for(PedidoDeCompra__c p : pedidos) {
                tsk.Subject = 'Informe de auditoria para el pedido [' + p.Name + ']';
                tsk.Description = '';
                tsk.WhatId = p.Id;
                if(p != null) {
                    //documents
                    if(attachments != null) {
                        inboundAttachments = new List<InfolasticEmailInboundAttachment>();
                        doc = createDocumentDO(PROCESO_DOCUMENTO_AUDITORIA, TIPO_DOCUMENTO_AUDITORIA, rt.Id, p.Id);
    
                        for(Messaging.InboundEmail.BinaryAttachment att : attachments) {
                            inboundAttachment = new InfolasticEmailInboundAttachment(att);
                            inboundAttachments.add(inboundAttachment);
                        }
                        inboundAttachments.sort();
                        inboundAttachment = inboundAttachments.get(inboundAttachments.size() - 1);
                        inboundAttachment.isPrincipal = true;
    
                        System.debug('nameFP [' + inboundAttachment.attachment.fileName + ']');
    
                        for(InfolasticEmailInboundAttachment iatt : inboundAttachments) {
                            createDocument(doc, iatt.attachment.body, iatt.attachment.fileName, iatt.isPrincipal);
                        }
                    }
                    //set the hyperlink in rich text field
                    p.URL_Informe_Audiroria__c = '<a href=\'' + urlReporte + '\'>' + 'Informe auditoria' + '</a>';
                    pedidosToUpdate.add(p);
                }
    
                tsk.OwnerId = p.OwnerId;
                tsk.Status = 'Open';
                tsk.Type = 'Other';
                tsk.ActivityDate = Date.today();
                tsk.isReminderSet = true;
                tsk.reminderDateTime = Datetime.now();
                tsk.Description += emailSubject + '\n\n' + emailBody;
                tasksToInsert.add(tsk);
            }
            update pedidosToUpdate;
            insert tasksToInsert;
        }
  }


    private Documento__c createDocumentDO(String proceso, String tipoDoc, String recordTypeId, String orderId) {
        Documento__c doc = new Documento__c();
        doc.PedidoDeCompra__c = orderId;
        doc.RecordTypeId = recordTypeId;
        doc.Proceso__c = proceso;
        doc.Tipo_de_Documento__c = tipoDoc;
        doc.Name = tipoDoc;
        insert doc;
        return doc;
    }


    private static void createDocument(Documento__c doc, Blob contentFile, String fileName, Boolean isPrincipal) {
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = contentFile;
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        insert cv;

        List<ContentVersion> cdlist = [SELECT ContentDocumentId
                  FROM ContentVersion
                  WHERE Id = :cv.Id
                  limit 1];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cdlist.get(0).ContentDocumentId;
        cdl.LinkedEntityId = doc.Id;
        cdl.ShareType = 'I';

        insert cdl;

        if(isPrincipal) {
            doc.Archivo_Principal__c = cdlist.get(0).ContentDocumentId;
            update doc;
        }
    }

}