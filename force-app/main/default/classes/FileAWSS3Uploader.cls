public class FileAWSS3Uploader {

    public static String uploadImage(String keyAws, 
                                     String secretAws,
                                     String bucketNameAws,
                                     String hostAws,
                                     String fileNameAws,
                                     String awsDirectory, 
                                     Blob fileBody) {


        System.debug('AWS S3 Upload Buckect CALL');
        System.debug('key[' + keyAws + '] secret[' + secretAws + '] bucket[' + bucketNameAws + '] host[' + hostAws + '] fileName[' + fileNameAws + '] awsDir[' + awsDirectory + ']');

        String attachmentBody = EncodingUtil.base64Encode(fileBody);
        String formattedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
        String key = keyAws; //AWS key
        String secret = secretAws; //AWS Secret key
        String bucketname = bucketNameAws; //AWS bucket name
        String host = hostAws;
        String method = 'PUT';
        String filename = fileNameAws;
        System.debug('FileName[' + filename + ']');
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint('https://' + bucketname + '.' + host + '/images/' + filename);
        req.setHeader('Host', bucketname + '.' + host);
        req.setHeader('Content-Length', String.valueOf(attachmentBody.length()));
        req.setHeader('Content-Encoding', 'UTF-8');
        //req.setHeader('Content-type', attach.ContentType);
        req.setHeader('Content-type', 'image/jpeg');
        //image/jpeg
        req.setHeader('Connection', 'keep-alive');
        req.setHeader('Date', formattedDateString);
        req.setHeader('ACL', 'public-read-write');
        req.setBodyAsBlob(fileBody);
        String stringToSign = 'PUT\n\n' + 'image/jpeg' + '\n' + formattedDateString + '\n' + '/' + bucketname + '/' + awsDirectory + '/' + filename;
        String encodedStringToSign = EncodingUtil.urlEncode(stringToSign, 'UTF-8');
        
        Blob mac = Crypto.generateMac('HMACSHA1', blob.valueof(stringToSign),blob.valueof(secret));
        String signedKey  = EncodingUtil.base64Encode(mac);
        String authHeader = 'AWS' + ' ' + key + ':' + signedKey ;
        req.setHeader('Authorization',authHeader);
        String decoded = EncodingUtil.urlDecode(encodedStringToSign , 'UTF-8');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('res: ' + res);
        
        return res.getBody();
    }
}


//Document attach = [select id, name, body, bodylength, folderid, type from document where folderid = '00l46000000I4dX' and id = '015780000008yap'];