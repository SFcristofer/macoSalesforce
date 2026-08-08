/**
*   Controller for UploadProdImages Page
*
*/

public class UploadProdImages{
    
    public list<ProdImage> prodImageList {get;set;}
    public Product2 product {get;set;}
    public static final String IMAGE_FOLDER = '00l4w000001zx52';
    public static String NO_IMAGE = '0154w0000242U1s';
    public static final String IMG1 = 'Imagen 1';
    public static final String IMG2 = 'Imagen 2';
    public static final String IMG3 = 'Imagen 3';
    public static final String IMG4 = 'Imagen 4';
    public Integer SIZE_IMAGE = 0;

    public AWS_Generacion_Cotizacion__mdt aws_mdt;
    
    public UploadProdImages(ApexPages.StandardController std) {
        String sizeImageValue;
        aws_mdt = [SELECT Id, 
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
                          Salesforce_Images_DirId__c,
                          Size_Image__c,
                          Id_Doc_Imagen_No_Disponible__c
                     FROM AWS_Generacion_Cotizacion__mdt 
                    WHERE MasterLabel = 'AWSCotizacion'];

        NO_IMAGE = aws_mdt.Id_Doc_Imagen_No_Disponible__c;
        sizeImageValue = aws_mdt.Size_Image__c;
        SIZE_IMAGE = Integer.valueOf(sizeImageValue);
        
        product = [SELECT Id,
                    ProductCode,
                    IdImagen1__c,
                    IdImagen2__c,
                    IdImagen3__c,
                    IdImagen4__c
                    FROM Product2
                    WHERE Id = :std.getId()];
        
        prodImageList = new list<ProdImage>();
        prodImageList.add(new ProdImage(product.IdImagen1__c, IMG1));
        prodImageList.add(new ProdImage(product.IdImagen2__c, IMG2));
        prodImageList.add(new ProdImage(product.IdImagen3__c, IMG3));
        prodImageList.add(new ProdImage(product.IdImagen4__c, IMG4));

    }
    
    // Save action method
    // change return type back to void if uploading more is required
    public PageReference saveChanges() {
        PageReference pageRef;
        String imageName;
        String nameImageToUpload;
        map<String, Document> docs = new map<String, Document>();
        for(ProdImage p : prodImageList){
            if(p.fileBody != null){
                String suffix = p.label.right(1) == '1' ? '' : '_' + p.label.right(1);
                imageName = product.ProductCode + suffix;
                System.debug('p.label [' + p.label + '] MaxsizeImage[' + SIZE_IMAGE + ']');
                docs.put(p.label, new Document( name = product.ProductCode + suffix,
                                                body = p.fileBody,
                                                folderId = aws_mdt.Salesforce_Images_DirId__c));
                if(aws_mdt != null && p.label.equals(IMG1)) {

                    if(imageName != null && imageName != '' && imageName.length() > 7) {
                        nameImageToUpload = imageName.substring(0, 7);
                        System.debug('image name [' + imageName + '] imgname t upld [' + nameImageToUpload + ']');
                        //if(p.fileBody != null && p.fileBody.size() >= 1000000) {
                        if(p.fileBody != null && p.fileBody.size() > SIZE_IMAGE) {                        
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'La imagen tiene un tamaño mayor a [' + SIZE_IMAGE + '] bytes'));
                            return pageRef;
                        }
                        FileAWSS3Uploader.uploadImage(aws_mdt.AWS_Key__c, 
                                                      aws_mdt.AWS_Secret__c, 
                                                      aws_mdt.AWS_S3_Bucket_Name__c, 
                                                      aws_mdt.AWS_S3_Host__c, 
                                                      nameImageToUpload, 
                                                      //'DELETEME',                                                       
                                                      aws_mdt.AWS_S3_Images__c, 
                                                      p.fileBody);
                    }
                }
            }
        }
        if(docs.values().size() > 0){
            insert docs.values();
        }
        for(String docLabel : docs.keySet()){
            if(docLabel == IMG1){
                product.IdImagen1__c = docs.get(docLabel).Id;
            } else if(docLabel == IMG2){
                product.IdImagen2__c = docs.get(docLabel).Id;
            } else if(docLabel == IMG3){
                product.IdImagen3__c = docs.get(docLabel).Id;
            } else if(docLabel == IMG4){
                product.IdImagen4__c = docs.get(docLabel).Id;
            }
        }
        if(docs.values().size() > 0){
            update product;
        }

        pageRef = new PageReference(ApexPages.currentPage().getUrl());
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    // Action method when the user is done
    public PageReference done(){
        // send the user to the detail page for the sobject
        return new PageReference('/' + product.Id);
    }


    public class ProdImage{
        public blob fileBody{get;set;}
        public String fileName{get;set;}
        public String existingImage{get;set;}
        public String label{get;set;}

        public ProdImage(String imageId, String imageLabel){
            existingImage = imageId;
            if(existingImage == null) {
                existingImage = NO_IMAGE;
            }
            label = imageLabel;
        }
    }
}