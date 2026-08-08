public class OpportunityCostVerification {
    public String idOpportunity {set; get;}
    public Opportunity opportunity {set; get;}
    public List<Account> factories {set; get;}
    public List<Product2> products {set; get;}
    private Map<String, List<Product2>> factoriesProds; //idFactory, prod
    private Map<String, Account> idsFactories;
    private Map<String, Product2> idsProducts;
    public List<ProductCostVerification> productsCostV;

    public OpportunityCostVerification(Opportunity popp) {
        opportunity = popp;
        idOpportunity = opportunity.Id;
        factoriesProds = new Map<String, List<Product2>>();
        idsFactories = new Map<String, Account>();
        idsProducts = new Map<String, Product2>();
        productsCostV = new List<ProductCostVerification>();
    }

    public void addOppLineItem(OpportunityLineItem oli) {
         Account factory;
         Product2 prod;
         ProductCostVerification pcv;
         List<Product2> prods;
         Integer plazoPrecios;
         Date ultimaFechaRevision;
         Date limiteFechaRevision;
         Integer diffDays;
         
         factory = idsFactories.get(oli.Product2.Fabrica__c);
         if(factory == null) {
             factory = new Account();
             factory.Name = oli.Product2.Fabrica__r.Name;
             factory.Id = oli.Product2.Fabrica__c;
             idsFactories.put(factory.Id, factory);
         }

         prod = idsProducts.get(oli.Product2Id);
         if(prod == null) {
             prod = new Product2();
             prod.Id = oli.Product2Id;
             prod.Name = oli.Product2.Name;
             prod.PrecioDeFabrica__c = oli.Product2.PrecioDeFabrica__c;
             prod.Fecha_revision_costo__c = oli.Product2.Fecha_revision_costo__c;
             prod.Estado_verificacion_costo__c = oli.Product2.Estado_verificacion_costo__c;

             System.debug(' FRC[' + prod.Fecha_revision_costo__c + '] FP[' + oli.Product2.Fabrica__r.Plazo_Precios_Proveedor__c + ']');

             if(prod.Fecha_revision_costo__c == null || oli.Product2.Fabrica__r.Plazo_Precios_Proveedor__c == null) {
                prod.Precio_Vigente__c = false;
                diffDays = 0;
             } else {
                 plazoPrecios = Integer.valueOf(oli.Product2.Fabrica__r.Plazo_Precios_Proveedor__c);
                 ultimaFechaRevision = prod.Fecha_revision_costo__c;
                 limiteFechaRevision = Date.today();
                 limiteFechaRevision = limiteFechaRevision.addDays(plazoPrecios * -1);
                 if(limiteFechaRevision > ultimaFechaRevision) {
                    prod.Precio_Vigente__c = false;
                 } else {
                    prod.Precio_Vigente__c = true;                     
                 }
                 diffDays = Date.today().daysBetween(ultimaFechaRevision.addDays(plazoPrecios));
             }
             //prod.Precio_Vigente__c = oli.Product2.Precio_Vigente__c;
             prod.IDImagen1__c = oli.Product2.ProductoBase__r.IDImagen1__c;

             pcv = new ProductCostVerification(prod);
             pcv.idFactory = oli.Product2.Fabrica__c;
             pcv.compareType = 'greenred';
             pcv.imageInfo = oli.Product2.ProductoBase__r.IDImagen1__c;
             pcv.codigo = oli.Product2.CodigoDeProductoBase__c;
             pcv.plazoPreciosProveedor = oli.Product2.Fabrica__r.Plazo_Precios_Proveedor__c;
             pcv.isPrecioVigente = prod.Precio_Vigente__c;
             if(pcv.isPrecioVigente) {
                 pcv.orderColor = 3;
                 pcv.colorBall = '/resource/1560452910000/greenCircle';
             } else {
                 pcv.orderColor = 1;
                 pcv.colorBall = '/resource/1560452910000/redCircle';
             }
             pcv.oppLineItemID = oli.Id;
             pcv.descripcion = oli.Product2.ProductoBase__r.Descripcion_Larga__c;
             pcv.fechaRevision = oli.Product2.Fecha_revision_costo__c;
             pcv.daysValidCost = diffDays;

             productsCostV.add(pcv);
             idsProducts.put(prod.Id, prod);
         }

         prods = factoriesProds.get(factory.Id);
         if(prods == null) {
             prods = new List<product2>();
             factoriesProds.put(factory.Id, prods);
         }
         prods.add(prod);
    }

}