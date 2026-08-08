/**
*   Trigger helper class for Escandallo.trigger (should probably be re-named).
*   
*/
public class ActualizarPrecioProductoController {
    private Escandallo__c escandallo;
    private Map<Id, EscandalloLineItem__c> productIdToEscandalloLineItem;
    public Boolean productoEstaActualizado {get; set;}
    public datetime escandalloLastUpdated {get; set;}
    private Set<Id> productIds;


    /**
    *   Constructor. Loads all ItemsEscandallo.
    *   Assumes Escandallo is a singleton.
    */
    public ActualizarPrecioProductoController() {
        productIdToEscandalloLineItem = new Map<Id, EscandalloLineItem__c>();
        this.escandallo = [SELECT Id, (SELECT Producto__c,
                                                CostoTotalUnidad__c,
                                                CostoImportacionUnidad__c,
                                                PrecioCompraFabrica__c,
                                                Producto__r.CostoTotal2__c,
                                                Producto__r.PrecioDeFabrica__c,
                                                Producto__r.LastModifiedDate,
                                                LastModifiedDate,
                                                Porcentaje_Oficina_GS__c
                                                FROM ItemsEscandallo__r),
                                LastModifiedDate
                                FROM Escandallo__c limit 1];
    }
    
    /**
    *   Constructor. Loads SELECTED ItemsEscandallo based on their linked product.
    *   Assumes Escandallo is a singleton.
    */
    public ActualizarPrecioProductoController(Set<Id> prodIds) {
        productIdToEscandalloLineItem = new Map<Id, EscandalloLineItem__c>();
        this.escandallo = [SELECT Id, (SELECT Producto__c,
                                                CostoTotalUnidad__c,
                                                CostoImportacionUnidad__c,
                                                PrecioCompraFabrica__c,
                                                Producto__r.CostoTotal2__c,
                                                Producto__r.PrecioDeFabrica__c,
                                                Producto__r.LastModifiedDate,
                                                LastModifiedDate,
                                                Porcentaje_Oficina_GS__c
                                                FROM ItemsEscandallo__r
                                                WHERE Producto__c IN :prodIds),
                                LastModifiedDate
                                FROM Escandallo__c limit 1];
                                
        productIds = prodIds;
    }

    /**
    *   For all base products, gets its sub-products and updates all Pricebook Entries for the 
    *   laters based on the new Import Cost.
    *   Note: Test Governor Limits for a lot of products may need to split in several operations
    */
    public void updatePrice() {
        System.debug('items ' + escandallo.ItemsEscandallo__r);
        for (EscandalloLineItem__c cli: escandallo.ItemsEscandallo__r){
            productIdToEscandalloLineItem.put(cli.Producto__c, cli);   
        }
        
        Map<Id, Product2> productosToUpdate = new Map<Id, Product2>();
        for (EscandalloLineItem__c cli: productIdToEscandalloLineItem.values()){
            if(cli.Producto__r != null){
                cli.Producto__r.CostoEscandallo__c = cli.CostoImportacionUnidad__c;
                productosToUpdate.put(cli.Producto__c, cli.Producto__r);
            }
        }
        if(!productosToUpdate.isEmpty()){
            update productosToUpdate.values();
        }
        
        for(Product2 subProd : [SELECT Id,
                                    ProductoBase__c,
                                    ProductoDeFabrica__r.ProductoBase__c
                                    FROM Product2
                                    WHERE ProductoBase__c in :productIdToEscandalloLineItem.keySet()
                                    OR ProductoDeFabrica__r.ProductoBase__c in :productIdToEscandalloLineItem.keySet()]){
            if(subProd.ProductoBase__c != null){
                productIdToEscandalloLineItem.put(subProd.Id, productIdToEscandalloLineItem.get(subProd.ProductoBase__c));
            }else{
                productIdToEscandalloLineItem.put(subProd.Id, productIdToEscandalloLineItem.get(subProd.ProductoDeFabrica__r.ProductoBase__c));
            }
        }
        
        
        List<PricebookEntry> pricebookEntries = [SELECT Name, 
                                                        Pricebook2.Margen__c, 
                                                        Pricebook2.Name, 
                                                        Product2Id,
                                                        UnitPrice,
                                                        Product2.CostoPackaging__c, 
                                                        Product2.ProductoBase__c 
                                                        FROM PricebookEntry 
                                                        WHERE Product2Id IN :productIdToEscandalloLineItem.keySet()];
        
        
        Map<Id, Product2> productosMap = new Map<Id, Product2>([SELECT Id,
                                                                CostoTotal2__c
                                                                FROM Product2 where Id IN :productIdToEscandalloLineItem.keySet()]);
        List<PricebookEntry> pricebookEntriesToUpdate = new List<PricebookEntry>();
        for (PricebookEntry pbe: pricebookEntries){
            if (pbe.Pricebook2.Margen__c != null && pbe.Pricebook2.Margen__c > 0){
                Product2 prodData = productosMap.get(pbe.Product2Id);
                EscandalloLineItem__c escItem = productIdToEscandalloLineItem.get(pbe.Product2.ProductoBase__c);
                
                Decimal costoTotal = (prodData != null && prodData.CostoTotal2__c != null) ? prodData.CostoTotal2__c : 0;
                Decimal oficinaGS = (escItem != null && escItem.Porcentaje_Oficina_GS__c != null) ? escItem.Porcentaje_Oficina_GS__c : 0;
                Decimal margen = pbe.Pricebook2.Margen__c / 100;
                
                Decimal divisor = 1 - (margen + (oficinaGS / 100));
                if (divisor != 0) {
                    Decimal nuevoPrecio = costoTotal / divisor;
                    
                    if (pbe.UnitPrice != nuevoPrecio) {
                        pbe.UseStandardPrice = false;
                        pbe.UnitPrice = nuevoPrecio;
                        pricebookEntriesToUpdate.add(pbe);
                    }
                }
            }
        }
        
        if (!pricebookEntriesToUpdate.isEmpty()) {
            update pricebookEntriesToUpdate;
        }
    }
/*
    public void verificarProductoActualizado(){
        System.debug('escandallo last modified ' + escandallo.LastModifiedDate);
        escandalloLastUpdated = escandallo.LastModifiedDate;
        datetime productoLastUpdated = datetime.newInstance(1900, 1, 1);
         
        for (EscandalloLineItem__c cli: escandallo.ItemsEscandallo__r){
            System.debug('cli last modified ' + cli.LastModifiedDate);
            System.debug('prod last modified ' + cli.Producto__r.LastModifiedDate);

            if (cli.LastModifiedDate > escandalloLastUpdated){
                escandalloLastUpdated = cli.LastModifiedDate;
            }
            if (cli.Producto__r.LastModifiedDate > productoLastUpdated){
                productoLastUpdated = cli.Producto__r.LastModifiedDate;
            }
        }
        System.debug('productoLastUpdated ' + productoLastUpdated);
        System.debug('escandalloLastUpdated ' + escandalloLastUpdated);

        this.productoEstaActualizado = productoLastUpdated >= escandalloLastUpdated;        
    }
*/
}