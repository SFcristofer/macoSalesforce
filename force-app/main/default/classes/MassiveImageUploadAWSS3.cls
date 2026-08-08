public class MassiveImageUploadAWSS3 {
    public Integer numRowsToBeUpload {get; set;}
    public Map<String, Product2> mapProds;
    public List<Product2> noImgProds;    

    private String awsKey;
    private String awsSecret;
    private String awsS3BucketName;
    private String awsS3Host;
    private String awsS3ImgDir;
    private String salesforceIdFolder;

    public MassiveImageUploadAWSS3(Integer rows) {
        numRowsToBeUpload = rows;
        readMetadataConfiguration();
        //awsS3ImgDir = 'images';
        //salesforceIdFolder = '00l4w000001zx52AAA';
    
    }


    public void resetUploadFlags() {
        List<Product2> products; 
        
        products = [SELECT Id, 
                           Name,
                           IDImagen1__c,
                           image_upladed_s3_result__c,
                           image_uploaded_s3__c
                      FROM Product2 
                     WHERE RecordType.DeveloperName = 'Producto'
                       AND image_uploaded_s3__c = True LIMIT 4000]; 
        
        for(Product2 p : products) {
            p.image_uploaded_s3__c = False;
            p.image_upladed_s3_result__c = null;
        }

        update products;
    }


    private void readMetadataConfiguration() {
        AWS_Generacion_Cotizacion__mdt mdt;
        mdt = [SELECT Id, 
                      MasterLabel,
                      DeveloperName,
                      Color_FOB_Price__c,
                      Numero_OLI__c,
                      AWS_URL_Base__c,
                      AWS_webcontext_name__c,
                      AWS_webpath__c,
                      AWS_call_method_name__c,
                      AWS_template_file__c,
                      AWS_S3_Bucket_Name__c,
                      AWS_S3_Region__c,
                      AWS_Secret__c,
                      AWS_Key__c,
                      AWS_S3_Host__c,
                      AWS_S3_Images__c,
                      Salesforce_Images_DirId__c
                 FROM AWS_Generacion_Cotizacion__mdt 
                WHERE MasterLabel = 'AWSCotizacion'];

        awsKey = mdt.AWS_Key__c;
        awsSecret = mdt.AWS_Secret__c;
        awsS3BucketName = mdt.AWS_S3_Bucket_Name__c;
        awsS3Host = mdt.AWS_S3_Host__c;
        awsS3ImgDir = mdt.AWS_S3_Images__c;
        salesforceIdFolder = mdt.Salesforce_Images_DirId__c;       
    }

    public void executeLoad() {
        //get N products
        List<Document> documents;

        if(awsKey == null || awsKey.equals('') || 
           awsSecret == null || awsKey.equals('') || 
           awsS3BucketName == null || awsS3BucketName.equals('') ||
           awsS3Host == null || awsS3Host.equals('')) {
            
            System.debug('Check values in AWS_Generacion_Cotizacion__mdt Metadata, aws key, aws secret, s3 bucket and s3 host should not be null or empty');
            return;
        }

        mapProds = fetchProducts();
        documents = fetchDocuments(mapProds);
        //upload products
        uploadImagesToAWSS3(documents);
        updateProducts(mapProds);
    }

    private void uploadImagesToAWSS3(List<Document> docs) {
        String nameImageToUpload;                    //nameImageToUpload = image.Name.substring(0, 7);
        for(Document d : docs) {
            nameImageToUpload = d.Name.substring(0, 7);
            FileAWSS3Uploader.uploadImage(awsKey, awsSecret, awsS3BucketName, awsS3Host, nameImageToUpload, awsS3ImgDir, d.Body);            
        }
    }


    private Map<String, Product2> fetchProducts() {
        Map<String, Product2> mapProducts = new Map<String, Product2>();
        List<Product2> products;

        noImgProds = new List<Product2>();
        
        if(numRowsToBeUpload == null || numRowsToBeUpload <= 0) {
            System.debug('Must specify a limit');
            return mapProducts;
        }

        products = [SELECT Id, 
                           Name,
                           IDImagen1__c,
                           image_upladed_s3_result__c,
                           image_uploaded_s3__c
                      FROM Product2 
                     WHERE RecordType.DeveloperName = 'Producto'
                       AND image_uploaded_s3__c = False LIMIT :numRowsToBeUpload];

        System.debug('UPLD IMG size prods [' + products.size() + ']');
        for(Product2 prod : products) {
            System.debug('UPLD IMG fetc prod [' + prod.Name + '] [' + prod.IDImagen1__c + ']');
            //prod.image_uploaded_s3__c = True;
            if(prod.IDImagen1__c == null) {
                prod.image_upladed_s3_result__c = 'NOIMG';
                prod.image_uploaded_s3__c = True;
                noImgProds.add(prod);
            } else {
                mapProducts.put(prod.IDImagen1__c, prod);
            }
        }

        return mapProducts;
    }

    private List<Document> fetchDocuments(Map<String, Product2> mapProds) {
        List<Document> docs;
        List<Document> docsToUpload;        
        List<String> prodImgs;
        Product2 prod;
        Integer sizeImage;        

        prodImgs = new List<String>();
        docsToUpload = new List<Document>();

        for(String idImg : mapProds.keySet()) {
            prod = mapProds.get(idImg);
            if(prod != null) {
                System.debug('UPLD IMG flag [' + prod.image_uploaded_s3__c + ']');
                if(prod.image_uploaded_s3__c == False) {
                    prod.image_uploaded_s3__c = True;                    
                    prodImgs.add(prod.IDImagen1__c);
                }
            }
        }
        System.debug('UPLD IMG size prods imgs [' + prodImgs.size() + ']');
        docs = [SELECT Id, 
                       Name, 
                       Body, 
                       BodyLength, 
                       FolderId, 
                       Type 
                  FROM Document 
                 //WHERE FolderId = '00l46000000I4dX' 
                 WHERE FolderId = :salesforceIdFolder
                   AND Id IN :prodImgs];

        for(Document d : docs) {
            prod = mapProds.get(d.Id);
            sizeImage = d.BodyLength;
            if(sizeImage >= 1000000) {
                if(prod != null) {
                    prod.image_upladed_s3_result__c = 'NASIZE';
                }
            } else {
                if(d.Name != null || d.Name == '' || d.Name.length() < 7) {
                    //nameImageToUpload = image.Name.substring(0, 7);
                    docsToUpload.add(d);
                } else {
                    if(prod != null) {
                        prod.image_upladed_s3_result__c = 'NANAME';
                    }
                }
            }                

        }
        
        return docsToUpload;
    }


    private void updateProducts(Map<String, Product2> mapProds) {
        Product2 prod;
        List<Product2> prodsToUpdate = new List<product2>();

        for(String idImg : mapProds.keySet()) {
            prod = mapProds.get(idImg);
            prodsToUpdate.add(prod);
        }
        update prodsToUpdate;
        
        update noImgProds;
    }

}