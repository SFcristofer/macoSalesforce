public with sharing class TechOneDriveService {

    @AuraEnabled
    public static List<String> getFolderThumbnails(String sharedLink) {
        if (String.isBlank(sharedLink)) {
            return new List<String>();
        }

        try {
            // Encode the sharing URL as per Microsoft Graph API requirements
            String base64Value = EncodingUtil.base64Encode(Blob.valueOf(sharedLink));
            String encodedUrl = 'u!' + base64Value.replace('=', '').replace('/', '_').replace('+', '-');

            HttpRequest req = new HttpRequest();
            // Fetch children of the shared folder and expand thumbnails
            req.setEndpoint('callout:OneDrive_API/v1.0/shares/' + encodedUrl + '/driveItem/children?$select=id,name&$expand=thumbnails');
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json');
            req.setTimeout(10000); // 10 seconds max

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                List<String> imageUrls = new List<String>();
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> values = (List<Object>) responseMap.get('value');
                
                if (values != null) {
                    for (Object valObj : values) {
                        Map<String, Object> item = (Map<String, Object>) valObj;
                        if (item.containsKey('thumbnails')) {
                            List<Object> thumbnails = (List<Object>) item.get('thumbnails');
                            if (thumbnails != null && !thumbnails.isEmpty()) {
                                Map<String, Object> firstThumbnailSet = (Map<String, Object>) thumbnails[0];
                                // Get 'large' or 'medium' thumbnail
                                if (firstThumbnailSet.containsKey('large')) {
                                    Map<String, Object> largeThumb = (Map<String, Object>) firstThumbnailSet.get('large');
                                    imageUrls.add((String) largeThumb.get('url'));
                                } else if (firstThumbnailSet.containsKey('medium')) {
                                    Map<String, Object> mediumThumb = (Map<String, Object>) firstThumbnailSet.get('medium');
                                    imageUrls.add((String) mediumThumb.get('url'));
                                }
                            }
                        }
                    }
                }
                return imageUrls;
            } else {
                throw new CalloutException('Error API Microsoft: ' + res.getStatus() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage('Error: ' + e.getMessage());
            throw ahe;
        }
    }
}
