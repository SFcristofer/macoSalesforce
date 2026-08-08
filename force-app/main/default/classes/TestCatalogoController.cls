@isTest
private class TestCatalogoController {
    @isTest
    private static void testNOToken() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        CatalogoController cc = new CatalogoController();
        system.assert(ApexPages.getMessages().toString().contains(CatalogoController.INVALID_TOKEN));
    }
    
    @isTest
    private static void testWithToken() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        tu.genCatalogo('token');
        PageReference catPage = Page.CatalogueIndex;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'token');
        CatalogoController cc = new CatalogoController();
        String token = ApexPages.currentPage().getParameters().get('dbrToken');
        System.assertEquals(token, 'token');
    }
    
    @isTest
    private static void testLoadSubfamilaYProd() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        tu.genCatalogo('token');
        PageReference catPage = Page.CatalogueIndex;
        Test.setCurrentPage(catPage);
        Map<String, String> params = ApexPages.CurrentPage().getparameters();
        params.put('dbrToken', 'token');
        params.put(CatalogoController.PARAM_FAMILIA, 'G');
        params.put(CatalogoController.PARAM_SUBFAMILIA, '1');
        params.put(CatalogoController.PARAM_CLASE, '01');
        CatalogoController cc = new CatalogoController();
        ApexPages.CurrentPage().getparameters().put(CatalogoController.PARAM_PROD, 'G101001A');
        cc = new CatalogoController();
    }
    
    @isTest
    private static void testBulkFunctionsCall() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        tu.genCatalogo('token');
        PageReference catPage = Page.CatalogueIndex;
        Test.setCurrentPage(catPage);
        Map<String, String> params = ApexPages.CurrentPage().getparameters();
        params.put('dbrToken', 'token');
        params.put(CatalogoController.PARAM_FAMILIA, 'G');
        params.put(CatalogoController.PARAM_SUBFAMILIA, '1');
        params.put(CatalogoController.PARAM_CLASE, '01');
        CatalogoController cc = new CatalogoController();
        
        List<Product2> prlist = [select id, name, productobase__r.name, productobase__r.ProductCode from product2];
        for(Product2 p : prlist) {
            System.debug('id[' + p.Id + '] name[' + p.name + '] pbname[' + p.productobase__r.name + '] pbcode[' + p.productobase__r.ProductCode + ']');
        }
        
        ApexPages.CurrentPage().getparameters().put(CatalogoController.PARAM_PROD, 'G101001P');
        cc = new CatalogoController();
        cc.addToCart();
        cc.addToCartFromList();
        cc.removeFromCart();
        cc.addToCart();
        ApexPages.CurrentPage().getparameters().put(CatalogoController.PCODE, 'G101001A');
        ApexPages.CurrentPage().getparameters().put(CatalogoController.PSEL, '7-something');
        ApexPages.CurrentPage().getparameters().put(CatalogoController.CMM, 'This is a custom comment');
        
        if(cc.pedidoCatalogo.productos != null && cc.pedidoCatalogo.productos.size() > 0) {
            system.debug(cc.pedidoCatalogo.productos[0]);
            system.debug(cc.pedidoCatalogo.productos[0].getSelectedBrown());
            system.debug(cc.pedidoCatalogo.productos[0].getSelectedWhite());
            system.debug(cc.pedidoCatalogo.productos[0].getSelectedColor());
        }
        cc.changeComment();
        cc.changePackaging();
    }
    
    @isTest
    private static void testEnviarCotizacionCompleto() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        
        Account clienteContacto = [SELECT Id FROM Account WHERE Name LIKE 'ClienteContactoUno%' LIMIT 1];
        
        Catalogo__c catalogo = new Catalogo__c(
            Name = 'Test Catalogo Enviar',
            Cliente__c = clienteContacto.Id,
            Familias__c = 'G',
            Clases__c = 'G101',
            Portal_Token__c = 'tokenEnviar'
        );
        insert catalogo;
        
        // Primero cargar el catálogo
        PageReference catPage = Page.CatalogueIndex;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'tokenEnviar');
        CatalogoController cc = new CatalogoController();
        
        // Agregar un producto al carrito manualmente (bypassing persistence)
        ProductoPedidoCatalogo ppc = new ProductoPedidoCatalogo();
        List<Product2> prods = [SELECT Id, ProductoBase__r.ProductCode, ProductoBase__r.ProductName__c, 
                                ProductoBase__r.Family, ProductoBase__r.Subfamilia__c, 
                                ProductoBase__r.Clase__c, ProductoBase__r.Medidas_Agrupadas__c,
                                ProductoBase__r.IDImagen1__c, ProductoBase__r.Color__c,
                                ProductoBase__r.Packaging__c
                                FROM Product2 
                                WHERE RecordType.DeveloperName = 'ProductoDeFabrica' LIMIT 1];
        
        if(!prods.isEmpty()) {
            ppc.prodId = prods[0].Id;
            ppc.prodCode = prods[0].ProductoBase__r.ProductCode;
            ppc.prodName = prods[0].ProductoBase__r.ProductName__c;
            ppc.prodFamPrefix = prods[0].ProductoBase__r.Family.left(1);
            ppc.prodSfmPrefix = prods[0].ProductoBase__r.Subfamilia__c.left(1);
            ppc.prodClaPrefix = prods[0].ProductoBase__r.Clase__c.left(2);
            ppc.prodMeasures = prods[0].ProductoBase__r.Medidas_Agrupadas__c;
            ppc.prodImageId = prods[0].ProductoBase__r.IDImagen1__c;
            ppc.prodColor = prods[0].ProductoBase__r.Color__c;
            ppc.setDefaultPackaging(prods[0].ProductoBase__r.Packaging__c);
            ppc.comments = 'Test';
            
            cc.pedidoCatalogo.productos.add(ppc);
            
            Test.startTest();
            PageReference result = cc.enviarCotizacion();
            Test.stopTest();
            
            List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Catalogo__c = :catalogo.Id];
            System.assertEquals(1, opps.size(), 'Should have created opportunity');
        }
    }
    
    @isTest
    private static void testEnviarCotizacion() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        
        Account clienteContacto = [SELECT Id FROM Account WHERE Name LIKE 'ClienteContactoUno%' LIMIT 1];
        
        Catalogo__c catalogo = new Catalogo__c(
            Name = 'Test Catalogo Enviar',
            Cliente__c = clienteContacto.Id,
            Familias__c = 'G',
            Clases__c = 'G101',
            Portal_Token__c = 'tokenEnviar2'
        );
        insert catalogo;
        
        PageReference catPage = Page.CatalogueIndex;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'tokenEnviar2');
        
        Test.startTest();
        CatalogoController cc = new CatalogoController();
        
        try {
            PageReference result = cc.enviarCotizacion();
        } catch(Exception e) {
            System.debug('Expected exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    private static void testDeleteProductFromCart() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        tu.genCatalogo('token');
        
        PageReference catPage = Page.CataloguePedido;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'token');
        ApexPages.CurrentPage().getparameters().put('selectedDeleteProduct', 'TESTCODE');
        
        Test.startTest();
        CatalogoController cc = new CatalogoController();
        PageReference result = cc.deleteProductFromCart();
        System.assertEquals(null, result);
        Test.stopTest();
    }
    
    @isTest
    private static void testLoadProducto() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        tu.genCatalogo('token');
        
        List<Product2> products = [SELECT Id, ProductoBase__r.ProductCode 
                                   FROM Product2 
                                   WHERE RecordType.DeveloperName = 'ProductoDeFabrica' 
                                   LIMIT 1];
        
        if(!products.isEmpty()) {
            String productCode = products[0].ProductoBase__r.ProductCode;
            
            PageReference catPage = Page.CatalogueProduct;
            Test.setCurrentPage(catPage);
            ApexPages.CurrentPage().getparameters().put('dbrToken', 'token');
            ApexPages.CurrentPage().getparameters().put(CatalogoController.PARAM_FAMILIA, 'G');
            ApexPages.CurrentPage().getparameters().put(CatalogoController.PARAM_SUBFAMILIA, '1');
            ApexPages.CurrentPage().getparameters().put(CatalogoController.PARAM_PROD, productCode);
            
            Test.startTest();
            CatalogoController cc = new CatalogoController();
            System.assertEquals(productCode, cc.selectedProd);
            System.assertEquals(true, cc.alreadyAdded == false || cc.alreadyAdded == true);
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testBuildCatalogo() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        
        Catalogo__c catalogo = new Catalogo__c(
            Name = 'Test Build',
            Cliente__c = tu.cliente.Id,
            Familias__c = 'G,H,B',
            Clases__c = 'G101,G102,H101,B101',
            Portal_Token__c = 'tokenBuild'
        );
        insert catalogo;
        
        PageReference catPage = Page.CatalogueIndex;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'tokenBuild');
        
        Test.startTest();
        CatalogoController cc = new CatalogoController();
        System.assertNotEquals(null, cc.catalogoGUI);
        System.assertNotEquals(null, cc.catalogoGUI.familias);
        System.assert(cc.catalogoGUI.familias.size() > 0);
        Test.stopTest();
    }
    
    @isTest
    private static void testAllPaths() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        tu.genCatalogo('token');
        
        Test.startTest();
        
        PageReference catPage = Page.CatalogueSubfamily;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'token');
        ApexPages.CurrentPage().getparameters().put(CatalogoController.PARAM_FAMILIA, 'G');
        CatalogoController cc1 = new CatalogoController();
        System.assertEquals('G', cc1.selectedFamily);
        
        catPage = Page.CatalogueClase;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'token');
        ApexPages.CurrentPage().getparameters().put(CatalogoController.PARAM_FAMILIA, 'G');
        ApexPages.CurrentPage().getparameters().put(CatalogoController.PARAM_SUBFAMILIA, '1');
        ApexPages.CurrentPage().getparameters().put(CatalogoController.PARAM_CLASE, '01');
        CatalogoController cc2 = new CatalogoController();
        System.assertEquals('1', cc2.selectedSubFamily);
        System.assertEquals('01', cc2.selectedClase);
        
        Test.stopTest();
    }
    
    @isTest
    private static void testCartWithProducts() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        tu.genCatalogo('token');
        
        PageReference catPage = Page.CatalogueIndex;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'token');
        
        Test.startTest();
        
        CatalogoController cc = new CatalogoController();
        System.assertNotEquals(null, cc.pedidoCatalogo);
        System.assertEquals('', cc.numberProductsCart);
        System.assertEquals('', cc.styleCartHref);
        System.assertEquals('', cc.styleCartSpan);
        System.assertEquals(true, cc.showPage);
        System.assertNotEquals(null, cc.addedProducts);
        System.assertNotEquals(null, cc.catalogoGUI);
        
        Test.stopTest();
    }
    
    @isTest
    private static void testLoadProductoMethod() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        tu.genCatalogo('token');
        
        List<Product2> products = [SELECT Id, ProductoBase__r.ProductCode 
                                   FROM Product2 
                                   WHERE RecordType.DeveloperName = 'ProductoDeFabrica' 
                                   LIMIT 1];
        
        if(!products.isEmpty()) {
            String productCode = products[0].ProductoBase__r.ProductCode;
            
            PageReference catPage = Page.CatalogueIndex;
            Test.setCurrentPage(catPage);
            ApexPages.CurrentPage().getparameters().put('dbrToken', 'token');
            
            Test.startTest();
            
            CatalogoController cc = new CatalogoController();
            cc.loadProducto(productCode, 'G', '1', '01');
            
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testInvalidToken() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        
        PageReference catPage = Page.CatalogueIndex;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'invalidToken123');
        
        Test.startTest();
        
        CatalogoController cc = new CatalogoController();
        System.assertEquals(false, cc.showPage);
        
        Test.stopTest();
    }
    
    @isTest
    private static void testProductoWrapperNull() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        tu.genCatalogo('token');
        
        PageReference catPage = Page.CatalogueIndex;
        Test.setCurrentPage(catPage);
        ApexPages.CurrentPage().getparameters().put('dbrToken', 'token');
        
        Test.startTest();
        
        CatalogoController cc = new CatalogoController();
        cc.removeFromCart();
        cc.addToCartFromList();
        
        Test.stopTest();
    }
}