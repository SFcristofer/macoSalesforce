public class CreatesOrderTokenController {
    public PedidoDeCompra__c order {set; get;}
    public String idOrder {set; get;}
    public String orderName {set; get;}
    private static String EMPTY_EMAIL = 'El proveedor debe tener el correo electrónico comercial';
    private static String MSG_SUCCESS = 'Se ha generado el token y se ha enviado por correo electrónico';
    private static String TOKEN_ALREADY_EXIST = 'Ya hay un token generado para este proveedor, se generará un token nuevo y se enviara por correo';
    public Boolean generateTokenEnabled {set; get;}
    public Boolean isValidEmail {set; get;}

    public CreatesOrderTokenController(ApexPages.StandardController stdController) {
        String token;
        Portal_DO_Brands__c portalCfg;

        RecordType rt;
        idOrder = ApexPages.currentPage().getParameters().get('id');
        rt = DOBrandsDAO.getRecordType('Principal', 'PedidoDeCompra__c');
        generateTokenEnabled = True;
        isValidEmail = True;
        System.debug('ID Order [' + idOrder + ']');

        order = DOBrandsDAO.getOrder(idOrder, rt);

        System.debug('Provider email[' + order.Email_Fabrica__c + ']');

        if(order.Email_Fabrica__c == null) {
            generateTokenEnabled = False;
            isValidEmail = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EMPTY_EMAIL));
        }

    }


    public PageReference generarTokenEnviar() {
        String token;
        Portal_DO_Brands__c portalCfg;

        if(!isValidEmail) {
            return null;
        }

        //generates token
        token = Util.generateToken();
        //update account
        order.Portal_Token__c = token;
        update order;

        generateTokenEnabled = False;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, MSG_SUCCESS));
        return null;
    }

}