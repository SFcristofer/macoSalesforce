public class OpportunityDAO {

    public static Opportunity getClonedOpportunity(String idOpp) {
        Boolean res;
        Opportunity result;
        Set<String> fieldNames;
        Map<String, Schema.SObjectField> fieldMap = Opportunity.sObjectType.getDescribe().fields.getMap();
        
        fieldNames = fieldMap.keySet();
        
        List<Opportunity> clonedOpp = Database.query('SELECT ' + String.join((Iterable<String>)fieldNames, ',') 
                                            + ' FROM Opportunity'
                                            + ' WHERE Id = \'' + idOpp + '\'');
        if(clonedOpp != null && clonedOpp.size() > 0) {
           result = clonedOpp[0];
        }
        return result;
    }


    public static List<OpportunityCostVerification> getOpportunitiesCostVerification(List<String> idOpps) {
        List<OpportunityCostVerification> oppsCostVerification = new List<OpportunityCostVerification>();
        OpportunityCostVerification oppCostVerification;
        List<Opportunity> opps;
        List<OpportunityLineItem> olis;
        opps = [SELECT Id, 
                       Name,
                       AccountId,
                       Account.Name, 
                       (SELECT Id,
                               Name,
                               Product2Id,  
                               Product2.CodigoDeProductoBase__c,
                               Product2.ProductCode,
                               Product2.Name,
                               Product2.PrecioDeFabrica__c,
                               Product2.Fecha_revision_costo__c,
                               Product2.Estado_verificacion_costo__c,
                               Product2.Precio_Vigente__c,
                               Product2.ProductoBase__r.Descripcion_Larga__c,
                               Product2.ProductoBase__r.IDImagen1__c,
                               Product2.ProductoBase__r.Imagen1__c,
                               Product2.ProductoBase__r.Thumb1__c,
                               Product2.ProductoBase__r.ProductCode,
                               Product2.Fabrica__c,
                               Product2.Fabrica__r.Name,
                               Product2.Fabrica__r.Plazo_Precios_Proveedor__c
                          FROM OpportunityLineItems 
                      ORDER BY Product2.Name)
                  FROM Opportunity 
                 WHERE Id IN :idOpps];

        for(Opportunity opp : opps) {
            oppCostVerification = new OpportunityCostVerification(opp);
            oppsCostVerification.add(oppCostVerification);
            olis = opp.OpportunityLineItems;
            for(OpportunityLineItem oli : olis) {
                oppCostVerification.addOppLineItem(oli);
            }

            /*System.debug('---------------------------------------------- DAO --------------------------------------------------------------------');
            for(OpportunityCostVerification ocv : oppsCostVerification) {
                for(ProductCostVerification pcv : ocv.productsCostV) {
                    System.debug(' [' + pcv.product.Id + '] [' + pcv.codigo + '] [' + pcv.product.Fecha_revision_costo__c + ']');
                }
            }*/
        }
        return oppsCostVerification;
    }

}


/*
    public static Opportunity getOpportunity(String idOpp) {
        //origin : china
        //port of landing
        Opportunity opp;
        opp = [SELECT Id,
                      Name,
                      AccountId,
                      CurrencyIsoCode,
                      URL_Cotizacion__c,
                      CostoFOB__c,
                      Is_Brand_Selected__c,
                      Pricebook2Id,
                      Pricebook2.Margen__c,
                      PlanificacionComercial__r.PorcentajeAportaciones__c,
                      PlanificacionComercial__r.PorcentajeConvenio__c,
                      (SELECT Id,
                              ComentariosCatalogo__c,
                              ComentarioPackagingNuevo__c,
                              Name,
                              Porcentaje_Item__c,
                              Precio_Minimo__c,
                              UnitPrice, //precio de venta - precio fob
                              Quantity,
                              Product2Id,
                              Product2.Marca2__c,
                              Product2.Color2__c,
                              Comentario_atendido__c,
                              Producto_Packaging__c,
                              Producto_Packaging__r.Packaging__c,
                              Producto_Packaging__r.CostoPackaging__c,
                              RequierePackagingNuevo__c,
                              Product2.CostoImportacionUnidad__c,
                              Product2.PrecioDeFabrica__c,                              
                              Product2.Codigo_EAN2__c,
                              Product2.PlazoDeFabricacion__c, //lead time
                              Product2.CodigoDeProductoBase__c,//suppliers item
                              Product2.Marca__c,
                              Product2.CostoPackaging__c,
                              Product2.Name,  //spanish description
                              Product2.RecordType.DeveloperName,
                              Product2.ProductoBase__r.Description, //
                              Product2.ProductoBase__r.Descripcion_Larga__c,
                              Product2.ProductoBase__r.Material__c, //Composition(material)
                              Product2.ProductoBase__r.UnidadesPorMasterBox__c, // (quantuty per carton master)
                              Product2.Packaging__c, //packaging
                              Product2.MOQ__c, //MOQ
                              Product2.ProductoBase__r.IDImagen1__c,
                              Product2.ProductoBase__r.Imagen1__c,
                              Product2.ProductoBase__r.UnidadesHQ__c,
                              Product2.ProductoBase__r.UnidadesContainer40__c, // agregar json, java, columnas
                              Product2.ProductoBase__r.UnidadesContainer20__c,
                              Product2.ProductoBase__r.ProductoAltoCm__c, // H(cm)
                              Product2.ProductoBase__r.ProductoAnchoCm__c, // W(cm)
                              Product2.ProductoBase__r.ProductoLargoCm__c, //L(cm)
                              Product2.ProductoBase__r.Producto_detalle__c,
                              Product2.ProductoBase__r.ProductoDiametroCm__c, //diam
                              Product2.ProductoBase__r.ProductoPesoKg__c, //w(kg)
                              Product2.ProductoBase__r.ProductoM3__c, //cubic meter
                              Product2.ProductoBase__r.Producto2AltoCm__c, // H(cm)
                              Product2.ProductoBase__r.Producto2AnchoCm__c, // W(cm)
                              Product2.ProductoBase__r.Producto2LargoCm__c, //L(cm)
                              Product2.ProductoBase__r.Producto2_detalle__c,
                              Product2.ProductoBase__r.Producto2DiametroCm__c,
                              Product2.ProductoBase__r.Producto2PesoKg__c,
                              Product2.ProductoBase__r.Producto2M3__c,
                              Product2.ProductoBase__r.Producto3AltoCm__c, // H(cm)
                              Product2.ProductoBase__r.Producto3AnchoCm__c, // W(cm)
                              Product2.ProductoBase__r.Producto3LargoCm__c, //L(cm)
                              Product2.ProductoBase__r.Producto3_detalle__c,
                              Product2.ProductoBase__r.Producto3DiametroCm__c,
                              Product2.ProductoBase__r.Producto3PesoKg__c,
                              Product2.ProductoBase__r.Producto3M3__c,
                              Product2.ProductoBase__r.Masterbox1_detalle__c,
                              Product2.ProductoBase__r.MasterboxAltoCm__c,
                              Product2.ProductoBase__r.MasterboxAnchoCm__c,
                              Product2.ProductoBase__r.MasterboxLargoCm__c,
                              Product2.ProductoBase__r.MasterboxM3__c,
                              Product2.ProductoBase__r.MasterboxPesoKg__c,
                              Product2.ProductoBase__r.Masterbox2AltoCm__c,
                              Product2.ProductoBase__r.Masterbox2AnchoCm__c,
                              Product2.ProductoBase__r.Masterbox2LargoCm__c,
                              Product2.ProductoBase__r.Masterbox2M3__c,
                              Product2.ProductoBase__r.Masterbox2PesoKg__c,
                              Product2.ProductoBase__r.Masterbox2_detalle__c,
                              Product2.ProductoBase__r.Masterbox3AltoCm__c,
                              Product2.ProductoBase__r.Masterbox3AnchoCm__c,
                              Product2.ProductoBase__r.Masterbox3LargoCm__c,
                              Product2.ProductoBase__r.Masterbox3M3__c,
                              Product2.ProductoBase__r.Masterbox3PesoKg__c,
                              Product2.ProductoBase__r.Masterbox3_detalle__c,
                              Product2.ProductoBase__r.CodigoArancelario__c,
                              Product2.ProductoBase__r.Name,
                              Product2.ProductoBase__r.Clase__c,
                              Product2.ProductoBase__r.Subfamilia__c,
                              Product2.ProductoBase__r.Family,   
                              Product2.ProductoBase__r.Medidas_Agrupadas__c,  
                              Product2.ProductoBase__r.Packaging__c,
                              Product2.ProductoBase__r.Color__c,
                              Product2.Fabrica__r.PaisDelPuerto__c,
                              Product2.Fabrica__r.Puerto__c,
                              Product2.ProductoBase__r.ProductCode   //<ProductCode>.jpg
                         FROM OpportunityLineItems 
                     ORDER BY Product2.Name)
                 FROM Opportunity
                WHERE Id = :idOpp];
        return opp;
    }

*/