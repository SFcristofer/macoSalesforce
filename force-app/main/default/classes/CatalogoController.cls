public class CatalogoController {
    public static final String PARAM_FAMILIA = 'fam';
    public static final String PARAM_SUBFAMILIA = 'sfm';
    public static final String PARAM_CLASE = 'cla';
    public static final String PARAM_PROD = 'pro';
    public static final String KEY_ACCOUNT = 'Key Account';
    public static final String PCODE = 'pCode';
    public static final String PSEL = 'pSel';
    public static final String CMM = 'cmm';

    public Catalogo__c catalogo {set; get;}
    public Catalogo catalogoGUI {set; get;}
    
    public ProductCatalogueWrapper productoWrapper {set; get;}
    private Map<String, List<String>> mapaFamiliaSubfamilia;
    private Map<String, List<String>> mapaSubfamiliaClase;
    private List<Catalogo_FSC__mdt> catalogosMDTF;
    private List<Catalogo_FSC__mdt> catalogosMDTSF;
    private List<Catalogo_FSC__mdt> catalogosMDCL;
    public String selectedFamily {set; get;}
    public String selectedSubFamily {set; get;}
    public String selectedClase {set; get;}
    public String selectedProd {set; get;}

    public String styleCartHref {set; get;}
    public String styleCartSpan {set; get;}    
    public String numberProductsCart {set; get;}
    public PedidoCatalogo pedidoCatalogo {set; get;}

    public static String UNAVAILABLE_TOKEN = Label.PORTAL_UNAVAILABLE_TOKEN;
    public static String INVALID_TOKEN = Label.PORTAL_INVALID_TOKEN;

    public Boolean showPage {set; get;}
    
    public Boolean alreadyAdded {get;set;}
    public Map<String, Boolean> addedProducts {get;set;}
    
    public Integer numOppsCatalogo;
    private Pricebook2 listaPrecios;

    public CatalogoController() {
        List<Product2> productosSeleccionados;
        String jsonString;
        styleCartHref = '';  
        styleCartSpan = '';
        numberProductsCart = '';

        showPage = true;
        alreadyAdded = false;
        
        selectedFamily = Apexpages.currentPage().getParameters().get(PARAM_FAMILIA);
        selectedSubFamily = Apexpages.currentPage().getParameters().get(PARAM_SUBFAMILIA);
        selectedClase = Apexpages.currentPage().getParameters().get(PARAM_CLASE);
        selectedProd = Apexpages.currentPage().getParameters().get(PARAM_PROD);
        
        System.debug('selected prod[' + selectedProd + ']');

        Cookie cookieIdCatalogo = ApexPages.currentPage().getCookies().get('ctgtkn');
        if(cookieIdCatalogo != null) {
            pedidoCatalogo = CatalogueOrderPersistenceHandler.fetchPedidoCatalogo(cookieIdCatalogo.getValue());
            numberProductsCart = String.valueOf(pedidoCatalogo.productos.size());
            if(pedidoCatalogo.productos.size() > 0) {
                //TO-DO move this to the page(s)
                styleCartHref = 'color: #0D247D;';
                styleCartSpan = 'background-color: #089EBA; color: #fff; text-align: center; border-radius: 100px; font-size: 0.625rem; line-height: 1rem; width: 1rem; position: absolute; margin-top: -32px; margin-left: 12px;';
            }
        } else {
            pedidoCatalogo = new PedidoCatalogo();
        }

        listaPrecios = DOBrandsDAO.getListaPrecios(KEY_ACCOUNT);

        buildAddedProductsMap();
        if(selectedFamily == null) {
            load('Familia', '', '', '');
        } else if(selectedFamily != null && selectedSubFamily == null) {
            load('Subfamilia', selectedFamily, '', selectedFamily);
        } else if(selectedFamily != null && selectedSubFamily != null && selectedProd == null) {
            load('Clase', selectedSubFamily, selectedFamily, selectedClase);
            for(Product2 p : catalogoGUI.productos) {
                if(!addedProducts.containsKey(p.ProductoBase__r.productCode)) {
                    addedProducts.put(p.ProductoBase__r.productCode, false);
                }
            }
        } else if(selectedProd != null) {
            loadProducto(selectedProd, selectedSubFamily, selectedFamily, selectedClase);
            if(addedProducts.containsKey(selectedProd)) {
                alreadyAdded = true;
            }
        }

    }

    public void loadProducto(String cveProd, String cveFam, String cveSubfam, String cveClase) {
        List<Product2> prods;
        List<String> cvesProductos = new List<String>();
        cvesProductos.add(cveProd);
        prods = DOBrandsDAO.getProductsByProductCode(cvesProductos);
        System.debug('prodsssss [' + prods + ']');
        if(prods != null && !prods.isEmpty()) {
            productoWrapper = new ProductCatalogueWrapper(prods.get(0));
            load('Producto', cveFam, cveSubfam, cveClase);
        }
    }

    public void load(String tipo, String cveInmediato, String cvePadre, String cveActual) {
        String clases;
        mapaFamiliaSubfamilia = Util.getFieldDependencies('Product2', 'Family', 'Subfamilia__c');
        mapaSubfamiliaClase = Util.getFieldDependencies('Product2', 'Subfamilia__c', 'Clase__c');
        
        Cookie cookieIdCatalogo = ApexPages.currentPage().getCookies().get('ctgtkn');
        String portalToken = ApexPages.CurrentPage().getparameters().get('dbrToken');
        
        System.debug('portalToken [' + portalToken + ']');

        if(portalToken != null) {
            catalogo = DOBrandsDAO.getCatalogoByToken(portalToken);
            if(catalogo == null) {
                showPage = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVALID_TOKEN));
            } else {
                System.debug('LOADDDD  catalogo.Id [' + catalogo.Id + '] cliente[' + catalogo.Cliente__c + ']');
                cookieIdCatalogo = new Cookie('ctgtkn', portalToken, null, -1, true);
                ApexPages.currentPage().setCookies(new Cookie[]{cookieIdCatalogo});
            }
        }

        if(cookieIdCatalogo != null) {
            portalToken = cookieIdCatalogo.getValue();
            if(catalogo == null) {
                catalogo = DOBrandsDAO.getCatalogoByToken(portalToken);
            }
            clases = catalogo.Clases__c;
            catalogosMDTF = DOBrandsDAO.getCatalogosFSCMetadatos('Familia', '', '');        

            if(tipo.equals('Subfamilia')) {
                catalogosMDTSF = DOBrandsDAO.getCatalogosFSCMetadatos(tipo, cveInmediato, cvePadre);
            }

            if(tipo.equals('Clase') || tipo.equals('Producto')) {
                catalogosMDTSF = DOBrandsDAO.getCatalogosFSCMetadatos('Subfamilia', cvePadre, '');
                catalogosMDCL = DOBrandsDAO.getCatalogosFSCMetadatos('Clase', cveInmediato, cvePadre);
            }

            catalogoGUI = buildCatalogo(clases, tipo, cveInmediato, cvePadre, cveActual);
        } else {
            showPage = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVALID_TOKEN));
        }

        if(catalogo != null) {
            numOppsCatalogo = DOBrandsDAO.getCountOpportunitiesByCatalog(catalogo.Id);
        }
    }

    public Catalogo buildCatalogo(String catalogoClases, String tipo, String cveInmediato, String cvePadre, String cveActual) {
        String[] tokensClases;
        Catalogo catalogo = new Catalogo(catalogosMDTF, catalogosMDTSF, catalogosMDCL, mapaFamiliaSubfamilia, mapaSubfamiliaClase, listaPrecios.currencyIsoCode);
        tokensClases = catalogoClases.split(',');
        if(tokensClases != null && !tokensClases.isEmpty()) {
            for(String token : tokensClases) {
                if(token.length() == 4) {
                    catalogo.addFSCItem(token, tipo, cveInmediato, cvePadre, cveActual);
                }
            }
        }
        if(tipo == 'Clase' || tipo == 'Producto') {
            catalogo.currentClassPrefix = cveActual;
        }
        catalogo.buildCatalogo();

        return catalogo;
    }

    public void addToCartFromList() {
        List<Product2> prods = DOBrandsDAO.getProductsByProductCode(new List<String>{selectedProd});
        if(!prods.isEmpty()) {
            productoWrapper = new ProductCatalogueWrapper(prods.get(0));
        }
        addToCart();
    }

    public void addToCart() {
        String jsonString;
        ProductoPedidoCatalogo ppc;
        
        if(productoWrapper == null) {
            return;
        }

        if(productoWrapper.product == null) {
            return;
        }
        
        ppc = new ProductoPedidoCatalogo();
        ppc.prodId = productoWrapper.product.Id;
        ppc.prodCode = productoWrapper.product.ProductoBase__r.ProductCode;
        // Usar ProductName__c (inglés) en lugar de Name (español)
        ppc.prodName = productoWrapper.product.ProductoBase__r.ProductName__c;
        ppc.prodFamPrefix = productoWrapper.product.ProductoBase__r.Family.left(1);
        ppc.prodSfmPrefix = productoWrapper.product.ProductoBase__r.Subfamilia__c.left(1);
        ppc.prodClaPrefix = productoWrapper.product.ProductoBase__r.Clase__c.left(2);
        ppc.prodMeasures = productoWrapper.product.ProductoBase__r.Medidas_Agrupadas__c;
        ppc.prodImageId = productoWrapper.product.ProductoBase__r.IDImagen1__c;
        // Guardar ambos campos por si en el futuro se utilizan
        ppc.prodColor = productoWrapper.product.ProductoBase__r.Color__c;
        ppc.prodMaterial = productoWrapper.product.ProductoBase__r.Material__c;
        ppc.setDefaultPackaging(productoWrapper.product.ProductoBase__r.Packaging__c);
        ppc.comments = productoWrapper.prodComments;
        
        pedidoCatalogo.productos.add(ppc);
        //insert to the db
        CatalogueOrderPersistenceHandler.insertNewSelection(ppc, pedidoCatalogo.numeroPedido);

        styleCartHref = 'color: #0D247D;';
        styleCartSpan = 'background-color: #089EBA; color: #fff; text-align: center; border-radius: 100px; font-size: 0.625rem; line-height: 1rem; width: 1rem; position: absolute; margin-top: -32px; margin-left: 12px;';
            
        numberProductsCart = String.valueOf(pedidoCatalogo.productos.size());
        alreadyAdded = true;
    }

    public PageReference enviarCotizacion() {
        Opportunity opp;

        PageReference newPage;
        String jsonString;
        Datetime timeNow = System.now();
        List<String> codProds;
        List<String> idsProduct = new List<String>();
        Map<String, PriceBookEntry> mapProductPricebook;
        List<ProductoPedidoCatalogo> prodsCatalogFinal;
        String notValidproducts;
        Map<String, Product2> prods;
        OpportunityLineItem opli;
        List<OpportunityLineItem> listOpl;
        PlanificacionComercial__c planificiacion;
        String oppName;
        PriceBookEntry pbe;
        
        codProds = new List<String>();
        listOpl = new List<OpportunityLineItem>();
        prodsCatalogFinal = new List<ProductoPedidoCatalogo>();
        notValidproducts = '';

        for(ProductoPedidoCatalogo ppc : pedidoCatalogo.productos) {
            codProds.add(ppc.prodCode);
            idsProduct.add(ppc.prodId);
        }

        mapProductPricebook = DOBrandsDAO.getMapProductsPriceBook(idsProduct, 'Key Account', listaPrecios.CurrencyISOCode);
        for(ProductoPedidoCatalogo ppc : pedidoCatalogo.productos) {
            if(mapProductPricebook.containsKey(ppc.prodId)) {
                prodsCatalogFinal.add(ppc);
            } else {
                notValidproducts = notValidproducts + ' ' + ppc.prodName + ' [' + ppc.prodCode + '] no válido\n';
            }
        }

        planificiacion = DOBrandsDAO.getPlanificacion(String.valueOf(Date.today().year()), catalogo.Cliente__c);
       
        if(numOppsCatalogo == 0) {
            oppName = catalogo.name;
        } else {
            oppName = catalogo.name + '- ' + (numOppsCatalogo + 1);
        }
         
        opp = new Opportunity(Name = oppName,
                              AccountId = catalogo.Cliente__c,
                              StageName = 'Toma de Contacto',
                              CloseDate = Date.today(),
                              Is_Brand_Selected__c = false,
                              Opportunidad_catalogo__c = true,
                              Campana__c = 'Primera Compra',
                              Productos_No_Validos__c = notValidproducts,
                              Catalogo__c = catalogo.Id,
                              Pricebook2Id = listaPrecios.Id,
                              PlanificacionComercial__c = planificiacion != null ? planificiacion.Id : null);

        insert opp;

        System.debug('op iso code [' + opp.Id + '] [' + listaPrecios.CurrencyIsoCode + ']');

        for(ProductoPedidoCatalogo p : prodsCatalogFinal) {
            pbe = mapProductPricebook.get(p.prodId);

            opli = new OpportunityLineItem( Quantity = 1,
                                            // Mantener Color__c por compatibilidad
                                            Color__c = p.prodColor,
                                            OpportunityId = opp.Id,
                                            Product2Id = p.prodId,
                                            TotalPrice = 1,
                                            Aportaciones_2__c = planificiacion != null ? planificiacion.PorcentajeAportaciones__c : null,
                                            Convenio_2__c = planificiacion != null ? planificiacion.PorcentajeConvenio__c : null,
                                            PricebookEntryId = pbe.Id,
                                            ComentariosCatalogo__c = '');
            if(p.selectedPackaging != p.prodPackaging) {
                opli.ComentariosCatalogo__c += 'SOLICITA PACKAGING DIFERENTE: [' + p.selectedPackaging + '] ';
                opli.ComentarioPackagingNuevo__c = p.selectedPackaging;
                opli.RequierePackagingNuevo__c = true;
            }
            if(p.comments != null && p.comments != '') {
                opli.ComentariosCatalogo__c += p.comments;
            }
            
            if(opli.ComentariosCatalogo__c != null && opli.ComentariosCatalogo__c != '') {
                opli.Comentario_atendido__c = false;
            }

            listOpl.add(opli);
        }

        insert listOpl;
        CatalogueOrderPersistenceHandler.clearSelection(pedidoCatalogo.numeroPedido);
        newPage = new PageReference('/portal/CatalogueReady');
        return newPage;
    }


    public PageReference deleteProductFromCart() {
        PageReference newPage;
        String jsonString;
        PedidoCatalogo pc;
        ProductoPedidoCatalogo ppc;

        String passedParam1 = Apexpages.currentPage().getParameters().get('selectedDeleteProduct');

        deleteItemFromCart(passedParam1);

        return null;
    }

    public void deleteItemFromCart(String prodCode) {
        //delete Seleccion__c
        CatalogueOrderPersistenceHandler.deleteSelection(pedidoCatalogo.numeroPedido, prodCode);
        //re-fetch PedidoCatalogo
        pedidoCatalogo = CatalogueOrderPersistenceHandler.fetchPedidoCatalogo(pedidoCatalogo.token);

        if(pedidoCatalogo.productos.size() > 0) {
            numberProductsCart = String.valueOf(pedidoCatalogo.productos.size());
        } else {
            styleCartHref = '';  
            styleCartSpan = '';
            numberProductsCart = '';
        }

    }

    public void removeFromCart() {
        if(productoWrapper == null) {
            return;
        }
        
        if(productoWrapper.product == null) {
            return;
        }
        
        deleteItemFromCart(productoWrapper.product.ProductoBase__r.ProductCode);
        alreadyAdded = false;
    }

    private void buildAddedProductsMap() {
        addedProducts = new Map<String, Boolean>();
        for(ProductoPedidoCatalogo p : pedidoCatalogo.productos) {
            addedProducts.put(p.prodCode, true);
        }
    }

    /**
     * Changes the selected packaging for a product updating the Seleccion__c instance
     */
    public void changePackaging() {
        String pCode = Apexpages.currentPage().getParameters().get(PCODE);
        String selPackaging = Apexpages.currentPage().getParameters().get(PSEL);
        for(ProductoPedidoCatalogo p : pedidoCatalogo.productos) {
            if(p.prodCode == pCode) {
                p.selectedPackaging = selPackaging;
                CatalogueOrderPersistenceHandler.updateSelectionPackaging(p, pedidoCatalogo.numeroPedido);
            }
        }

    }

    /**
     * Changes the comment for a product updating the Seleccion__c instance
     */
    public void changeComment() {
        String pCode = Apexpages.currentPage().getParameters().get(PCODE);
        String comment = Apexpages.currentPage().getParameters().get(CMM);
        for(ProductoPedidoCatalogo p : pedidoCatalogo.productos) {
            if(p.prodCode == pCode) {
                p.comments = comment;
                CatalogueOrderPersistenceHandler.updateSelectionComment(p, pedidoCatalogo.numeroPedido);
            }
        }

    }


    class ProductCatalogueWrapper {
        public Product2 product {set; get;}
        public String prodComments {set; get;}
        public String image1Display {set; get;}
        public String image2Display {set; get;}
        public String image3Display {set; get;}
        public String image4Display {set; get;}
        public ProductCatalogueWrapper(Product2 prod) {
            product = prod;
            image1Display = '';
            image2Display = '';
            image3Display = '';
            image4Display = '';
            if(product.ProductoBase__r.IDImagen1__c == null || product.ProductoBase__r.IDImagen1__c.equals('')) {
                image1Display = 'display:none';
            }
            if(product.ProductoBase__r.IDImagen2__c == null || product.ProductoBase__r.IDImagen2__c.equals('')) {
                image2Display = 'display:none';
            }
            if(product.ProductoBase__r.IDImagen3__c == null || product.ProductoBase__r.IDImagen3__c.equals('')) {
                image3Display = 'display:none';
            }
            if(product.ProductoBase__r.IDImagen4__c == null || product.ProductoBase__r.IDImagen4__c.equals('')) {
                image4Display = 'display:none';
            }
        }
    }

}