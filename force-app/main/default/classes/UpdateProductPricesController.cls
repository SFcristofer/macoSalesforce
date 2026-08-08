public class UpdateProductPricesController {
    public List<String> productsPriceUpdated;
    public List<OppFactProdVerification> ofpvList;
    public Map<String, Product2> mapProducts;
    public Map<String, OpportunityLineItem> mapIdOLIs;    

    public UpdateProductPricesController(List<String> idsProducts) {
        productsPriceUpdated = idsProducts;
    }

    public UpdateProductPricesController(List<OppFactProdVerification> ofpvs) {
        productsPriceUpdated = new List<String>();
        ofpvList = ofpvs;
        for(OppFactProdVerification ofpv : ofpvs) {
            productsPriceUpdated.add(ofpv.idProduct);
        }
    }

    public void executeProductUpdateOFPV() {
        Product2 prod;
        Map<String, Product2> productsVerified;
        List<Product2> productsToBeUpdated = new List<Product2>();
        productsVerified = getProductsToUpdate(productsPriceUpdated);
        
        for(OppFactProdVerification ofpv : ofpvList) {
            prod = productsVerified.get(ofpv.idProduct);

            if(prod != null) {
                prod.PrecioDeFabrica__c = ofpv.newCostProduct;
                prod.Fecha_revision_costo__c = Date.today();
                productsToBeUpdated.add(prod);
            }
        }

        update productsToBeUpdated;
    }

    
    public void executeOppLineItemUpdate() {
        Product2 prodU;
        Set<String> olisUpdtd;
        Map<String, Set<String>> mapIdProdOLIS;
        List<OpportunityLineItem> olitms;
        List<OpportunityLineItem> oliToUpdt;        
        OpportunityLineItem oliU;        

        mapIdProdOLIS = new Map<String, Set<String>>();
        mapIdOLIs = new Map<String, OpportunityLineItem>();

        oliToUpdt = new List<OpportunityLineItem>();

        olitms = [SELECT Id,
                         UnitPrice,
                         CostoProducto__c,                         
                         OpportunityId,
                         Product2Id,
                         Opportunity.StageName
                    FROM OpportunityLineItem
                   WHERE Opportunity.StageName NOT IN ('Cerrada/Ganada','Cerrada/Perdida') 
                     AND Product2Id IN :productsPriceUpdated];

        //groupd opplineitems by prodid
        for(OpportunityLineItem oli : olitms) {
            mapIdOLIs.put(oli.Id, oli);

            olisUpdtd = mapIdProdOLIS.get(oli.Product2Id);
            if(olisUpdtd == null) {
                olisUpdtd = new Set<String>();
                olisUpdtd.add(oli.Id);
                mapIdProdOLIS.put(oli.Product2Id, olisUpdtd);
            } else {
                olisUpdtd.add(oli.Id);
            }
        }

        //upate each oli  unit price
        for(String prodId : mapIdProdOLIS.keySet()) {
            prodU = mapProducts.get(prodId);
            olisUpdtd =  mapIdProdOLIS.get(prodId);

            for(String oliId : olisUpdtd) {
                oliU = mapIdOLIs.get(oliId);
                //oliU.UnitPrice = prodU.PrecioDeFabrica__c;
                //oliU.CostoProducto__c = prodU.CostoTotal2__c;
                oliU.CostoProducto__c = prodU.PrecioDeFabrica__c + prodU.CostoImportacionUnidad__c + prodU.CostoPackaging__c;
                System.debug('oliid[' + oliU.Id + '] olicp[' + oliU.CostoProducto__c + '] prodcostt2[' + prodU.CostoTotal2__c + ']');
                oliToUpdt.add(OliU);
            }
        }

        //update olis
        update oliToUpdt;
    }


    public Map<String, Product2> getProductsToUpdate(List<String> idProducts) {
        List<Product2> products;        
        mapProducts = new Map<String, Product2>();

        products = [SELECT Id,
                           Name,
                           PrecioDeFabrica__c,
                           CostoImportacionUnidad__c,
                           CostoPackaging__c,
                           CostoTotal2__c,                           
                           Fecha_revision_costo__c
                      FROM Product2
                     WHERE Id IN :idProducts];

        for(Product2 pr : products) {
            mapProducts.put(pr.Id, pr);
        }
        return mapProducts;
    }

}