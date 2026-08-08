/**
*   Controller for "Simular Pedido" action on Proforma
*   @author lcosta@infolastic.com
*   @version 1.0
*/
public class GenDraftOrder {
    private Id proforma;

    private static final String APPROVER_PROFILE = 'Aprobador';
    private static final String SIM = 'Simulacion';
    private static final String SIM_APPROVER = 'Simulacion_Aprobador';
    private Escandallo__c escandalloUnico;    

    public GenDraftOrder(ApexPages.StandardController std) {
        proforma = std.getId();
        escandalloUnico = getEscandallo();
    }

    /**
    *   If there is a PedidoDeCompra__c of type "Simulacion" linked to the Proforma__c navigates to it
    *   If there is none, it creates one mocking the Proforma__c and navigates to it.
    */
    public PageReference generateDraft(){
        
        PedidoDeCompra__c draft = getPreexistingDraft();

        Profile approver = [SELECT Id
                                FROM Profile
                                WHERE Name = :APPROVER_PROFILE];
        System.debug('approver [' + approver.Id + ']');

        if (draft == null){
            Proforma__c p = [SELECT Id,
                                    Name,
                                    TipoDeContenedor__c,
                                    ETD__c,
                                    Cuenta__r.PlazoPago__c,
                                    Cuenta__r.Parent.PlazoPago__c,
                                    EstudioOportunidad__r.Fabrica__c,
                                    EstudioOportunidad__r.Fabrica__r.PorcentajeDeposito__c,
                                    EstudioOportunidad__r.Fabrica__r.TiempoServicioMedio__c,
                                    EstudioOportunidad__r.Fabrica__r.PlazoPago__c,
                                    CurrencyISOCode,
                                    (SELECT Id,
                                        NumeroDeCajas__c,
                                        Producto__c,
                                        UnidadesPorMasterBox__c,
                                        CBMMasterBox__c,
                                        PrecioUnitario__c,
                                        CostoFabrica__c,
                                        Aportaciones_2__c,
                                        Convenio_2__c,
                                        Porcentaje_Item__c
                                        FROM ProformaLineItems__r)
                                    FROM Proforma__c
                                    WHERE Id =:proforma];
            System.debug('id proforma [' + proforma + ']');
            Id idsimRT = Schema.sObjectType.PedidoDeCompra__c.getRecordTypeInfosByDeveloperName().get(SIM).getRecordTypeId();
            Id idsimAppRT = Schema.sObjectType.PedidoDeCompra__c.getRecordTypeInfosByDeveloperName().get(SIM_APPROVER).getRecordTypeId();
            System.debug('id proforma [' + p.Id + ']');
            System.debug('id fab [' + p.EstudioOportunidad__r.Fabrica__c + ']');
            System.debug('id fab [' + p.Cuenta__c + ']');
            draft = new PedidoDeCompra__c(Proforma__c = p.Id,
                                            ETD__c = p.ETD__c,
                                            Proveedor__c = p.EstudioOportunidad__r.Fabrica__c,
                                            PlazoPago__c = p.Cuenta__r.PlazoPago__c == null? Integer.valueOf(p.Cuenta__r.Parent.PlazoPago__c) 
                                                            :Integer.valueOf(p.Cuenta__r.PlazoPago__c),
                                            PlazoPagoFab__c = Integer.valueOf(p.EstudioOportunidad__r.Fabrica__r.PlazoPago__c),
                                            PlazoFabricacion__c = Integer.valueOf(p.EstudioOportunidad__r.Fabrica__r.TiempoServicioMedio__c),
                                            PorcentajeDepositoAFabrica__c = Integer.valueOf(p.EstudioOportunidad__r.Fabrica__r.PorcentajeDeposito__c),
                                            FechaConfirmacionCliente__c = Date.today(),
                                            TipoDeInteresFinanciacionClient__c = escandalloUnico.TipoDeInteresFinanciacionClient__c,
                                            TipoDeInteresDepositoFabrica__c = escandalloUnico.TipoDeInteresDepositoFabrica__c,
                                            InspeccionXEntrega__c = escandalloUnico.InspeccionXEntrega__c,
                                            CambioDocumentsXHQ__c = escandalloUnico.CambioDocumentsXHQ__c);
        System.debug('userinfo [' + UserInfo.getProfileId() + ']');            
            if(UserInfo.getProfileId() == approver.Id){
                draft.Name = 'SIMULACION ' + UserInfo.getFirstName().toUpperCase() + '[' + p.Name + ']';
                draft.RecordTypeId = idsimAppRT;
            }else{
                draft.Name = 'SIMULACION [' + p.Name + ']';
                draft.RecordTypeId = idsimRT;
            }
            insert draft;
            
            list<PedidoLineItem__c> newPedidoLineItems = new list<PedidoLineItem__c>();
            Decimal rate = CurrencyUtil.getRate(p.CurrencyISOCode);
            for(ProformaLineItem__c pli : p.ProformaLineItems__r){
                    newPedidoLineItems.add(new PedidoLineItem__c(ProformaLineItem__c = pli.Id,
                                                                    PedidoDeCompra__c = draft.Id,
                                                                    NumeroDeCajas__c = pli.NumeroDeCajas__c,
                                                                    CostoOrigen__c = p.CurrencyISOCode == CurrencyUtil.USD ? pli.CostoFabrica__c : (pli.CostoFabrica__c / rate).setScale(2, RoundingMode.HALF_UP), //multiply by conversion rate round up to 2 decimals
                                                                    UnidadesPorMasterBox__c = pli.UnidadesPorMasterBox__c,
                                                                    CBMMasterBox__c = pli.CBMMasterBox__c,
                                                                    PrecioDeVenta__c = p.CurrencyISOCode == CurrencyUtil.USD ? pli.PrecioUnitario__c : (pli.PrecioUnitario__c / rate).setScale(2, RoundingMode.HALF_UP), //multiply by conversion rate round up to 2 decimals
                                                                    Producto__c = pli.Producto__c,
                                                                    Aportaciones_2__c = pli.Aportaciones_2__c,
                                                                    Convenio_2__c = pli.Convenio_2__c,
                                                                    Porcentaje_Item__c = pli.Porcentaje_Item__c));
            }
            insert newPedidoLineItems;
        }
        return new PageReference('/lightning/r/PedidoDeCompra__c/' + draft.Id + '/view' );
    }

    private PedidoDeCompra__c getPreexistingDraft(){
        list<PedidoDeCompra__c> listOfDrafts = [SELECT Id
                                                    FROM PedidoDeCompra__c
                                                    WHERE Proforma__c = :proforma
                                                    AND CreatedById = :UserInfo.getUserId()];
        if(listOfDrafts.isEmpty()){
            return null;
        }
        return listOfDrafts[0];
    }

    private Escandallo__c getEscandallo() {
        System.debug('get Escandallo');
        Escandallo__c escandallo;
        escandallo = [SELECT Id, 
                             TipoDeInteresDepositoFabrica__c, 
                             TipoDeInteresFinanciacionClient__c,
                             InspeccionXEntrega__c,
                             CambioDocumentsXHQ__c
                        FROM Escandallo__c 
                       WHERE Name = 'Único'];
        return escandallo; 
    }

}