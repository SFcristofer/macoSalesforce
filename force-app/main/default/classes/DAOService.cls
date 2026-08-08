public class DAOService {
    
    /** Return products quantity classified by family, subfamily and class **/
    
    public static List<ProductListClassificationData> fetchProductsQuantity() {
        List<ProductListClassificationData> productsQuantity = new List<ProductListClassificationData>();
        ProductListClassificationData pcd;
        AggregateResult[] results = null;
        
        results = [SELECT Family fam, 
                          Subfamilia__c subfam, 
                          Clase__c clsName, 
                          COUNT(Id) numberProds 
                     FROM Product2 
                 GROUP BY Family, 
                          Subfamilia__c, 
                          Clase__c 
                 ORDER BY Family, Subfamilia__c, Clase__c];
                          
        for (AggregateResult ar : results) {
            pcd = new ProductListClassificationData();
            pcd.family = (String)ar.get('fam');
            pcd.subfamily = (String)ar.get('subfam');
            pcd.className = (String)ar.get('clsName');
            pcd.numberProducts = (Integer)ar.get('numberProds');                                    
            productsQuantity.add(pcd);
        }
                          
        return productsQuantity;
    }
    
   
    /** Return products quantity classified by family, subfamily and class **/
    public static List<ProductListClassificationData> fetchProductsQuantity(String pfamily, String psubfamily, String pclass) {
        List<ProductListClassificationData> productsQuantity = new List<ProductListClassificationData>();
        ProductListClassificationData pcd;
        AggregateResult[] results = null;
        
        results = [SELECT Family fam, 
                          Subfamilia__c subfam, 
                          Clase__c clsName, 
                          COUNT(Id) numberProds 
                     FROM Product2 
                    WHERE Family = :pfamily
                      AND Subfamilia__c = :psubfamily
                      AND Clase__c = :pclass
                 GROUP BY Family, 
                          Subfamilia__c, 
                          Clase__c 
                 ORDER BY Family, Subfamilia__c, Clase__c];
                 
        if (results != null) {
            for (AggregateResult ar : results) {
                pcd = new ProductListClassificationData();
                pcd.family = (String)ar.get('fam');
                pcd.subfamily = (String)ar.get('subfam');
                pcd.className = (String)ar.get('clsName');
                pcd.numberProducts = (Integer)ar.get('numberProds');                                    
                productsQuantity.add(pcd);
            }
        }

        return productsQuantity;
    }    


    public static List<Product2> fetchProducts(String pfamily, String psubfamily, String pclass, Integer plimit, Integer poffset) {
        List<Product2> productsList = new List<Product2>();
        
        productsList = [SELECT Id, 
                               Name, 
                               ProductName__c, 
                               Medidas_del_Producto_Agrupadas2__c,
                               Color2__c,
                               ProductCode,
                               Codigo_EAN2__c,
                               Codigo_DUN_14__c,
                               CodigoArancelario__c,
                               IsActive,
                               Family,
                               Subfamilia__c,
                               Clase__c,
                               Marca__c,
                               MarcaItemDeFactura__c,
                               PackagingPersonalizado__c,
                               Description,
                               Material__c,
                               ComposicionEnPorcentaje__c,
                               Listado_en_catalogo__c,
                               Garantia__c,
                               ManualDeInstrucciones__c,
                               Producto_detalle__c,
                               ProductoLargoCm__c,
                               ProductoAnchoCm__c,
                               ProductoAltoCm__c,
                               ProductoDiametroCm__c,
                               ProductoM3__c,
                               Volumen_Producto_m3__c, 
                               ProductoPesoKg__c,
                               G_W_del__c,
                               IDImagen1__c,
                               IDImagen2__c,
                               IDImagen3__c,
                               IDImagen4__c
                          FROM Product2 
                         WHERE Family = :pfamily
                           AND Subfamilia__c = :psubfamily
                           AND Clase__c = :pclass
                      ORDER BY Family, Subfamilia__c, Clase__c
                         LIMIT :plimit OFFSET :poffset];
                 
        return productsList;
    } 
    
    //MasterLabel - ProdService
    public static List<String> getMetadataProductService(String labelMtdt) {
        List<Producto_Service_IP_Access__mdt> metadataIPsAccess;
        List<String> ipsAddress;
        
        ipsAddress = new List<String>();
        
        metadataIPsAccess = [SELECT Id,
                                    DeveloperName,
                                    MasterLabel,
                                    IP_Address__c
                               FROM Producto_Service_IP_Access__mdt
                              WHERE MasterLabel = :labelMtdt];
                              
        for(Producto_Service_IP_Access__mdt mdtRow : metadataIPsAccess) {
            ipsAddress.add(mdtRow.IP_Address__c);
        }
        
        return ipsAddress;
    
    }   
    
}