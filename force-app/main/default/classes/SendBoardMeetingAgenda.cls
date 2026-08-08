public with sharing class SendBoardMeetingAgenda {
	
    public final String EMAIL_SUBJECT = 'Informe Direccion';

    public final String SENT_ERROR = 'El informe ya ha sido enviado anteriormente';
    public final String SENT_MSG = 'Se envió el informe a los destinatarios con éxito';

    private Informe_Direccion__c infoDir;

    public SendBoardMeetingAgenda(ApexPages.StandardController std) {
		infoDir = [SELECT id,
                            Asunto__c,
                            Enviado__c,
                            Enviar_a__c
                            FROM Informe_Direccion__c
                            WHERE Id = :std.getId()];
	}

    public PageReference sendMail(){
        if(infoDir.Enviado__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, SENT_ERROR));
        }else{
            Messaging.reserveSingleEmailCapacity(2);
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            // Strings to hold the email addresses to which you are sending the email.

            String[] toAddresses = InfoDir.Enviar_a__c.split(',');
            mail.setToAddresses(toAddresses);
            
            // Specify the address used when the recipients reply to the email. 
            mail.setReplyTo('ruben.bernardo@pacificglob.com');

            // Specify the name used as the display name.
            mail.setSenderDisplayName('Ruben Bernardo');

            // Specify the subject line for your email address.
            mail.setSubject(infoDir.Asunto__c);

            PageReference bMAgenda = Page.BoardMeetingAgenda;
            bMAgenda.getParameters().put('id',infoDir.id);
            if(!Test.isRunningTest()){
                mail.setHtmlBody(bMAgenda.getContent().toString());
            }else{
                mail.setPlainTextBody('This is running within a Test Method');
            }

            //Save the email sent as a File linked to the record
            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            if(!Test.isRunningTest()){
                cv.VersionData = bMAgenda.getContentAsPDF();
            }else{
                cv.VersionData = Blob.valueOf('Some file');
            }
            
            //cv.VersionData = Blob.valueOf('OOpps');
            cv.Title = EMAIL_SUBJECT;
            cv.PathOnClient = EMAIL_SUBJECT + '.pdf';
            insert cv;
            cv = [SELECT ContentDocumentId
                        FROM ContentVersion
                        WHERE Id = :cv.Id];
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = infoDir.Id;
            cdl.ShareType = 'I';
            insert cdl;

            infoDir.Enviado__c = true;
            infoDir.Fecha_Enviado__c = Date.today();
            update infoDir;

            // Send the email you have created.
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, SENT_MSG));
        }
        return null;
    }

}