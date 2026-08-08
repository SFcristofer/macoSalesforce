/**
*   @pre Only Tier 2 (ProductoDeFabrica) or Tier 3 (Packaging) can be included as OpportunityLineItems
*   Generates as many EstudioProforma records as Providers (represented by OpportunityLineItem.Product2.Fabrica)
*   we have in the target Opportunity. 
**/

public class CreateSyncEstudioOportunidad {
    private final Opportunity oppty;
    private static final String NO_COMMITMENT = 'Debe indicar la fecha de compromiso antes de '
                                            + 'enviar la Oportunidad a Compras para su estudio';

    private static final String SUCCESS = 'Se ha inciado con éxito el estudio de oportunidad ';
    
    private static final String MARCA_NO_SELECCIONADA = 'No se ha elegido la marca para los productos';
    private static final String CATALOGO_COMENTARIOS = 'No se puede enviar porque tiene ítems con comentarios sin atender';
    private static final String CODIGO_PAIS_MISSING = 'Falta el código de país en la cuenta principal';    
    private static final String RAZON_SOCIAL_MISSING = 'Falta la razón social en la cuenta principal';
    private static final String ID_FISCAL_MISSING = 'Falta el número de identificación en la cuenta principal';
    private static final String SOCIEDAD_MISSING = 'Falta la sociedad en la cuenta principal';
    private static final String PLAZO_PAGO_MISSING = 'Flata el plazo de pago en la cuenta principal';
    private static final String FORMA_PAGO_MISSING = 'Falta la forma de pago en la cuenta principal';
    private static final String CREDITO_MISSING = 'Falta el crédito autorizado en la cuenta principal';
    private static final String PUERTO_MISSING = 'Falta el puerto en la cuenta contacto';
    private static final String PAIS_PUERTO_MISSING = 'Falta el país del puerto en la cuenta contacto';

    public boolean error {get;set;}
    public List<OpportunityLineItem> oliComments {set; get;}
    public Boolean renderTable {set; get;}    

    public CreateSyncEstudioOportunidad(ApexPages.StandardController stdController) {
        this.oppty = [SELECT Id,
                             AccountId,
                             Account.Name,
                             Account.ParentId,
                             Name,
                             StageName,
                             CurrencyISOCode,                             
                             Fecha_de_Compromiso__c,
                             Is_Brand_Selected__c,
                             (SELECT Id,
                                     Product2Id,
                                     Quantity,
                                     UnitPrice,
                                     Name,
                                     ComentariosCatalogo__c,
                                     Comentario_atendido__c,
                                     CostoProducto__c,
                                     Product2.Name,
                                     Product2.Fabrica__c,
                                     Product2.CostoTotal2__c,
                                     Product2.ProductoBase__c,
                                     Product2.PrecioDeFabrica__c,
                                     Product2.ProductoDeFabrica__r.PrecioDeFabrica__c,
                                     Product2.ProductoDeFabrica__r.Fabrica__c,
                                     Product2.ProductoBase__r.Descripcion_Larga__c,
                                     Product2.ProductoBase__r.Imagen1__c,
                                     Product2.CodigoDeProductoBase__c,
                                     EstudioOportunidad__c
                                FROM OpportunityLineItems)
                                FROM Opportunity 
                               WHERE Id = :stdController.getId()];
                            
        oliComments = new List<OpportunityLineItem>();
        renderTable = false;
        error = false;
    }

    public PageReference execute() {

        Boolean isThereComments = false;
        map<Id, list<OpportunityLineItem>> idFabricaOLIs = new map<Id, list<OpportunityLineItem>>();
        map<Id, Id> idFabricaEstudioPro = new map<Id, Id>();
        map<Id, Id> idFabricaNombre = new map<Id, String>();
        
        renderTable = false;
                
        if(oppty.Fecha_de_Compromiso__c == null){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, NO_COMMITMENT));
            error = true;
        }
        
        if(oppty.Is_Brand_Selected__c == null || oppty.Is_Brand_Selected__c == false) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MARCA_NO_SELECCIONADA));
            error = true;
        }

        for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
            if(!oli.Comentario_atendido__c) {
                oliComments.add(oli);
                isThereComments = true;
                renderTable = true;
            }
            Id provId = oli.Product2.ProductoDeFabrica__r == null ? oli.Product2.Fabrica__c
                                : oli.Product2.ProductoDeFabrica__r.Fabrica__c;
            if(!idFabricaOLIs.containsKey(provId)){
                idFabricaOLIs.put(provId, new list<OpportunityLineItem>{oli});
            }else{
                idFabricaOLIs.get(provId).add(oli);
            }
            if(oli.EstudioOportunidad__c != null){
                idFabricaEstudioPro.put(provId, oli.EstudioOportunidad__c);
            }
        }
        
        if(isThereComments) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, CATALOGO_COMENTARIOS));
            error = true;
        }
        
        Account cliContacto = DOBrandsDAO.getAccount(oppty.AccountId);
        if(!cliContacto.parent.Alta_Libra__c) {
            if(cliContacto.parent.Codigo_pais2__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, CODIGO_PAIS_MISSING));
                error = true;
            }
            if(cliContacto.parent.RazonSocial__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, RAZON_SOCIAL_MISSING));
                error = true;
            }
            if(cliContacto.parent.NroIdFiscal__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ID_FISCAL_MISSING));
                error = true;
            }
            if(cliContacto.parent.Sociedad__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, SOCIEDAD_MISSING));
                error = true;
            }
            if(cliContacto.parent.PlazoPago__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, PLAZO_PAGO_MISSING));
                error = true;
            }
            if(cliContacto.parent.FormaPago__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, FORMA_PAGO_MISSING));
                error = true;
            }
            if(cliContacto.Parent.Credito_autorizado__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, CREDITO_MISSING));
                error = true;
            }
            if(cliContacto.Puerto__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, PUERTO_MISSING));
                error = true;
            }
            if(cliContacto.PaisDelPuerto__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, PAIS_PUERTO_MISSING));
                error = true;
            }
            if(error) {
                return null;
            } else if(!cliContacto.parent.Registrar_Libra__c) {
                cliContacto.parent.Registrar_Libra__c = true;
                update cliContacto.parent;
            }
        }


        map<Id, Account> fabricas = new  map<Id, Account>([SELECT Id,
                                            Name
                                            FROM Account
                                            WHERE Id in :idFabricaOLIs.keySet()]);
        
        list<EstudioOportunidad__c> newEstudiosPro = new list<EstudioOportunidad__c>();
            
        for(Id provId : idFabricaOLIs.keySet()){
            if(!idFabricaEstudioPro.containsKey(provId)){
                EstudioOportunidad__c newEstudio = new EstudioOportunidad__c(Oportunidad__c = oppty.Id,
                                                                             Fabrica__c = provId,
                                                                             CurrencyISOCode = oppty.CurrencyISOCode);
                newEstudiosPro.add(newEstudio);
            }
        }

        insert newEstudiosPro;
        list<OpportunityLineItem> assignEPToOlis = new list<OpportunityLineItem>();
        for(EstudioOportunidad__c ep : newEstudiosPro){
                for (OpportunityLineItem oli : idFabricaOLIs.get(ep.Fabrica__c)){
                    oli.EstudioOportunidad__c = ep.Id;
                }
                assignEPToOlis.addAll(idFabricaOLIs.get(ep.Fabrica__c));
        }       
        update assignEPToOlis;
        
        Task task = createTask(oppty);
        insert task;
        
        System.debug('estado[' + oppty.StageName + ']');
        if(oppty.StageName.equals('Toma de Contacto'))
        {
           oppty.StageName = 'Analizando Propuesta';
        }
        
        update oppty;

        return goToOppty();
    }


    public PageReference goToOppty() {
        //return new PageReference('/' + oppty.id);
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, SUCCESS));
        error = true;
        return null;        
    }

    
    private Task createtask(Opportunity opp)
    {
        String userId = UserInfo.getUserId();

        Task task = new Task();
        task.Subject = 'Enviado para estudio';
        task.Status = 'Completada';
        task.OwnerId = userId;
        task.Priority = 'Normal';
        task.WhatId = opp.Id;
        task.ActivityDate = System.today();
        
        return task;
    }
    
}