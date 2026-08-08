/**
*   Controller for "Aplicar cambios" action on PedidoDeCompra__c
*   @author lcosta@infolastic.com
*   @version 1.0
*/
public with sharing class ApplyChangesCloseSimulation {
	private PedidoDeCompra__c simulacion;
    private Id idProforma;

    private static final String SIM = 'Simulacion';
    private static final String ERR_TYPE = 'Solo se pueden aplicar cambios a la Proforma en Simulaciones ya que la acción implica la eliminación del pedido al que se aplica.';

    public ApplyChangesCloseSimulation(ApexPages.StandardController std) {
        //VALIDAR PRIMERO QUE ES SIMULACION ANTES DE ELIMINAR
        simulacion = [SELECT Id,
                            Proforma__c,
                            Proforma__r.CurrencyISOCode,
                            RecordType.DeveloperName,
                            (SELECT Id,
                                ProformaLineItem__c,
                                CostoOrigen__c,
                                CostoExtraUnitario__c,
                                NumeroDeCajas__c,
                                PrecioDeVenta__c
                                FROM PedidoLineItems__r)
                            FROM PedidoDeCompra__c
                            WHERE Id = :std.getId()];
        
        idProforma = simulacion.Proforma__c;
    }

    /**
    *   Copies all changes made to PedidoLineItems (CostoExtraUnitario__c, CostoOrigen__c, 
    *   NumeroDeCajas__c, PrecioDeVenta__c) on the current simulation to the linked ProformaLineItems
    *   deletes the Simulation and navigates to the Proforma__c
    */
    public PageReference execute(){
        if(simulacion.RecordType.DeveloperName == SIM){
            Map<Id, PedidoLineItem__c> profLItoPLI = new Map<Id, PedidoLineItem__c>();
            for(PedidoLineItem__c pli : simulacion.PedidoLineItems__r){
                profLItoPLI.put(pli.ProformaLineItem__c, pli);
            }
            //TO-DO handle exchange rate
            Decimal rate = CurrencyUtil.getRate(simulacion.Proforma__r.CurrencyISOCode);
            list<ProformaLineItem__c> itemsToUpdate = [SELECT Id
                                                        FROM ProformaLineItem__c
                                                        WHERE Proforma__c = :simulacion.Proforma__c];
            
            for(ProformaLineItem__c profLI : itemsToUpdate){
                PedidoLineItem__c pli = profLItoPLI.get(profLI.Id);
                profLI.CostoExtraUnitario__c = simulacion.Proforma__r.CurrencyISOCode == CurrencyUtil.USD ? pli.CostoExtraUnitario__c : (pli.CostoExtraUnitario__c * rate).setScale(2, RoundingMode.HALF_UP);
                profLI.CostoFabrica__c = simulacion.Proforma__r.CurrencyISOCode == CurrencyUtil.USD ? pli.CostoOrigen__c : (pli.CostoOrigen__c * rate).setScale(2, RoundingMode.HALF_UP);
                profLI.NumeroDeCajas__c = pli.NumeroDeCajas__c;
                profLI.PrecioUnitario__c = simulacion.Proforma__r.CurrencyISOCode == CurrencyUtil.USD ? pli.PrecioDeVenta__c : (pli.PrecioDeVenta__c * rate).setScale(2, RoundingMode.HALF_UP);
            }
            update itemsToUpdate;

            //delete simulacion; Client wants to keep the simulation to apply parameters to the real Pedido when created

            return new PageReference('/' + idProforma);
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERR_TYPE));
        return null;
    }
}