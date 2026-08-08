@isTest
private class TestAttachmentsProcessor 
{
	
	@isTest static void testAttachmentProcessor() 
	{
       PedidoDeCompra__c pedido;
       TestUtil tu = new TestUtil();
       tu.initOpportunityTest();
       test.startTest();
       tu.initPedidoAgente();
	   pedido = tu.getPedidoCompra(); 

       Messaging.InboundEmail inEmail = new Messaging.InboundEmail() ;
    
       inEmail.subject = 'Test Subject';
       inEmail.fromAddress = 'mail@mail.com';

       Messaging.InboundEmail.BinaryAttachment binAttachment = new Messaging.InboundEmail.BinaryAttachment();
       binAttachment.body = blob.valueOf('my attachment text');
       binAttachment.fileName = 'testfile.txt';
       binAttachment.mimeTypeSubType = 'text/plain';
       inEmail.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { binAttachment };
       
       AttachmentsProcessor.processDocsDO(pedido.Id, inEmail);
       test.stopTest();
	}
	
	
}