public class SplitOpportunityController {
    public String opportunityId;
    public Opportunity originalOpportunity {get;set;}
    public Opportunity clonedOpportunity {get;set;}
    public List<OpportunityLineItem> oppLineItemsCloned {get;set;}
    public List<OpportunityLineItem> oppLineItems {get;set;}
    public List<SplitOpplineItem> splitOppLineItems {get;set;}    
    public List<OpportunityLineItem> oppLineItemsOppClone {get;set;}

    public List<OpportunityLineItem> oppLineItemsFork {get;set;}

    public List<EstudioOportunidad__c> estudiosOpp {get;set;}
    public Map<Id, OppStudyStatus> estudioToStatus {get;set;}
    public Map<Id, Proforma__c> proformas {get;set;}
    
    public Map<Id, List<String>> prodsInProformaNOOrder {get;set;}
    public Map<Id, List<String>> prodsInProformaWOrder {get;set;}

    public static final String PRINCIPAL = 'Principal';

    public SplitOpportunityController(String oppId) {
        opportunityId = oppId;
    }

    public void splitOpportunities() {
        oppLineItemsCloned = new List<OpportunityLineItem>();       
        List<PedidoLineItem__c> pedidoLineItems;
        Map<String, Decimal> productoCantidad;
        Map<String, Decimal> productoCosto;
        Map<String, Decimal> productoPrecio;        
        Map<String, List<PedidoLineItem__c>> productoPedidosLineItems;
        prodsInProformaNOOrder = getProdsInProformas(opportunityId, false);

        prodsInProformaWOrder = getProdsInProformas(opportunityId, true);
        estudiosOpp = getEstudiosOportunidad(opportunityId);
        estudioToStatus = analizeStudies(estudiosOpp);
        
        oppLineItemsOppClone = new List<OpportunityLineItem>();
        OpportunityLineItem oliCloned;
        
        proformas = getProformasByIdOp(opportunityId);
        pedidoLineItems = getPedidoLineItems(proformas.keyset());

        //build a map  productId , quantity 
        productoCantidad = buildMapProductocantidad(pedidoLineItems);
        //build map product , order line item
        productoPedidosLineItems = buildMapProductoPedidoLineItems(pedidoLineItems);
        //build map product cost
        productoCosto = buildMapProductoCosto(productoPedidosLineItems, 'costo');
        productoPrecio = buildMapProductoCosto(productoPedidosLineItems, 'precio');

        System.debug('opid [' + opportunityId + ']');
        oppLineItems = getOpportunityLineItems(opportunityId);
        System.debug('oppLineItems.size 1 [' + oppLineItems.size() + ']');
        for(OpportunityLineItem oli : oppLineItems) {
            if(!prodsInProformaNOOrder.containsKey(oli.Product2Id)) {
                prodsInProformaNOOrder.put(oli.Product2Id, new List<String>());
            }
        }
        
        oppLineItemsFork = getOppLineItemsFork(oppLineItems, productoCantidad, prodsInProformaNOOrder);
        System.debug('oppLineItems.size 1.1 [' + oppLineItems.size() + ']');        
        oppLineItemsOppClone = getOppLineItemsToClone(oppLineItems, productoCantidad, productoCosto, productoPrecio);
        System.debug('oppLineItems.size 2 [' + oppLineItems.size() + ']');
        originalOpportunity = getOpportunity();
        clonedOpportunity = originalOpportunity.clone(false, true);
        clonedOpportunity.Name = nameClonedOpp(originalOpportunity.Name);
        originalOpportunity.StageName = 'Cerrada/Ganada';
        if(originalOpportunity.Seguimiento_de_Reposici_n__c == null) {
            originalOpportunity.Seguimiento_de_Reposici_n__c = 'No';
        }
        for(OpportunityLineItem oliOrig : oppLineItemsOppClone) {
            oliCloned = oliOrig.clone(false, true);
            oppLineItemsCloned.add(oliCloned);
        }

        oppLineItemsCloned.addAll(oppLineItemsFork);
        System.debug('line items cloned size[' + oppLineItemsCloned.size() + ']');

        splitOppLineItems = new List<SplitOppLineItem>();
        List<String> auxProformaOrderNames;
        SplitOppLineItem splitOLI;
        for(OpportunityLineItem olip : oppLineItems) {
            splitOLI = new SplitOppLineItem(olip);
            splitOppLineItems.add(splitOLI);
            auxProformaOrderNames = prodsInProformaWOrder.get(olip.Product2.ProductoBase__c);
            if(auxProformaOrderNames == null) {
                auxProformaOrderNames = prodsInProformaWOrder.get(olip.Product2Id);
                if(auxProformaOrderNames == null) { 
                    auxProformaOrderNames = new List<String>();
                }
            }
            splitOLI.proformaOrderNames = auxProformaOrderNames;
        }
    }


    /**
    *   Gets all the EstudioOportunidad__c with their Proformas__r linked to the Opportunity oppId
     */
    private List<EstudioOportunidad__c> getEstudiosOportunidad(Id oppId) {
       List<EstudioOportunidad__c> estudiosOpp;
       estudiosOpp = [SELECT Id,
                             CreatedById,
                             Cuenta__c,
                             Etapa__c,
                             Fabrica__c,
                             IdCuenta__c,
                             Name,
                             Oportunidad__c,
                            (SELECT Id, 
                                    ConfirmacionCliente__c
                                    FROM Proformas__r)
                        FROM EstudioOportunidad__c
                       WHERE Oportunidad__c = :oppId];
       return estudiosOpp;
    }


    /**
    *   For all EstudioOportunidad__c in std, analizes wether they have orders and/or proformas with no order.
    *   Returns a map with the id of the study and a structure (OppStudyStatus) 
    *   with 2 booleans (hasOrder, hasProformaWNOOrder).
     */
    private Map<Id, OppStudyStatus> analizeStudies(List<EstudioOportunidad__c> std) {
        Map<Id, OppStudyStatus> result = new Map<Id, OppStudyStatus>();
        for(EstudioOportunidad__c e : std) {
            OppStudyStatus oss = new OppStudyStatus();
            for(Proforma__c pr : e.Proformas__r) {
                if(pr.ConfirmacionCliente__c == true) {
                    oss.hasOrder = true;
                } else {
                    oss.hasProformaWNOOrder = true;
                }
            }
            result.put(e.Id, oss);
        }
        return result;
    }


    /**
    *   Gets all the Proformas linked to an Opportunity Product with (or without) orders based on param
    *   (Proforma__r.ConfirmacionCliente__c = withOrders) and maps them based on Product Id.
    */
    private Map<Id, List<String>> getProdsInProformas(Id oppId, boolean withOrders) {
        Map<Id, List<String>> result = new Map<Id, List<String>>();
        for( ProformaLineItem__c pli: [SELECT Id,
                                            Producto__c,
                                            Proforma__r.Name
                                            FROM ProformaLineItem__c
                                            WHERE Proforma__r.Oportunidad__c = :oppId
                                            AND Proforma__r.ConfirmacionCliente__c = :withOrders]) {
            if(!result.containsKey(pli.Producto__c)) {
                result.put(pli.Producto__c, new List<String>{pli.Proforma__r.Name});
            } else {
                result.get(pli.Producto__c).add(pli.Proforma__r.Name);
            }
        }
        return result;
    }


    public Opportunity getOpportunity() {
       Opportunity opp = [SELECT Id,
                                 Antiguedad__c,
                                 Budget_Confirmed__c,
                                 Campana__c,
                                 TotalOpportunityQuantity,
                                 ForecastCategoryName,
                                 ContractId,
                                 CostoDeDescargaEnDestino__c,
                                 CostoDeNacionalizacion__c,
                                 CostoDeSeguroDeEnvio__c,
                                 CostoDeTransporteAlAlmacenDelCliente__c,
                                 Costo_Estimado__c,
                                 CostoFOB__c,
                                 CostoTransporte__c,
                                 CreatedById,
                                 Description,
                                 Discovery_Completed__c,
                                 StageName,
                                 CloseDate,
                                 Fecha_de_Compromiso__c,
                                 Fecha_seguimiento_Reposicion__c,
                                 Id_de_aportacion_comercial__c,
                                 IdVenta__c,
                                 Amount,
                                 Importe_Neto2__c,
                                 Incoterm__c,
                                 ExpectedRevenue,
                                 Pricebook2Id,
                                 Margen__c,
                                 Loss_Reason__c,
                                 Is_Split_Flag__c,
                                 AccountId,
                                 Name,
                                 NumeroDeProductos__c,
                                 CampaignId,
                                 LeadSource,
                                 NextStep,
                                 PlanificacionComercial__c,
                                 PorcentajeAportacionesComerciales__c,
                                 SyncedQuoteId,
                                 IsPrivate,
                                 Probability,
                                 ProductosQueRequierenPackagingNuevo__c,
                                 OwnerId,
                                 RequierePackaging__c,
                                 Responsable_de_compras__c,
                                 ROI_Analysis_Completed__c,
                                 Seguimiento_de_Reposici_n__c,
                                 SumaDeCantidadesDeProductos__c,
                                 Type,
                                 LastModifiedById
                            FROM Opportunity
                           WHERE Id = :opportunityId];
       return opp;
    }

    public Map<Id, Proforma__c> getProformasByIdOp(String idOp) {
        return new Map<Id, Proforma__c>([SELECT Id, 
                                            Name, 
                                            Oportunidad__c,
                                            ConfirmacionCliente__c
                                            FROM Proforma__c
                                            WHERE Oportunidad__c = :idOp]);
    }

    public List<PedidoLineItem__c> getPedidoLineItems(Set<Id> profIds) {
       List<PedidoLineItem__c> pedidoLineItems = new List<PedidoLineItem__c>();
       pedidoLineItems = [SELECT Id, 
                                 Name,
                                 Producto__c,
                                 Producto__r.Name,
                                 PedidoDeCompra__c,
                                 PedidoDeCompra__r.Proforma__c,
                                 Unidades__c,
                                 PrecioDeVenta__c,
                                 CostoTotalUnitario__c,
                                 CostoTotal__c,
                                 PrecioDeVentaTot__c,
                                 CostoOrigen__c
                            FROM PedidoLineItem__c
                           WHERE PedidoDeCompra__r.Proforma__c IN :profIds
                           AND PedidoDeCompra__r.RecordType.DeveloperName = :PRINCIPAL];
       return pedidoLineItems;
    }

    public Map<String, Decimal> buildMapProductocantidad(List<PedidoLineItem__c> ppedidoLineItems) {
       Map<String, Decimal> productoCantidad = new Map<String, Decimal>();
       Decimal cantidad = 0;

       for(PedidoLineItem__c pedidoLineItem : ppedidoLineItems) {
          cantidad = productoCantidad.get(pedidoLineItem.Producto__c);
          if(cantidad == null) {
             productoCantidad.put(pedidoLineItem.Producto__c, pedidoLineItem.Unidades__c);
          } else {
             cantidad = cantidad + pedidoLineItem.Unidades__c;
             productoCantidad.put(pedidoLineItem.Producto__c, cantidad);
          }
       }

       System.debug('PROD CANTIDAD:');
       for(String prodid : productoCantidad.keySet()) {
           System.debug('prodid [' + prodid + '] [' + productoCantidad.get(prodid) + ']');
       }
       System.debug('PROD CANTIDAD');
       return productoCantidad;
    }


    public Map<String, List<PedidoLineItem__c>> buildMapProductoPedidoLineItems(List<PedidoLineItem__c> ppedidoLineItems) {
       Map<String, List<PedidoLineItem__c>> productoPLI = new Map<String, List<PedidoLineItem__c>>();
       List<PedidoLineItem__c> listPedidoLineItems;

       for(PedidoLineItem__c pedidoLineItem : ppedidoLineItems) {
          listPedidoLineItems = productoPLI.get(pedidoLineItem.Producto__c);
          if(listPedidoLineItems == null) {
             listPedidoLineItems = new List<PedidoLineItem__c>();
             productoPLI.put(pedidoLineItem.Producto__c, listPedidoLineItems);
          }
          listPedidoLineItems.add(pedidoLineItem);
       }

       for(String prod : productoPLI.keySet()) {
          listPedidoLineItems = productoPLI.get(prod);
       }


       System.debug('PROD PLI:');
       List<PedidoLineItem__c> listPedidoLineItemsDebug;       
       for(String prodid : productoPLI.keySet()) {
           System.debug('prodid [' + prodid + ']');
           listPedidoLineItemsDebug = productoPLI.get(prodid);
           for(PedidoLineItem__c pli : listPedidoLineItemsDebug) {
               System.debug('   plineitem [' + pli.Id + '] [' + pli.Name + ']');
           }
       }
       System.debug('PROD PLI');       


       return productoPLI; 
    }


    public Map<String, Decimal> buildMapProductoCosto(Map<String, List<PedidoLineItem__c>> productoPedidosLineItemsMap, String mapType)
    {
       Map<String, Decimal> productoMap = new Map<String, Decimal>();
       List<PedidoLineItem__c> pliList;
       Decimal sumaUnidades = 0;
       Decimal sumaCostoCantidad = 0;
       Decimal promedio = 0;

       for(String prod : productoPedidosLineItemsMap.keySet())
       {
          sumaUnidades = 0;
          sumaCostoCantidad = 0;
          promedio = 0;           
          pliList = productoPedidosLineItemsMap.get(prod);
          for(PedidoLineItem__c pli : pliList) {
             sumaUnidades = sumaUnidades + pli.Unidades__c;
             if(mapType.equals('costo')) {
                 if(pli.CostoTotal__c != null) {
                     sumaCostoCantidad = sumaCostoCantidad + pli.CostoTotal__c;
                 }
             }
             if(mapType.equals('precio')) {
                 if(pli.PrecioDeVentaTot__c != null) {
                     sumaCostoCantidad = sumaCostoCantidad + pli.PrecioDeVentaTot__c;
                 }
             }
          }
          if(sumaUnidades > 0) {
             promedio = sumaCostoCantidad / sumaUnidades;
          } else {
              promedio = 0;
          }
          productoMap.put(prod, promedio);
       }

       System.debug('PROD COSTO:');
       for(String prodid : productoMap.keySet()) {
           System.debug('prodidco [' + prodid + '] [' + productoMap.get(prodid) + ']');
       }
       System.debug('PROD COSTO');       

       return productoMap;
    }


    public List<OpportunityLineItem> getOpportunityLineItems(String idOp) {
       List<OpportunityLineItem> oppLineItems;
       oppLineItems = [SELECT Id,
                              Aportaciones__c,
                              Aportaciones_2__c,
                              Convenio__c,
                              Convenio_2__c,
                              Porcentaje_Item__c,
                              Quantity,
                              Color__c,
                              ComentarioPackagingNuevo__c,
                              CostoProducto__c,
                              Costo_Total__c,
                              CreatedById,
                              Cumple_min_margen__c,
                              ProductCode,
                              Codigo_de_Producto__c,
                              Descripcion__c,
                              Description,
                              Discount,
                              Estado__c,
                              EstudioOportunidad__c,
                              Fabrica__c,
                              ServiceDate,
                              IdFabrica__c,
                              Imagen__c,
                              Importe_Neto__c,
                              IncrementoPorAportaciones__c,
                              Margen_minimo__c,
                              Modificar_precio_manual__c,
                              OpportunityId,
                              ListPrice,
                              UnitPrice,
                              Product2Id,
                              Product2.ProductoBase__c,                              
                              RequierePackagingNuevo__c,
                              Subtotal,
                              Total_CBM__c,
                              PricebookEntry.Product2.Name,
                              CurrencyIsoCode,
                              LastModifiedById
                         FROM OpportunityLineItem 
                        WHERE OpportunityId = :idOp];
       return oppLineItems;
    }

    public List<OpportunityLineItem> getOppLineItemsToClone(List<OpportunityLineItem> poppLineItems, Map<String, Decimal> pproductoCantidad, Map<String, Decimal> pproductoCosto, Map<String, Decimal> pproductoPrecio) {
       Integer index = 0;
       Decimal cantidadOLI = 0;
       Decimal costoOLI = 0;
       Decimal precioOLI = 0;
       List<OpportunityLineItem> oppLineItemsOppClone = new List<OpportunityLineItem>();

       for(OpportunityLineItem oli : poppLineItems) {
          System.debug('nmpr [' + oli.PricebookEntry.Product2.Name + '] [' + oli.Product2Id + '] [' + oli.Product2.ProductoBase__c +']');
          //cantidadOLI = pproductoCantidad.get(oli.Product2Id);
          cantidadOLI = pproductoCantidad.get(oli.Product2.ProductoBase__c);
          System.debug('cantidadOli 1: ' + cantidadOLI);
          if(cantidadOLI == null) {
              cantidadOLI = pproductoCantidad.get(oli.Product2Id);
              System.debug('cantidadOli 2: ' + cantidadOLI);              
          }

          //precioOLI = pproductoPrecio.get(oli.Product2Id);
          precioOLI = pproductoPrecio.get(oli.Product2.ProductoBase__c);
          System.debug('precioOli 1: ' + precioOLI);
          if(precioOLI == null) {
              precioOLI = pproductoPrecio.get(oli.Product2Id);
              System.debug('precioOli 2: ' + precioOLI);
              if(precioOLI == null) {
                  precioOLI = 0;
              }
          }
          if(cantidadOLI != null) {
             costoOLI = pproductoCosto.get(oli.Product2Id);
             System.debug('costoOli: ' + costoOLI);
             oli.Quantity = cantidadOLI;
             oli.CostoProducto__c = costoOLI;
             oli.UnitPrice = precioOLI;
          } else {
             oppLineItemsOppClone.add(oli);
          }
          index++;
       }

       System.debug('oppLineItemsOppClone: ' + oppLineItemsOppClone);

       for(OpportunityLineItem olitc : oppLineItemsOppClone) {
           System.debug('olitc: ' + olitc);           
           index = poppLineItems.indexOf(olitc);
           if(index >= 0) {
              poppLineItems.remove(index);
           }
       }

       return oppLineItemsOppClone;
    }

    /**
    *   After creating a new open Opportunity the asociated EstudioOportunidad are processed as follows:
    *       1) If it has no orders, it gets linked to the new opportunity
    *       2) If it has no open Proformas and has Orders, no changes are made
    *       3) If it has open Proformas and Orders it gets cloned and linked to the new Opportunity
    *       returns: A map of original EstudioOportunidad Id to cloned Study
     */
    public Map<Id, EstudioOportunidad__c> processStudies(Id newOppId) {
        Map<Id, EstudioOportunidad__c> existingEOToClone = new Map<Id, EstudioOportunidad__c>();
        List<EstudioOportunidad__c> upsertStudies = new List<EstudioOportunidad__c>();
        for(EstudioOportunidad__c e : estudiosOpp) {
            OppStudyStatus oss = estudioToStatus.get(e.Id);
            if(!oss.hasOrder) {
                e.Oportunidad__c  = newOppId;
                upsertStudies.add(e);
                existingEOToClone.put(e.Id, e);                
            } else if(oss.hasProformaWNOOrder){
                EstudioOportunidad__c cloneEO  = e.clone();
                cloneEO.Oportunidad__c  = newOppId;
                upsertStudies.add(cloneEO);
                existingEOToClone.put(e.Id, cloneEO);
            }
        }
        upsert upsertStudies;
        return existingEOToClone;
    }

    /**
    *   For all Proformas linked to the original Opportunity with no order (ConfirmacionCliente__c = false):
    *   If the Proforma Study has been cloned, 
    *   it links the proforma to the new study and new Opportunity
    *
     */
    public void processProformas(Id newOppId, Map<Id, EstudioOportunidad__c> oldStudyToClone) {
        List<Proforma__c> toUpdate = new List<Proforma__c>();
        for(Proforma__c pr : [SELECT Id,
                                    EstudioOportunidad__c
                                    FROM Proforma__c
                                    WHERE Oportunidad__c = :opportunityId
                                    AND ConfirmacionCliente__c = false]){
            if(oldStudyToClone.containsKey(pr.EstudioOportunidad__c)){
                pr.EstudioOportunidad__c = oldStudyToClone.get(pr.EstudioOportunidad__c).Id;
                pr.Oportunidad__c = newOppId;
                toUpdate.add(pr);
            }
        }
        update toUpdate;
    }
    

    /**
    *   For a list of OpportunityLineItems and a map with the amount of such products in orders
    *   For each OppLineItem if it has orders and also Proformas w/o order, it gets forked(cloned)
    *   And sets Qty - Qty in orders as the forked Qty
    *
     */
    private List<OpportunityLineItem> getOppLineItemsFork(List<OpportunityLineItem> closedItems,
                                                            Map<String, Decimal> prodsInOrders,
                                                            Map<Id, List<String>> prodsInProformaNOOrder) {
        List<OpportunityLineItem> result = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli : closedItems) {
            if(prodsInOrders.containsKey(oli.Product2Id) && prodsInProformaNOOrder.containsKey(oli.Product2Id)) {
                if(oli.Quantity - prodsInOrders.get(oli.Product2Id) > 0) {
                    OpportunityLineItem forked = oli.clone();
                    forked.Quantity = oli.Quantity - prodsInOrders.get(oli.Product2Id);
                    result.add(forked);
                }
            }
        }
        return result;
    }

    /**
    *   If originalName ends in "-[number]" it adds 1 to the number
    *   otherwise it adds "-2" to the originalName
     */
    private String nameClonedOpp(String originalName) {
        Pattern withNumber = Pattern.compile('(.*)-(\\d+)');
        Matcher nameMatcher = withNumber.matcher(originalName);
        String cloneName;
        if(nameMatcher.find()) {
            cloneName = nameMatcher.group(1);
            Integer counter = Integer.valueOf(nameMatcher.group(2)) + 1;
            cloneName += '-';
            cloneName += counter;
        } else {
            cloneName = originalName + '-2';
        }
        system.debug('CLONE NAME: ' + cloneName);
        return cloneName;
    }

    public class OppStudyStatus {
        boolean hasProformaWNOOrder {get;set;}
        boolean hasOrder {get;set;}
        
        public OppStudyStatus() {
            hasProformaWNOOrder = false;
            hasOrder = false;
        }
    }
}