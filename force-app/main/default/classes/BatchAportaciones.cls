global class BatchAportaciones implements Database.Batchable<sObject> {
    private Date fechaIni;
    private String MAIL_SUBJECT = 'Aportaciones DO Brands - Cierre ';
    private String MAIL_BODY = 'Estimado Nacho,\n\n Adjuntamos aportaciones comerciales firmadas a cierre de ';
    private String MAIL_BODY_FIN = ' [Esto es un correo electrónico generado por el sistema - No Responder]\n';
    private String[] deliveryMails;
    private List<String> deliveryMailsList; 

    global BatchAportaciones() {
        fechaIni = Date.today().addMonths(-1);
        initCustomSettings();
    }

   /**
    * Inicializa custom settings
    */
    private void initCustomSettings() {
        List<Envio_Correos__c> ecSCList;

        ecSCList = Util.getCSCorreosTransferencia('aportacion');
                    
        deliveryMails = new String[ecSCList.size()];
        Integer i = 0;
        for(Envio_Correos__c ec : ecSCList) {
            deliveryMails[i] = ec.correo_electronico__c;
            i++;
        }
    }

   /**
    * get the data
    */
    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Id, 
                                                Name, 
                                                Descripcion__c, 
                                                Fecha__c, 
                                                Importe__c,
                                                MesAno__c,
                                                Planificacioncomercial__r.Name, 
                                                Planificacioncomercial__r.ObjetivoDeAportaciones__c,
                                                Planificacioncomercial__r.Cuenta__c,
                                                Planificacioncomercial__r.Cuenta__r.Name,
                                                Planificacioncomercial__r.Cuenta__r.ParentId
                                                FROM Aportacion__c
                                                WHERE Estado__c = 'Lista'
                                                AND Enviada_Administracion__c = false]);
    }

    global void execute(Database.BatchableContext BC, List<Aportacion__c> scope) {
        String dateMonth;
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        ContentVersion doc;
        Messaging.EmailFileAttachment attcv;
        List<Id> idAportaciones = new List<Id>();
        for(Aportacion__c a : scope) {
            idAportaciones.add(a.Id);
        }
        Map<Id, ContentVersion> aIdToDoc = genApIdToDocMap(genDocIdToLinkMap(idAportaciones));
        for(Aportacion__c a : scope) {
            if(aIdToDoc.containsKey(a.Id)) {
                doc = aIdToDoc.get(a.Id);
                attcv = createFileAttachmentFromContentVersion(a.Name, doc);
                attachments.add(attcv);
            }
            a.Enviada_Administracion__c = true;
        }

        Messaging.EmailFileAttachment att;
        //create page
        att = createFileAttachment(fechaIni);
        attachments.add(att);
        //send mail
        dateMonth = Util.getMonth(fechaIni.month());
        buildAndSendMessage(deliveryMails, MAIL_SUBJECT + dateMonth + ' ' + fechaIni.year(), MAIL_BODY + dateMonth + ' ' + fechaIni.year() + MAIL_BODY_FIN, attachments);
        update scope;
    }


    global void finish(Database.BatchableContext BC) {
    }

    private Messaging.EmailFileAttachment createFileAttachment(Date fechaIni) {
        Blob blobPDF;
        Messaging.EmailFileAttachment fileAtt;

        PageReference vfPdf =  Page.ReporteAportaciones;
        if(Test.isRunningTest()) {
            blobPDF = Blob.valueOf('Unit.Test');
        } else {
            blobPDF = vfPdf.getContentAsPDF();
        }
        fileAtt = createEmailFileAttachment('AportacionesCierre' + Util.getMonth(fechaIni.month()) + '-' + fechaIni.year() + '.pdf', blobPDF);
        return fileAtt;
    }

   /**
    * Crea un objeto de tipo archivo adjunto para ser enviado por correo
    */
    private Messaging.EmailFileAttachment createEmailFileAttachment(String fileName, Blob file) {
        Messaging.EmailFileAttachment fileAtt = new Messaging.EmailFileAttachment();
        fileAtt.setFileName(fileName);
        fileAtt.setInline(false);
        fileAtt.setBody(file);
        return fileAtt;
    }

    private static void buildAndSendMessage(String[] deliveryMails, String subject, String textBody, 
                                                            List<Messaging.EmailFileAttachment> attachments) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = deliveryMails;
        message.subject = subject;
        message.plainTextBody = textBody;
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};

        if(attachments != null && attachments.size() > 0) {
            message.setFileAttachments(attachments);
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }

    private Map<Id, ContentDocumentLink> genDocIdToLinkMap(List<String> idAportaciones) {
        Map<Id, ContentDocumentLink> result = new Map<Id, ContentDocumentLink>();
        for(ContentDocumentLink cdl: [SELECT Id, 
                                    ContentDocumentId, 
                                    LinkedEntityId
                                    FROM ContentDocumentLink 
                                    WHERE LinkedEntityId IN :idAportaciones]) {
            result.put(cdl.ContentDocumentId, cdl);
        }
        return result;
    }

    private Map<Id, ContentVersion> genApIdToDocMap(Map<Id, ContentDocumentLink> docIdToLinkMap) {
        Map<Id, ContentVersion> result = new Map<Id, ContentVersion>();
        List<ContentVersion> docs = [SELECT ContentDocumentId,
                                        FileExtension,
                                        VersionData
                                        FROM ContentVersion
                                        WHERE ContentDocumentId IN :docIdToLinkMap.keySet()];
        for(ContentVersion cv : docs) {
            result.put(docIdToLinkMap.get(cv.ContentDocumentId).LinkedEntityId, cv);
        }
        return result;
    }

    private Messaging.EmailFileAttachment createFileAttachmentFromContentVersion(String name, ContentVersion contentVersion) {
        Blob blobFile;
        Messaging.EmailFileAttachment fileAtt;          
        blobFile = contentVersion.VersionData;
        fileAtt = createEmailFileAttachment(name + '.' + contentVersion.FileExtension, blobFile);
        return fileAtt;
    }
}