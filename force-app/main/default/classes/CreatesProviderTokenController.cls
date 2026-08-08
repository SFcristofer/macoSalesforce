public class CreatesProviderTokenController {
    public Account provider {set; get;}
    public String idProvider {set; get;}
    public String comercialEmail {set; get;}
    public String providerName {set; get;}
    private static String EMPTY_EMAIL = 'El proveedor debe tener el correo electrónico comercial';
    private static String MSG_SUCCESS = 'Se ha generado el token y se ha enviado por correo electrónico';
    private static String TOKEN_ALREADY_EXIST = 'Ya hay un token generado para este proveedor, se generará un token nuevo y se enviara por correo';
    public Boolean generateTokenEnabled {set; get;}
    public Boolean isValidEmail {set; get;}

    public CreatesProviderTokenController(ApexPages.StandardController stdController) {
        String token;
        Portal_DO_Brands__c portalCfg;

        RecordType rt;
        idProvider = ApexPages.currentPage().getParameters().get('id');
        rt = DOBrandsDAO.getRecordType('Proveedor', 'Account');
        generateTokenEnabled = True;
        isValidEmail = True;
        System.debug('ID provider [' + idProvider + ']');

        provider = DOBrandsDAO.getProvider(idProvider, rt);

        System.debug('Provider email[' + provider.EmailComercial__c + ']');        

        if(provider.EmailComercial__c == null) {
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
        provider.Portal_Token__c = token;
        update provider;

        generateTokenEnabled = False;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, MSG_SUCCESS));
        return null;
    }

}