public class ProductBatchLibra {
    public static String ERROR_VALIDATION_PRODUCTS = 'No existen productos de fábrica';
    public static String ERROR_VALIDATION_FACTORY = 'no tiene fábrica asociada';
    public static String ERROR_VALIDATION_CODE = 'no tiene código rápido';
    public static String ERROR_VALIDATION_NO_PROFORMA = 'NO PROFORMA';

    public Product2 product {set; get;}
    public String sociedadIdentifier {set; get;}
    public String validationResult;
    private Map<String, Proforma__c> factoriesProforma;
    public List<Product2> baseProducts;

    public ProductBatchLibra(Product2 pproduct, String sociedad, Map<String, Proforma__c> mapFP) {
        product = pproduct;
        sociedadIdentifier = sociedad;
        validationResult = '';
        factoriesProforma = mapFP;
        baseProducts = new List<Product2>();
    }


    public Boolean validateProduct() {
        Boolean result = true;
        List<Product2> prodToSendLibra;
        Proforma__c proformaFactory;
        prodToSendLibra = product.FabricasDelProducto__r;
        if(prodToSendLibra == null || prodToSendLibra.isEmpty()) {
            validationResult = ERROR_VALIDATION_PRODUCTS + ' [' + product.Name + '] [' + product.Id + ']';
            return false;
        }
    
        for(Product2 prodBL : prodToSendLibra) {
            if(prodBL.Fabrica__r != null) {
                proformaFactory = factoriesProforma.get(prodBL.Fabrica__r.Id);
                if(proformaFactory == null) {
                    validationResult = validationResult + ERROR_VALIDATION_NO_PROFORMA + ' [' + prodBL.Fabrica__r.Id + '], ';
                    continue;
                } else {
                    baseProducts.add(prodBL);
                }
            }
            if(prodBL.Fabrica__r == null) {
                validationResult = validationResult + '[' + prodBL.Id + '] [' + prodBL.Name + '] ' + ERROR_VALIDATION_FACTORY + ', ';
                result = false;
            } else if (prodBL.Fabrica__r.Codigo_rapido__c == null) {
                validationResult = validationResult + 'Prod ID [' + prodBL.Id + '] [' + prodBL.Name + '] [' + prodBL.Fabrica__r.Name + '] ' + ERROR_VALIDATION_CODE + ', ';
                result = false;
            }
         }
         
         /*if(baseProducts.isEmpty()) {
             result = false;
         }*/
         return result;
     }

}