public class ProductCostVerification implements Comparable {
    public String idProduct {set; get;}
    public String idFactory {set; get;}    
    public Product2 product {set; get;}
    public String imageInfo {set; get;}
    public String compareType {set; get;}
    public String codigo {set; get;}
    public Date fechaRevision {set; get;}
    public Boolean isPrecioVigente {set; get;}
    public String plazoPreciosProveedor {set; get;}
    public String oppLineItemID {set; get;}
    public String descripcion {set; get;}
    public String englishDescription {set; get;}    
    public Integer daysValidCost {set; get;}
    public Boolean isMarkedForVerification {set; get;}
    public String colorBall {set; get;}
    public Integer orderColor {set; get;}
    public Boolean isSent {set; get;}    

    public ProductCostVerification(Product2 pprod) {
        product = pprod;
        idProduct = product.Id;
        isPrecioVigente = false;
        isSent = false;
    }

    public Integer compareTo(Object compareTo) {
        ProductCostVerification compareToProd = (ProductCostVerification)compareTo;
        if(compareType.equals('greenred')) {
            if (orderColor < compareToProd.orderColor) {
                return -1;
            }
            if (orderColor > compareToProd.orderColor) {
                return 1;
            }
            //if (isPrecioVigente == compareToProd.isPrecioVigente) {
            if (orderColor == compareToProd.orderColor) {
                if(product.Name.equals(compareToProd.product.Name)) return 0;
                if(product.Name > compareToProd.product.Name) return 1;
                return -1;
            }
            return 0;
        } else {

        }
        return 0;
    }
}