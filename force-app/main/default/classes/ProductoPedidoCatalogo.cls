public class ProductoPedidoCatalogo {
    public static final String BROWN = 'brown box';
    public static final String WHITE = 'white box';
    public static final String COLOR = 'color box';
    public String prodId {get; set;} //Factory Product Id
    public String prodCode {get; set;}
    public String prodName {get; set;}
    public String prodFamPrefix {get; set;}
    public String prodSfmPrefix {get; set;}
    public String prodClaPrefix {get; set;}
    public String prodMeasures {get; set;}
    public String prodPackaging {get; set;}
    public String prodImageId {get; set;}
    public String prodColor {get; set;}
    public String prodMaterial {get; set;} // Nuevo campo agregado
    public String comments {get; set;}
    public String selectedPackaging {get; set;}
    
    public ProductoPedidoCatalogo() {
    }
    
    /**
     * Converts the pack string into one of 
     */
    public void setDefaultPackaging(String pack) {
        if(pack == null || pack.contains('1-') || pack.contains('2-') || pack.contains('3-')) {
            prodPackaging = BROWN;
            selectedPackaging = BROWN;
        } else if (pack.contains('7-')) { 
            prodPackaging = WHITE;
            selectedPackaging = WHITE;
        } else {
            prodPackaging = COLOR;
            selectedPackaging = COLOR;
        }
    }
    
    public boolean getSelectedBrown() {
        return selectedPackaging == BROWN;
    }
    
    public boolean getSelectedWhite() {
        return selectedPackaging == WHITE;
    }
    
    public boolean getSelectedColor() {
        return selectedPackaging == COLOR;
    }
}