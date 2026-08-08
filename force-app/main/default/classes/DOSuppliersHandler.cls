global class DOSuppliersHandler implements Messaging.InboundEmailHandler{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, 
                                                            Messaging.Inboundenvelope envelope) {
  
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        try{
            SupplierEmailParser sep = new SupplierEmailParser(email);
            sep.parse();
            result.success = true;
            result.message = (email.subject + ' matched');
        }catch (Exception e) {
            result.success = false;
            result.message = 'Oops, I failed. Error : '+e.getMessage();
            system.debug(e.getTypeName() + ' >> ' + e.getMessage() + ' >> ' + e.getStackTraceString());
        }
        return result;
    }    
}