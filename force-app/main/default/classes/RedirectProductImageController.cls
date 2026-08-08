public class RedirectProductImageController{
    public RedirectProductImageController(){
     
    }
    
    public PageReference redirectToProductImage(){
        //Write your logic here and redirect
          PageReference retURL = new PageReference('https://cs66.salesforce.com/servlet/servlet.FileDownload?file=0150v000000DM4T');
          retURL.setRedirect(true);
          return retURL;
    }
}