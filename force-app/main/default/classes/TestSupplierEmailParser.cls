@isTest
private class TestSupplierEmailParser {
    
    @testSetup static void testSetup(){
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agente').getRecordTypeId();

        Account agent = new Account(Name = 'Super Agent',
                                    RecordTypeId = idRT,
                                    Website = 'superbooking.com');
        insert agent;
        Contact agentContact = new Contact(LastName = 'Mr. Bob',
                                            email = 'bob@booking-partner.com',
                                            AccountId = agent.Id);
        insert agentContact;
    }
    
    @isTest static void testParsingWrongFormat() {
        // Initialize test data
        Account provider;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        
        provider = tu.createFabrica();
        
        test.startTest();
        PedidoDeCompra__c p = new PedidoDeCompra__c(Name = 'PE20999',
                                                    Proforma__c = [SELECT Id FROM Proforma__c LIMIT 1].Id,
                                                    Proveedor__c = provider.Id);
        insert p;
        
        AttachmentsProcessor a = new AttachmentsProcessor();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = 'Booking Confirmation for PE20999';
        email.plainTextBody = 'Nothing fancy. No useful data';
        email.fromAddress = 'bob@booking-partner.com';
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('Attached Booking Confirmation');
        attachment.fileName = 'bookingConfirmation.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        //Start the EmailParser
        DOSuppliersHandler dsh = new DOSuppliersHandler();
        dsh.handleInboundEmail(email, env);
        test.stopTest();
    }

    @isTest static void testParsingMoreThanOnePE() {
        Account provider;
        // Initialize test data
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        
        provider = tu.createFabrica();
                
        test.startTest();
        PedidoDeCompra__c p = new PedidoDeCompra__c(Name = 'PE20999',
                                                    Proforma__c = [SELECT Id FROM Proforma__c LIMIT 1].Id,
                                                    Proveedor__c = provider.Id);
        insert p;
        
        AttachmentsProcessor a = new AttachmentsProcessor();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = 'Booking Confirmation for PE20999';
        email.plainTextBody = 'Nothing fancy however there is something with PE20512. Ah and about PE201000 congrats on fulfilling more than 999 orders!';
        email.fromAddress = 'bob@superbooking.com';
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('Attached Booking Confirmation');
        attachment.fileName = 'bookingConfirmation.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        //Start the EmailParser
        DOSuppliersHandler dsh = new DOSuppliersHandler();
        dsh.handleInboundEmail(email, env);
        test.stopTest();
    }

    @isTest static void testParsingRightFormat() {
        Account provider;
        // Initialize test data
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        
        provider = tu.createFabrica();
        
        test.startTest();
        PedidoDeCompra__c p = new PedidoDeCompra__c(Name = 'PE20999',
                                                    Proforma__c = [SELECT Id FROM Proforma__c LIMIT 1].Id,
                                                    Proveedor__c = provider.Id);
        insert p;
        
        AttachmentsProcessor a = new AttachmentsProcessor();

        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = 'Booking Confirmation for PE20999';
        email.plainTextBody = 'Now this can be processed can\'t it\n'
                                + 'HBL: 11111111\n' +
                                + 'MBL: 55555555\n' +
                                + 'CARRIER: FAST SHIPPER  \n' +
                                + 'VESSEL/VOYAGE: HERCULES\t\n' +
                                + 'ETD: 2020-04-17\n' +
                                + 'POL: Mexico\n' +
                                + 'POD: Guangdong\n';
        email.fromAddress = 'bob@superbooking.com';
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('Attached Booking Confirmation');
        attachment.fileName = 'bookingConfirmation.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        //Start the EmailParser
        DOSuppliersHandler dsh = new DOSuppliersHandler();
        dsh.handleInboundEmail(email, env);
        test.stopTest();
    }
    
    
}