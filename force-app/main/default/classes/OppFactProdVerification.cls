public class OppFactProdVerification implements Comparable {
    public String idVerificacionCosto {set; get;}
    public String idVerificacionCostoProd {set; get;}
    public String idOpportunity {set; get;}
    public String idFactory {set; get;}
    public String idProduct {set; get;}
    public String idBaseProduct {set; get;}
    public Boolean isCostApproved {set; get;}

    public String oppName {set; get;}
    public String factoryName {set; get;}
    public String productName {set; get;}
    public String productCode {set; get;}
    public String productDescription {set; get;}
    public String englishProductDescription {set; get;}    
    public Integer oppRev {set; get;} 
    public Date fechaUltimaRevision {set; get;}
    public Integer diasVencimiento {set; get;}
    public Date fechaStatus {set; get;}

    public String imageInfo {set; get;}
    public String supplierCodeProduct {set; get;}
    public Decimal oldCostProduct {set; get;}
    public Decimal newCostProduct {set; get;}    
    public String estado {set; get;}
    
    public Integer numOps {set; get;}    

    public OppFactProdVerification() {
        numOps = 1;
    }


    public Integer compareTo(Object compareTo) {
        OppFactProdVerification compareToProd = (OppFactProdVerification)compareTo;

        if(oppName != null) {
            if(oppName > compareToProd.oppName) return 1;
            if(oppName < compareToProd.oppName) return -1;
            if(oppName.equals(compareToProd.oppName)) {
                if(factoryName > compareToProd.factoryName) return 1;
                if(factoryName < compareToProd.factoryName) return -1;
                if(factoryName.equals(compareToProd.factoryName)) {
                    if(productName > compareToProd.productName) return 1;
                    if(productName < compareToProd.productName) return -1;
                    if(productName.equals(compareToProd.productName)) return 0;
                }
            }
        } else {
            if(factoryName > compareToProd.factoryName) return 1;
            if(factoryName < compareToProd.factoryName) return -1;
            if(factoryName.equals(compareToProd.factoryName)) {
                if(productName > compareToProd.productName) return 1;
                if(productName < compareToProd.productName) return -1;
                if(productName.equals(compareToProd.productName)) return 0;
            }
        }

        return 0;
    }   

}