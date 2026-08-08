/**
 * Esta clase se encarga de enviar un correo electronico a un agente
 */
public class AgentMail {
    private static final String PROCESS_NAME = 'AgentMail';

    /**
     * Constructor
     */
    public AgentMail() {
    }

    /**
     * Metodo que recibe los identificadores de los pedidos y que se les generara
     * una solicitud de bookin y se enviara al agente asociado al pedido.
     * Este metodo se invoca desde el flujo Pedido_correo_booking
     */
    @InvocableMethod
    public static void getDataOrder(List<PedidoDeCompra__c> idOrders) {
        String email;
        String idOrder;
        for (PedidoDeCompra__c order : idOrders) {
            idOrder = order.id;
            System.debug('Metodo invoc [' + order.id + ']');
            System.debug('Metodo invoc [' + order.Cuenta_Agente_DO__c + ']');
            email = getEmailAgent(order.Cuenta_Agente_DO__c);
            System.debug('Metodo invoc [' + email + ']');
            buildSendMessage(idOrder, order.Numero_de_Orden__c ,email);
        }
    }

    /**
     * Metodo que construye el correo electronico y lo envia
     * @param idOrder. Identificador del pedido
     * @param deliveryMail Correo del destinatario
     */
     //@Future(callout=true) 
    public static void buildSendMessage(String idOrder, String numeroOrden, String deliveryMail) {
      Blob blobPDF;
      //Pagina que se envia en forma de archivo(pdf) adjunto
      PageReference vfPdf =  Page.BookingAgente;
      vfPdf.getParameters().put('id',idOrder);

      
      if(Test.isRunningTest()) {
          blobPDF = Blob.valueOf('Unit.Test');
      } else {
          blobPDF = vfPdf.getContentAsPDF();
      }
      
      System.debug('blobPDF [' + blobPDF + ']');
      Messaging.EmailFileAttachment fileAtt = new Messaging.EmailFileAttachment();
      fileAtt.setContentType('application/pdf');
      fileAtt.setFileName('booking.pdf');
      fileAtt.setInline(false);
      fileAtt.setBody(blobPDF);

    
      Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
      message.toAddresses = new String[] { deliveryMail };
      message.subject = 'Booking Request: ' + numeroOrden;
      message.plainTextBody = 'Once the booking is confirmed, please, complete the information below (only enter the values after the colons): \n HBL: \n MBL: \n POL: \n POD: \n CARRIER: \n VESSEL/VOYAGE: \n ETD: \n';
      Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
      
      message.setFileAttachments(new Messaging.EmailFileAttachment[] {fileAtt});
              
      Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
      System.debug('mail sent res [' + results + ']');
    }
    
    /**
     * Obtenemos el correo electronico del agente al cual se le enviara la solicitud de booking
     * @param idAgente El identificador del agente al cual se le enviara la solicitud de booking
     */
    public static String getEmailAgent(String idAgente) {
        Account cuenta;
        String result;
        List<Test_Envio_Correo__mdt> mdtEmails;
        Test_Envio_Correo__mdt testSendMail;
        Boolean isTestMode = false;

        mdtEmails = [SELECT Masterlabel, 
                            Proceso__c, 
                            Test_Mode__c, 
                            Test_email__c
                       FROM Test_Envio_Correo__mdt
                      WHERE Proceso__c =: PROCESS_NAME];

        if(mdtEmails != null && !mdtEmails.isEmpty()) {
            if(mdtEmails.size() > 1) {
                throw new DoBrandsException('The ' + PROCESS_NAME + ' process is defined more than once in metadata settings');
            } else {
                testSendMail = mdtEmails.get(0);
                isTestMode = testSendMail.Test_Mode__c;
            }
        }

        if(!isTestMode) {
            try {
                cuenta = [SELECT Id, website, EmailComercial__c FROM Account WHERE Id = :idAgente];
                if(cuenta != null) {
                    result = cuenta.EmailComercial__c;
                }
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
            }
        } else {
            result = testSendMail.Test_email__c;
        }

        if(result == null) {
            throw new DoBrandsException('The field EmailComercial__c in Account or Test_email__c in Test_Envio_Correo__mdt, can not be null');
        }
        return result;
    }

}