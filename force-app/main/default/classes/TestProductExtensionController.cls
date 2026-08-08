@isTest
public class TestProductExtensionController
{

    public static testMethod void testMyController() 
    { 
        List<Product2> listProducts = null;
        Opportunity opp = null;
        Product2 prodClicked = null;
        
        String prodSearch = 'La';
        
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();  
        
        opp = tu.getOpportunity();
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(opp);
        
        System.debug('test opp id [' + opp.id + ']');
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        ProductExtensionController controller = new ProductExtensionController(stdCtrl);

        controller.previousPage();
        
        listProducts = controller.getProductList();
        System.debug('list size[' + listProducts.size() + ']');
        for(Product2 prod : listProducts)
        {
            System.debug('prodName [' + prod.Name + '] []');
        }
        
        //system.assertEquals(listProducts.size(), 2);

        System.debug('has next[' + controller.hasNext + ']');
        system.assertEquals(controller.hasNext, false);
        
        System.debug('has previous[' + controller.hasPrevious + ']');
        system.assertEquals(controller.hasPrevious, false);

        controller.prodSearch = prodSearch;
        controller.searchProducts();
        System.debug('search[' + controller.getProductList().size() + ']');
        
        //system.assertEquals(controller.getProductList().size(), 1);
        
        prodClicked = controller.getProductList().get(0);
        
        controller.findProductById(prodClicked.id);
        
        System.debug('pageNumber[' + controller.pageNumber + ']');
        
        controller.previous();
        controller.next();

        System.debug('pageNumber[' + controller.getResultSize() + ']');
        
        controller.getCheckedProducts().put(prodClicked.id,true);

        System.debug('idProdClicked[' + prodClicked.id + ']');
        ApexPages.currentPage().getParameters().put('idProd', prodClicked.id);
        controller.clickProduct();
        
        controller.getSelectedProducts();
        
        controller.nextPage();
        
        controller.getHybridProducts();
        
        controller.saveOppLineItem();  
        
        controller.clickDeleteSelectedProduct();      
    }
}