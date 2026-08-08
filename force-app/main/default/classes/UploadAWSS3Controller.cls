public class UploadAWSS3Controller {
    public String idProduct {set; get;}
    public Product2 product {set; get;}
    public Boolean errorImage {set; get;}
    private Document image;
    public String nameImageToUpload {set; get;}
    public String messageResultUpload {set; get;}

    public UploadAWSS3Controller(ApexPages.StandardController stdController) {
        List<Product2> products;
        Integer sizeImage;
        errorImage = false;

        idProduct = stdController.getId();

        products = [SELECT Id,
                           Name, 
                           IDImagen1__c,
                           Imagen1__c,
                           ProductCode,
                           IsActive
                      FROM Product2
                      WHERE Id = :idProduct];

        if(products.size() > 0) {
            product = products.get(0);
        }
        System.debug('uplado images size soql [' + products.size() + ']');
        if(product != null) {
            System.debug('idm[' + idProduct + '] ido[' + product.Id + '] idimg[' + product.IDImagen1__c + '] img[' + product.Imagen1__c + ']');
            if(product.IDImagen1__c != null) {
                image = [SELECT Id, 
                                Name, 
                                Body, 
                                BodyLength, 
                                FolderId, 
                                Type 
                           FROM Document 
                          WHERE FolderId = '00l4w000001zx52AAA' 
                            AND Id = :product.IDImagen1__c];
                            //AND Id = '015780000008yap'];
      
                System.debug('image id[' + image.Id + '] name[' + image.Name + '] bodyLength[' + image.BodyLength + '] type[' + image.Type + ']');
                sizeImage = image.BodyLength;
                if(sizeImage >= 1000000) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'La imagen tiene un tamaño mayor o igual a 1 MB'));
                    errorImage = true;
                } else {
                    if(image.Name != null || image.Name == '' || image.Name.length() < 7) {
                        nameImageToUpload = image.Name.substring(0, 7);
                    } else {
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'La imagen no tiene nombre o el nombre es incorrecto'));
                        errorImage = true;
                    }
                }                
            } else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Producto no tiene imagen'));
                errorImage = true;
            }
        }

    }

    public PageReference uploadImage() {
        PageReference newPage;

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
                      AWS_S3_Host__c
                 FROM AWS_Generacion_Cotizacion__mdt 
                WHERE MasterLabel = 'AWSCotizacion'];
  
        if(mdt != null) {
            FileAWSS3Uploader.uploadImage(mdt.AWS_Key__c, mdt.AWS_Secret__c, mdt.AWS_S3_Bucket_Name__c, mdt.AWS_S3_Host__c, nameImageToUpload, 'images', image.Body);
        }
        messageResultUpload = 'Imagen registrada correctamente';
        newPage = new PageReference('/apex/UploadProdImageAWSS3Result');
        return newPage;
    }    

}