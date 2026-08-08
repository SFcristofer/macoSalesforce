/**
*   Before Insert Validates there is no Document linked to the same (Proforma or Pedido) with the Same Type and for the same 
*   Process
*   @author lcosta@infolastic.com
*   @version 1.0
*/
public class DocumentoDOTriggerHelper{
    public static final String ALREADY_UPL_ERR = 'Ya se ha subido {0} para {1}. Modifique el doc existente de ser necesario';
    private set<Id> proformaIds;
    private set<Id> pedidoIds;
    private list<Documento__c> docs;
    public DocumentoDOTriggerHelper(list<Documento__c> newDocs){
        docs = newDocs;
        proformaIds = new set<Id>();
        pedidoIds = new set<Id>();
        for(Documento__c d : newDocs){
            if(d.PedidoDeCompra__c != null){
                pedidoIds.add(d.PedidoDeCompra__c);
            }else if(d.Proforma__c != null){
                proformaIds.add(d.Proforma__c);
            }
        }
    }

    public void execute(){
        Map<String, Documento__c> procTipoWhatIdToDoc = new Map<String, Documento__c>();
        for(Documento__c d : [SELECT Id,
                                    Proceso__c,
                                    Tipo_de_documento__c,
                                    PedidoDeCompra__c,
                                    Proforma__c
                                    FROM Documento__c
                                    WHERE Proforma__c in :proformaIds
                                    OR PedidoDeCompra__c in :pedidoIds]){
            if(d.PedidoDeCompra__c != null){
                procTipoWhatIdToDoc.put(d.Proceso__c + d.Tipo_de_documento__c + d.PedidoDeCompra__c, d);
            }else if(d.Proforma__c != null){
                procTipoWhatIdToDoc.put(d.Proceso__c + d.Tipo_de_documento__c + d.Proforma__c, d);
            }
        }
        for(Documento__c d : docs) {
            if(!d.Tipo_de_documento__c.equals('Informe Carga de Contenedor') || !d.Tipo_de_documento__c.equals('Packing List') || !d.Tipo_de_documento__c.equals('Factura')) {
                if(d.PedidoDeCompra__c != null && procTipoWhatIdToDoc.containsKey(d.Proceso__c + d.Tipo_de_documento__c + d.PedidoDeCompra__c)){
                    d.addError(ALREADY_UPL_ERR.replace('{0}', d.Tipo_de_documento__c).replace('{1}', 'el pedido'));
                } else if(d.Proforma__c != null && procTipoWhatIdToDoc.containsKey(d.Proceso__c + d.Tipo_de_documento__c + d.Proforma__c)){
                    d.addError(ALREADY_UPL_ERR.replace('{0}', d.Tipo_de_documento__c).replace('{1}', 'la proforma'));
                }
            }
        }
    }
}