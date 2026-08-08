public class SFAmazonInfoLoader {
    public Map<String, ProductImage> mapProductsImage;
    List<String> idsImages;
    List<Document> imageInfoList;

    public SFAmazonInfoLoader() {

    }

    public void getInformationProductImage() {
        List<Product2> products;
        mapProductsImage = new Map<String, ProductImage>();
        idsImages = new List<String>();
        ProductImage prodImage;

        products = [SELECT Id, 
                           Name, 
                           ProductCode, 
                           IDImagen1__c 
                      FROM Product2 
                     WHERE IDImagen1__c != null 
                       AND ProductCode != null 
                  ORDER BY IDImagen1__c];

        for(Product2 prod : products) {
            prodImage = new ProductImage(prod, prod.IDImagen1__c);
            mapProductsImage.put(prod.IDImagen1__c, prodImage);
            idsImages.add(prod.IDImagen1__c);
        }


        imageInfoList = [SELECT Id, 
                                Name, 
                                BodyLength, 
                                Folderid, 
                                Type 
                           FROM Document 
                          WHERE FolderId = '00l46000000I4dX' 
                            AND Id IN :idsImages];

        for(Document d : imageInfoList) {
            prodImage = mapProductsImage.get(d.Id);
            if(prodImage != null) {
                prodImage.imageName = d.Name;
                prodImage.sizeImage = d.BodyLength;
            }
        }

        for(String key : mapProductsImage.keySet()) {
            prodImage = mapProductsImage.get(key);
            System.debug(prodImage.product.Id + ',' + prodImage.product.Name + ',' + prodImage.product.ProductCode + ',' + prodImage.imageName + ',' + prodImage.sizeImage);
        }
    }


    class ProductImage {
        public String idImage {set; get;}
        public Product2 product {set; get;}
        public String imageName {set; get;}
        public Integer sizeImage {set; get;}
        
        public ProductImage(Product2 pproduct, String idImg) {
            product = pproduct;
            idImage = idImg;
        }

        
    }
}