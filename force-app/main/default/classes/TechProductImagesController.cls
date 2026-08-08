public with sharing class TechProductImagesController {

    @AuraEnabled
    public static void saveImages(Id recordId, String onedriveLink, String img1, String img2, String img3, String img4) {
        try {
            Product2 prod = new Product2(Id = recordId);
            if (onedriveLink != null) {
                if (onedriveLink.length() > 255) {
                    throw new AuraHandledException('El enlace de OneDrive es demasiado largo (máximo 255 caracteres). Por favor, utiliza un enlace más corto o un acortador de URLs.');
                }
                prod.Tech_Enlace_OneDrive__c = onedriveLink;
            }
            
            // Helper to save attachment and return Id
            if (img1 != null && img1.length() > 0) prod.IDImagen1__c = saveAttachment(recordId, 'Imagen1.jpg', img1);
            if (img2 != null && img2.length() > 0) prod.IDImagen2__c = saveAttachment(recordId, 'Imagen2.jpg', img2);
            if (img3 != null && img3.length() > 0) prod.IDImagen3__c = saveAttachment(recordId, 'Imagen3.jpg', img3);
            if (img4 != null && img4.length() > 0) prod.IDImagen4__c = saveAttachment(recordId, 'Imagen4.jpg', img4);
            
            update prod;
        } catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
    }

    private static Id saveAttachment(Id parentId, String name, String base64Data) {
        // Remove data:image/...;base64, prefix if present
        if (base64Data.contains(',')) {
            base64Data = base64Data.substringAfter(',');
        }
        Attachment att = new Attachment();
        att.ParentId = parentId;
        att.Name = name;
        att.Body = EncodingUtil.base64Decode(base64Data);
        att.ContentType = 'image/jpeg';
        insert att;
        return att.Id;
    }
}