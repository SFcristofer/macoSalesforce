/**
 *  Creates a new Proforma and redirects to its Add Items page
 */
public class CreateProforma {
    public static final String AUTOGEN_KEY = 'Autogenerado';
    public static final String BLOCKED_PROF_RT = 'Bloqueada';

    private static final String NOMBRE_MISSING = 'Se necesita registar el nombre del proveedor';
    private static final String RAZON_SOCIAL_MISSING = 'Se necesita registar la razón social del proveedor';
    private static final String ID_FISCAL_MISSING = 'Se necesita registar el número de identificación del proveedor';
    private static final String CODIGO_PAIS_MISSING = 'Se necesita registar el código del país del proveedor';
    private static final String PLAZO_PAGO_MISSING = 'La cuenta de esta oportunidad debe tener plazo de pago selecionado';
    private static final String TIEMPO_SERVICIO_MEDIDO_MISSING = 'La cuenta de esta oportunidad debe tener tiempo de servicio medido';
    private static final String PORCENTAJE_DEPOSITO_MISSING = 'La cuenta de esta oportunidad debe tener porcentaje de depósito';

    public Boolean error {get;set;}

    private EstudioOportunidad__c study;
    
    public CreateProforma(ApexPages.StandardController std) {
        study = [SELECT Id, 
                        Oportunidad__c,
                        IdCuenta__c,
                        CurrencyISOCode,
                        Fabrica__c,
                        Fabrica__r.Id,
                        Fabrica__r.Name,
                        Fabrica__r.Codigo_pais2__c,
                        Fabrica__r.RazonSocial__c,
                        Fabrica__r.NroIdFiscal__c,
                        Fabrica__r.Codigo_rapido__c,
                        Fabrica__r.PlazoPago__c,
                        Fabrica__r.TiempoServicioMedio__c,
                        Fabrica__r.PorcentajeDeposito__c,
                        Fabrica__r.Registrar_Libra__c
                   FROM EstudioOportunidad__c
                  WHERE Id = :std.getId()];

        error = false;
    }

    public PageReference createProformaAndRedirect() {
        Id blockedRT = Schema.sObjectType.Proforma__c.getRecordTypeInfosByDeveloperName().get(BLOCKED_PROF_RT).getRecordTypeId();

        
        if(study.Fabrica__r.Codigo_rapido__c == null ) {
            if(study.Fabrica__r.Name == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, NOMBRE_MISSING));
                error = true;
            }
            if(study.Fabrica__r.Codigo_pais2__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, CODIGO_PAIS_MISSING));
                error = true;
            }
            if(study.Fabrica__r.RazonSocial__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, RAZON_SOCIAL_MISSING));
                error = true;
            }
            if(study.Fabrica__r.NroIdFiscal__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ID_FISCAL_MISSING));
                error = true;
            }
            if(study.Fabrica__r.PlazoPago__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, PLAZO_PAGO_MISSING));
                error = true;
            }
            if(study.Fabrica__r.TiempoServicioMedio__c == null || study.Fabrica__r.TiempoServicioMedio__c.equals('')) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, TIEMPO_SERVICIO_MEDIDO_MISSING));
                error = true;
            }
            if(study.Fabrica__r.PorcentajeDeposito__c == null || study.Fabrica__r.PorcentajeDeposito__c.equals('')) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, PORCENTAJE_DEPOSITO_MISSING));
                error = true;
            }
            
            if(error) {
                return null;
            }

            study.Fabrica__r.Registrar_Libra__c = true;
            update study.Fabrica__r;
        }

        Proforma__c p = new Proforma__c(Name = AUTOGEN_KEY,
                                        RecordTypeId = blockedRT,
                                        EstudioOportunidad__c = study.Id,
                                        Oportunidad__c = study.Oportunidad__c,
                                        Cuenta__c = study.IdCuenta__c,
                                        CurrencyISOCode = study.CurrencyISOCode);

        insert p;
        return new PageReference('/apex/ContainerAddItems?Id=' + p.Id);
    }

}