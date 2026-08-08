public class OpportunityTriggerHelper {
    public static final String INS = 'ins';
    public static final String UPD = 'upd';
    public static final String B4UPD = 'b4upd';
    public static final String AUPD = 'aupd';
    private static final String CERRADA_GANADA = 'Cerrada/Ganada';
    private String oper;
    private Map<Id, Opportunity> oldOppMap;
    private Map<Id, Opportunity> newOppMap;    

    public OpportunityTriggerHelper(String operp, Map<Id, Opportunity> oldOps, Map<Id, Opportunity> newOps) {
        this.oper = operp;
        oldOppMap = oldOps;
        newOppMap = newOps;
    }

    public void execute() {
        Map<Id, Proforma__c> proformas;
        List<String> idsProforma;
        List<PedidoDeCompra__c> pedidos;
        List<String> idsPedidos;
        List<PedidoLineItem__c> pedidoLineItems;
        //Map<String, Decimal> productoCantidad;
        //Map<String, Decimal> productoCosto;
        
        Map<String, Decimal> mapProfLICantidad;
        Map<String, Decimal> mapProfLIPrecio;        
        List<String> prodIds;
        
        List<OpportunityLineItem> oppLineItems;
        List<OpportunityLineItem> oppLineItemsOppClone;
        SplitOpportunityController splitOppCtrlr;
        Map<String, List<PedidoLineItem__c>> productoPedidosLineItems;

        Opportunity oppBfr;
        Opportunity opp; 
        
        List<Proforma__c> proformasOportunidad;
        Boolean isValid = true;
        Boolean emptyProformas = false;
        Decimal oliCantidad;
        Decimal profLICantidad;
        Decimal profLIPrecio;        
        
        prodIds = new List<String>();

        if(this.oper == B4UPD) {
            for(Id idOp : newOppMap.keySet()) {
           
                oppBfr = newOppMap.get(idOp);
                
                if(oppBfr.StageName.equals(CERRADA_GANADA) && !oldOppMap.get(idOp).StageName.equals(CERRADA_GANADA)) {
                
                    oppBfr.CloseDate = Date.today();

                    if(!oppBfr.Is_Split_Flag__c) {

                        splitOppCtrlr = new SplitOpportunityController(idOp);

                        //get proformas in order to get orders (pedidos)
                        proformas = splitOppCtrlr.getProformasByIdOp(idOp);

                        //get order line items (pedido line items)
                        /*pedidoLineItems = splitOppCtrlr.getPedidoLineItems(proformas.keyset());
                 
                        //build a map  productId , quantity 
                        productoCantidad = splitOppCtrlr.buildMapProductocantidad(pedidoLineItems);
                 
                        //build map product , order line item
                        List<PedidoLineItem__c> pliList;
                        productoPedidosLineItems = splitOppCtrlr.buildMapProductoPedidoLineItems(pedidoLineItems);
                 
                        productoCosto = splitOppCtrlr.buildMapProductoCosto(productoPedidosLineItems, 'costo');

                        oppLineItems = splitOppCtrlr.getOpportunityLineItems(idOp);
                 
                        oppLineItemsOppClone = splitOppCtrlr.getOppLineItemsToClone(oppLineItems, productoCantidad, productoCosto, productoCosto);

                        if(oppLineItemsOppClone.size() > 0) {
                            oppBfr.StageName.addError('use boton <cerrar parcialmente>');
                        }*/
                    
                        System.debug('OpportunityTriggerHelper - execute oper[' + oper + ']');                    
                    
                        proformasOportunidad = getProformas(oppBfr.Id);
                        
                        

                        for(Proforma__c pr : proformasOportunidad) {
                            if(!pr.ConfirmacionCliente__c) {
                                isValid = false;
                            }
                        }
                        
                        if(proformasOportunidad.size() == 0) {
                            emptyProformas = true;
                            isValid = false;
                        }
                        
                        
                        if(!isValid && !emptyProformas) {
                            oppBfr.StageName.addError('use boton <cerrar parcialmente>');
                        }

                        if(!isValid && emptyProformas) {
                            oppBfr.StageName.addError('No hay proformas para esta oportunidad');
                        }

                    }
                }
            }
        }
        
        if(this.oper == AUPD) {
        
            for(Id idOp : newOppMap.keySet()) {
           
                oppBfr = newOppMap.get(idOp);
               
                if(oppBfr.StageName.equals(CERRADA_GANADA)) {
                    System.debug('OpportunityTriggerHelper - execute - After update');
                    
                    mapProfLICantidad = getMapProformaLineItem(oppBfr.Id);
                    mapProfLIPrecio = getMapProformaLineItemPrecio(oppBfr.Id);

                    System.debug('profLineItemSize size[' + mapProfLICantidad.keySet().size() + ']');
                            
                    for(String prodIdkey : mapProfLICantidad.keySet()) {
                        prodIds.add(prodIdkey);
                    }
                    
                    oppLineItems = getListOppLineItem(oppBfr.Id, prodIds);
                            
                    System.debug('oppLineItems size[' + oppLineItems.size() + ']');
                            
                    for(OpportunityLineItem oli : oppLineItems) {
                        profLICantidad = mapProfLICantidad.get(oli.Product2Id);
                        profLIPrecio = mapProfLIPrecio.get(oli.Product2Id);
                        
                        System.debug('opId[' + oli.OpportunityId + '] oliId[' + oli.Id + '] prodId[' + oli.Product2Id + '] oldQty [' + oli.Quantity + '] newQty[' + profLICantidad + '] [' + profLIPrecio + ']');
                        oli.Quantity = profLICantidad;
                        oli.UnitPrice = profLIPrecio;
                    }
                            
                    update oppLineItems;
                }
                
            }
        }
    }
    
    
    private List<OpportunityLineItem> getListOppLineItem(String idOpp, List<String> listProds) {
        List<OpportunityLineItem> listOLI;
        
        listOLI = [SELECT Id, 
                          Name,
                          OpportunityId,
                          Product2Id,
                          Quantity 
                     FROM OpportunityLineItem 
                    WHERE OpportunityId = :idOpp
                    AND Product2Id IN :listProds];

        return listOLI;
    }
    
    
    private Map<String, Decimal> getMapProformaLineItem(String idOpp) {
        Map<String, Decimal> profLICantidad = new Map<String, Decimal>();    
        AggregateResult[] results = null; 
        Decimal cantidad;
        Decimal cantidadMap;        
        String idProd;      
        
        results = [SELECT Producto__c Idprod, 
                          SUM(Unidades__c) SumUnidades
                     FROM ProformaLineItem__c 
                    WHERE Proforma__r.Oportunidad__c = :idOpp
                 GROUP BY Producto__c];

        for(AggregateResult ar : results) {
            idProd = (String)ar.get('Idprod');
            cantidad = (Decimal)ar.get('SumUnidades');
            profLICantidad.put(idProd, cantidad);
        }

        return profLICantidad;
    }



    private Map<String, Decimal> getMapProformaLineItemPrecio(String idOpp) {
        Map<String, Decimal> profLIPrecio = new Map<String, Decimal>();    
        List<ProformaLineItem__c> results; 
        
        results = [SELECT Producto__c, 
                          Proforma__c,
                          PrecioUnitario__c
                     FROM ProformaLineItem__c 
                    WHERE Proforma__r.Oportunidad__c = :idOpp
                 ORDER BY Producto__c];

        for(ProformaLineItem__c pli : results) {
            profLIPrecio.put(pli.Producto__c, pli.PrecioUnitario__c);
            System.debug('proforma - prodid [' + pli.Producto__c + '] [' + pli.PrecioUnitario__c + ']');
        }

        return profLIPrecio;
    }

    
    
    private List<Proforma__c> getProformas(String idOpp) {
        List<Proforma__c> proformas;
        
        proformas = [SELECT Id, 
                            Name, 
                            Oportunidad__c, 
                            ConfirmacionCliente__c 
                       FROM Proforma__c 
                      WHERE Oportunidad__c = :idOpp];
        
        return proformas;
    }
    
    
    
    
}