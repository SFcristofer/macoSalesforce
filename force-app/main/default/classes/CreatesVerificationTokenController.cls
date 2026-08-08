public class CreatesVerificationTokenController {
    public List<Verificacion_Costo_Productos__c> listVcpToUpdate;
    public Account provider {set; get;}
    public String idProvider {set; get;}
    public String idVerificationCosto {set; get;}    
    public String comercialEmail {set; get;}
    public String providerName {set; get;}
    private static String EMPTY_EMAIL = 'El proveedor debe tener el correo electrónico comercial';
    private static String MSG_SUCCESS = 'Se ha generado el token y se ha enviado por correo electrónico';
    private static String TOKEN_ALREADY_EXIST = 'Ya hay un token generado para este proveedor';
    public Boolean generateTokenEnabled {set; get;}
    public Boolean isValidEmail {set; get;}

    public CreatesVerificationTokenController() {
        String token;

        RecordType rt;
        idProvider = ApexPages.currentPage().getParameters().get('id');
        idVerificationCosto = ApexPages.currentPage().getParameters().get('idVc');
        rt = DOBrandsDAO.getRecordType('Proveedor', 'Account');
        generateTokenEnabled = True;
        isValidEmail = True;
        System.debug('ID provider [' + idProvider + ']');

        if(idProvider != null) {
            listVcpToUpdate = getVCP(idProvider, idVerificationCosto);
        }

        provider = DOBrandsDAO.getProvider(idProvider, rt);

        System.debug('Provider email[' + provider.EmailComercial__c + ']');        

        if(provider.EmailComercial__c == null) {
            generateTokenEnabled = False;
            isValidEmail = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, EMPTY_EMAIL));
        }

    }


    private List<Verificacion_Costo_Productos__c> getVCP(String idFactc, String idVerificacionCosto) {
        List<Verificacion_Costo_Productos__c> listVCP;
        //listVCP = [SELECT Id, Name, Estado__c, Fecha_Estado__c, Factory__c FROM Verificacion_Costo_Productos__c WHERE Id = :idVCP];
        listVCP = [SELECT Id, 
                          Name, 
                          Estado__c, 
                          Fecha_Estado__c, 
                          Factory__c 
                     FROM Verificacion_Costo_Productos__c 
                    WHERE Factory__c = :idFactc
                    AND Verificacion_Costo__c = :idVerificacionCosto];

        return listVCP;
    }

    public PageReference generarTokenEnviar() {
        String token;

        if(provider.Portal_Token_Verificacion__c != null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, TOKEN_ALREADY_EXIST));
            return null;
        }

        if(!isValidEmail) {
            return null;
        }

        //generates token
        token = Util.generateToken();
        //update account
        provider.Portal_Token_Verificacion__c = token;
        update provider;

        generateTokenEnabled = False;

        for(Verificacion_Costo_Productos__c vcpu : listVcpToUpdate) {
            vcpu.Estado__c = 'Token Enviado';
            vcpu.Fecha_Estado__c = Date.today();
        }

        update listVcpToUpdate;

        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, MSG_SUCCESS));
        return null;
    }

}