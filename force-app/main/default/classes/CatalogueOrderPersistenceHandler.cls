/**
 * Handles the serialization and persistence of a Catalogue Order Selection in Seleccion__c object
 */
public class CatalogueOrderPersistenceHandler {
    public CatalogueOrderPersistenceHandler() {

    }

    /*
    *   Fetches all Seleccion__c linked to the Catalogo__c with Portal_Token__c = token and 
    *   generates a PedidoCatalogo with the data
    */
    public static PedidoCatalogo fetchPedidoCatalogo(String token) {
        PedidoCatalogo result = new PedidoCatalogo();
        result.token = token;
        List<Catalogo__c> lc = [SELECT Id 
                                    FROM Catalogo__c
                                    WHERE Portal_Token__c = :token];
        if(!lc.isEmpty()) {
            result.numeroPedido = lc[0].Id;
            for(Seleccion__c s : [SELECT ProdId__c,
                                    prodCode__c,
                                    prodName__c,
                                    prodFamPrefix__c,
                                    prodSfmPrefix__c,
                                    prodClaPrefix__c,
                                    prodMeasures__c,
                                    prodPackaging__c,
                                    prodImageId__c,
                                    prodColor__c,
                                    comments__c,
                                    selectedPackaging__c
                                    FROM Seleccion__c
                                    WHERE Catalogo__r.Portal_Token__c = :token]) {
                ProductoPedidoCatalogo ppc = new ProductoPedidoCatalogo();
                ppc.prodId = s.prodId__c;
                ppc.prodCode = s.prodCode__c;
                ppc.prodName = s.prodName__c;
                ppc.prodFamPrefix = s.prodFamPrefix__c;
                ppc.prodSfmPrefix = s.prodSfmPrefix__c;
                ppc.prodClaPrefix = s.prodClaPrefix__c;
                ppc.prodMeasures = s.prodMeasures__c;
                ppc.prodPackaging = s.prodPackaging__c;
                ppc.prodImageId = s.prodImageId__c;
                ppc.prodColor = s.prodColor__c;
                ppc.comments = s.comments__c;
                ppc.selectedPackaging = s.selectedPackaging__c;
                result.productos.add(ppc);
            }
        }
        
        return result;
    }

    /*
    *   Inserts a new Seleccion__c for the Catalogo__c with Id = cId
    */
    public static void insertNewSelection(ProductoPedidoCatalogo ppc, String cId) {
        Seleccion__c s = new Seleccion__c(Catalogo__c = cId,
                                            prodId__c = ppc.prodId,
                                            prodCode__c = ppc.prodCode,
                                            prodName__c = ppc.prodName,
                                            prodFamPrefix__c = ppc.prodFamPrefix,
                                            prodSfmPrefix__c = ppc.prodSfmPrefix,
                                            prodClaPrefix__c = ppc.prodClaPrefix,
                                            prodMeasures__c = ppc.prodMeasures,
                                            prodPackaging__c = ppc.prodPackaging,
                                            prodImageId__c = ppc.prodImageId,
                                            prodColor__c = ppc.prodColor,
                                            comments__c = ppc.comments,
                                            selectedPackaging__c = ppc.selectedPackaging);
        insert s;
    }

    /**
     * Deletes a Seleccion__c instance based on its Catalogo__c and ProdCode__c
     */
    public static void deleteSelection(String cId, String pCode) {
        delete [SELECT Id
                    FROM Seleccion__c
                    WHERE Catalogo__c = :cId
                    AND prodCode__c = :pCode];

    }

    /**
     * Updates the selectedPackaging__c for a Seleccion__c 
     */
    public static void updateSelectionPackaging(ProductoPedidoCatalogo p, String cId) {
        Seleccion__c s = [SELECT Id
                            FROM Seleccion__c
                            WHERE Catalogo__c = :cId
                            AND prodCode__c = :p.prodCode];
        s.selectedPackaging__c = p.selectedPackaging;
        update s;
    }

    /**
     * Updates the selectedPackaging__c for a Seleccion__c 
     */
    public static void updateSelectionComment(ProductoPedidoCatalogo p, String cId) {
        Seleccion__c s = [SELECT Id
                            FROM Seleccion__c
                            WHERE Catalogo__c = :cId
                            AND prodCode__c = :p.prodCode];
        s.Comments__c = p.comments;
        update s;
    }


    /**
     * Deletes all Seleccion__c instances linked to Catalogo__c with id = cId
     */
    public static void clearSelection(String cId) {
        delete [SELECT Id
                            FROM Seleccion__c
                            WHERE Catalogo__c = :cId];
    }
}