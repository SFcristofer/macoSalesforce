public class ModificarProductosOportunidadController {
    transient private List<String> listFilter;
    public List<OPLIWrapper> oppLIWrapperList {set; get;}
    public Opportunity opp {set; get;}
    public String oliIdBrandChanged {set; get;}
    public String oliSelectedBrand {set; get;}
    public String idFactProdSelectedBrand {set; get;}    
    private Decimal opportunityMargen;
    private Decimal opportunityPorcentajeAportaciones;
    private Decimal opportunityPorcentajeConvenio;
    private Decimal conversionRate;

    public ModificarProductosOportunidadController(ApexPages.StandardController stdController) {
        Decimal costoProducto;
        Decimal listPrice;
        Decimal minimumPrice;
        Decimal costoPackaging;
        String idOpportunity;

        List<String> idsFactoryProduct;        
        ProductWrapper prodWrapper;
        OPLIWrapper oliWrapper;
        List<OpportunityLineItem> oppLineItems;
        List<ProductWrapper> productWrapperList;
     
        oppLIWrapperList = new List<OPLIWrapper>();
        listFilter = new List<String>();
        productWrapperList = new List<ProductWrapper>();
        idsFactoryProduct = new List<String>();

        System.debug('COOOOOOOOOONSTRUCTIR');
        idOpportunity = ApexPages.currentPage().getParameters().get('id');
        opp = DOBrandsDAO.getOpportunityMP(idOpportunity);

        opportunityMargen = opp.Pricebook2.Margen__c;
        opportunityPorcentajeAportaciones = opp.PlanificacionComercial__r.PorcentajeAportaciones__c;
        opportunityPorcentajeConvenio = opp.PlanificacionComercial__r.PorcentajeConvenio__c;
        conversionRate = CurrencyUtil.getRate(opp.CurrencyIsoCode);

        if(opp != null) {
            oppLineItems = opp.OpportunityLineItems;
        }

        for(OpportunityLineItem oppli : oppLineItems) {
            if(oppli.Producto_Packaging__c != null) {
                costoPackaging = oppli.Producto_Packaging__r.CostoPackaging__c;
            } else {
                costoPackaging = oppli.Product2.CostoPackaging__c;
            }

            costoProducto = (oppli.Product2.PrecioDeFabrica__c + oppli.Product2.CostoImportacionUnidad__c  + costoPackaging) * conversionRate;

            System.debug('[' + oppli.Product2.PrecioDeFabrica__c + '] [' + costoPackaging + '] [' + oppli.Product2.CostoImportacionUnidad__c + '] [' + conversionRate + ']');

            listPrice = costoProducto / (1 - (opportunityMargen / 100));
            System.debug('[' + listPrice + '] [' + opportunityMargen + ']');
            minimumPrice = listPrice / ( 1 - (opportunityPorcentajeAportaciones + opportunityPorcentajeConvenio + oppli.Porcentaje_Item__c) / 100);
            System.debug('[' + opportunityPorcentajeAportaciones + '] [' + opportunityPorcentajeConvenio + '] [' + oppli.Porcentaje_Item__c + ']');            
            oppli.Precio_Minimo__c = minimumPrice;

            listFilter.add(oppli.Product2.CodigoDeProductoBase__c.substring(0,7) + '%');
            oliWrapper = new OPLIWrapper(oppli);
            oppLIWrapperList.add(oliWrapper);
        }
        
        List<Product2> prods = [SELECT Id, 
                                       Name, 
                                       ProductCode, 
                                       CodigoDeProductoBase__c, 
                                       Marca2__c,
                                       Packaging__c,
                                       PrecioDeFabrica__c,
                                       ProductoBase__r.IDImagen1__c,
                                       ProductoBase__r.Imagen1__c,
                                       IDImagen1__c,
                                       RecordType.DeveloperName 
                                  FROM Product2 
                                 WHERE CodigoDeProductoBase__c LIKE :listFilter 
                                   AND RecordType.DeveloperName = 'ProductoDeFabrica'
                                   AND IsActive = true
                              ORDER BY CodigoDeProductoBase__c];

        //Factory products associated to a products base.
        for(Product2 p : prods) {
            prodWrapper = new ProductWrapper(p);
            productWrapperList.add(prodWrapper);
            idsFactoryProduct.add(p.Id);
        }

        List<Product2> packProds = [SELECT Id, 
                                           Name, 
                                           Marca2__c,
                                           Packaging__c,
                                           PrecioDeFabrica__c,
                                           ProductoDeFabrica__c,
                                           CostoPackaging__c
                                      FROM Product2
                                     WHERE RecordType.DeveloperName = 'OpcionDePackaging'
                                       AND ProductoDeFabrica__c IN :idsFactoryProduct
                                  ORDER BY ProductoDeFabrica__c];

        relateOLIBrands(oppLIWrapperList, productWrapperList);
        relatePackagingAndFactoryProducts(oppLIWrapperList, packProds);
    }


    private void relateOLIBrands(List<OPLIWrapper> oppLineItems, List<ProductWrapper> prods) {
        for(OPLIWrapper oliw : oppLineItems) {
            //search product brand
            findAndAddBrand(oliw, prods);
        }
    }

    
    private void findAndAddBrand(OPLIWrapper oliw, List<ProductWrapper> prods) {
        String productWrapperCodeWithoutBrand;    
        String productCodeWithoutBrand;
        FactoryProduct fp;
        String namePackaging;
        productCodeWithoutBrand = oliw.oli.Product2.CodigoDeProductoBase__c.substring(0,7);
        
        for(ProductWrapper pw : prods) {
            productWrapperCodeWithoutBrand = pw.product.CodigoDeProductoBase__c.substring(0,7);
            if(productCodeWithoutBrand.equals(productWrapperCodeWithoutBrand)) {

                fp = oliw.findFactoryProductBrand(pw.product.Marca2__c);
                if(fp == null) {
                    oliw.addBrand(pw.product.Id, pw.product.Marca2__c);
                    if(oliw.oli.Producto_Packaging__c != null) {
                        namePackaging = oliw.oli.Producto_Packaging__r.Packaging__c;
                    } else if (pw.product.Packaging__c != null) {
                        namePackaging = pw.product.Packaging__c;
                    } else {
                        namePackaging = 'SIN DATO';
                    }
                    oliw.addFactoryProduct(new Factoryproduct(pw.product, namePackaging));
                }
            }
        }
    }

    private void relatePackagingAndFactoryProducts(List<OPLIWrapper> oppLineItems, List<Product2> packprods) {
        FactoryProduct fprod;
        String idFactProd;
        for(Product2 pprod : packprods) {
            //id factory product associated with packaging porduct
            idFactProd = pprod.ProductoDeFabrica__c;
            for(OPLIWrapper oliw : oppLineItems) {
                fprod = oliw.findFactoryProduct(idFactProd);
                if(fprod != null) {
                    fprod.addPackaging(pprod);
                }
            }
        }

        for(OPLIWrapper oliwp : oppLineItems) {
            oliwp.setupAvailablePackagings();
            oliwp.setupAvailablePackaging();
        }
    }


    public PageReference saveBrands() {
        List<String> prodIds;
        List<OpportunityLineItem> oliToDelete;
        List<OpportunityLineItem> oliToSave;
        FactoryProduct factoryProductSelected;
        Product2 packagingProductSelected;
        Map<String, OpportunityLineItem> clonedOLIs;
        List<String> origOLIIds;
        OpportunityLineItem origOLI;
        OpportunityLineItem clonedOLI;
        Decimal listPrice;
        
        System.debug('SAVE P');

        oliToDelete = new List<OpportunityLineItem>();
        //Cloned opportunity line items list 
        oliToSave = new List<OpportunityLineItem>();
        //Original opportunity line items ids list
        origOLIIds = new List<String>();
 
        //Get original opp line items id's list
        for(OPLIWrapper ooliw : oppLIWrapperList) {
            origOLIIds.add(ooliw.oli.Id);
        }

        //get cloned opp line item object map
        //map (id, oli)
        clonedOLIs = DOBrandsDAO.getClonedRecordsOLI(origOLIIds);

        for(OPLIWrapper oliw : oppLIWrapperList) {
            System.debug('selbr[' + oliw.selectedBrand + ']');
            origOLI = clonedOLIs.get(oliw.oli.Id);
            if(origOLI == null) {
                break;
            }
            oliToDelete.add(oliw.oli);
            clonedOLI = origOLI.clone(false, true);
            factoryProductSelected = oliw.findSelectedFactoryProduct();
            packagingProductSelected = factoryProductSelected.findPackagingProduct(oliw.selectedPackaging);            

            if(oliw.oli.Product2.Packaging__c != null && !oliw.oli.Product2.Packaging__c.equals(oliw.selectedPackaging)) {
                //if factory product does not have packaging products
                if(packagingProductSelected == null) {
                    clonedOLI.ComentarioPackagingNuevo__c = oliw.oli.Product2.Packaging__c + ' cambio a ' + oliw.selectedPackaging;
                    clonedOLI.CostoProducto__c = (oliw.oli.Product2.PrecioDeFabrica__c + oliw.oli.Product2.CostoImportacionUnidad__c) * conversionRate;
                } else {
                    clonedOLI.Producto_Packaging__c = packagingProductSelected.Id;                    
                    clonedOLI.ComentarioPackagingNuevo__c = oliw.oli.Product2.Packaging__c + ' cambio a ' + packagingProductSelected.Packaging__c;
                    clonedOLI.CostoProducto__c = (oliw.oli.Product2.PrecioDeFabrica__c + oliw.oli.Product2.CostoImportacionUnidad__c + packagingProductSelected.CostoPackaging__c) * conversionRate;
                }

                clonedOLI.RequierePackagingNuevo__c = true;
                clonedOLI.Precio_Minimo__c = oliw.oli.Precio_Minimo__c;
            } 

            clonedOLI.Quantity = oliw.oli.Quantity;
            clonedOLI.UnitPrice = oliw.oli.UnitPrice;
            clonedOLI.Product2Id = factoryProductSelected.factoryProduct.Id;

            clonedOLI.Modificar_precio_manual__c = true;
            clonedOLI.TotalPrice = null;
            clonedOLI.Comentario_atendido__c = oliw.isCommentAdressed;
        
            System.debug('save[' + clonedOLI.Name + ']');
            oliToSave.add(clonedOLI);
        }
        
        delete oliToDelete;
        insert oliToSave;
        opp.Is_Brand_Selected__c = true;
        update opp;

        System.debug('END SAVE P');

        return null;
    }
    

    public void changeBrand() {
        FactoryProduct fp;
        System.debug('Cambio marca [' + oliIdBrandChanged + ']');
        for(OPLIWrapper oliw : oppLIWrapperList) {
            if(oliw.oli.Id.equals(oliIdBrandChanged)) {
                fp = oliw.findFactoryProductBrand(oliw.selectedBrand);
                oliw.availablePackagings = fp.packagings;
            }
        }

    }


    public void changePackaging() {
        Decimal costoProducto;
        Decimal listPrice;
        Decimal minimumPrice;
        FactoryProduct fp;
        Product2 packagingProduct;
        List<Product2> packagingProducts;

        for(OPLIWrapper oliw : oppLIWrapperList) {
            if(oliw.oli.Id.equals(oliIdBrandChanged)) {
                fp = oliw.findFactoryProductBrand(oliw.selectedBrand);
                if(fp != null) {
                    packagingProducts = fp.packagingProducts;
                    for(Product2 p : packagingProducts) {
                        if(p.Packaging__c.equals(oliw.selectedPackaging)) {
                            packagingProduct = p;  
                        }
                    }
                    if(packagingProduct != null) {
                        //calculate
                        costoProducto = (oliw.oli.Product2.PrecioDeFabrica__c + packagingProduct.CostoPackaging__c) * conversionRate;
                        listPrice = costoProducto / (1 - (opportunityMargen / 100));
                        minimumPrice = listPrice / ( 1 - (opportunityPorcentajeAportaciones + opportunityPorcentajeConvenio + oliw.oli.Porcentaje_Item__c) / 100 );
                        oliw.oli.Precio_Minimo__c = minimumPrice;
                    }
                }
            }
        }
    }


    class ProductWrapper {
        public Product2 product {set; get;}
        public String productCode {set; get;}
        
        public ProductWrapper(Product2 prod) {
            product = prod;
            productCode = prod.ProductCode;
        }
    }
 
    
    class FactoryProduct {
        public String idProduct {set; get;}
        public Product2 factoryProduct {set; get;}
        public List<Product2> packagingProducts {set; get;}
        public List<SelectOption> packagings {get;set;}
        public String basePackaging {get;set;}
        public String selectedPackaging {get;set;}

        public FactoryProduct(Product2 prod, String basePack) {
            packagings = new List<SelectOption>();
            packagingProducts = new List<Product2>();
            factoryProduct = prod;
            idProduct = prod.Id;
            basePackaging = basePack;
        }

        public void addPackaging(Product2 packProd) {
            packagingProducts.add(packProd); 
            SelectOption option = new SelectOption(packProd.Packaging__c, packProd.Packaging__c);
            packagings.add(option);
            if(basePackaging.equals(packProd.Packaging__c)) {
                selectedPackaging = packProd.Packaging__c;
            }
        }

        public Product2 findPackagingProduct(String packaging) {
            for(Product2 pp : packagingProducts) {
                if(pp.Packaging__c.equals(packaging)) {
                    return pp;
                }
            }
            return null;
        }
    }

    class OPLIWrapper {
        public OpportunityLineItem oli {set; get;}
        public List<FactoryProduct> factoryProducts {get;set;}
        public List<SelectOption> brands {get;set;}
        public String selectedBrand {get;set;}
        public String selectedIdFactoryProd {get;set;}
        public String imageid {get;set;}
        public List<SelectOption> availablePackagings {get;set;}
        public String selectedPackaging {get;set;}
        public Boolean isCommentAdressed {get;set;}

        public OPLIWrapper(OpportunityLineItem poli) {
            brands = new List<SelectOption>();
            factoryProducts = new List<FactoryProduct>();
            oli = poli;
            isCommentAdressed= oli.Comentario_atendido__c;
        }
        
        public void addBrand(String idprod, String brand) {
            String[] tokens = brand.split('-');
            String prodMarca = tokens[0];
            SelectOption option = new SelectOption(brand, brand);
            brands.add(option);
            if(prodMarca.equals(oli.Product2.CodigoDeProductoBase__c.substring(7,8))) {
                selectedBrand = brand;
                selectedIdFactoryProd = oli.Product2Id;
            }
        }

        
        public void setupAvailablePackaging() {
            FactoryProduct fp;
            fp = findFactoryProduct(selectedIdFactoryProd);
            if(fp != null) {
                availablePackagings = fp.packagings;
                if(availablePackagings.isEmpty()) {
                    SelectOption option = new SelectOption(fp.basePackaging, fp.basePackaging);
                    fp.packagings.add(option);
                }
                selectedPackaging = fp.basePackaging;
            }
        }

        public void setupAvailablePackagings() {
            for(FactoryProduct fp : factoryProducts) {
                if(fp != null) {
                    if(fp.packagings.isEmpty()) {
                        SelectOption option = new SelectOption(fp.basePackaging, fp.basePackaging);
                        fp.packagings.add(option);
                    }
                }
            }
        }


        public void addFactoryProduct(FactoryProduct fprod) {
            if(fprod != null) {
                //imageid = fprod.factoryProduct.ProductoBase__r.Imagen1__c;
                imageid = fprod.factoryProduct.ProductoBase__r.IDImagen1__c;                
                //System.debug('img[' + imageid + ']');
                factoryProducts.add(fprod);
            }
        }
        
        public FactoryProduct findSelectedFactoryProduct() {
            FactoryProduct productSelected;
            if(selectedBrand != null) {
                 for(FactoryProduct fprod : factoryProducts) {
                    if(fprod.factoryProduct.Marca2__c.equals(selectedBrand)) {
                        productSelected = fprod;
                        break;
                    }
                }
            }
            System.debug(' find selected prod selected [' + productSelected + '] ');
            return productSelected;
        }

        public FactoryProduct findFactoryProduct(String idFprod) {
            for(FactoryProduct fp : factoryProducts) {
                if(fp.idProduct.equals(idFprod)) {
                    return fp;
                }
            }
            return null;
        }

        public FactoryProduct findFactoryProductBrand(String brand) {
            for(FactoryProduct fp : factoryProducts) {
                if(fp.factoryProduct.Marca2__c.equals(brand)) {
                    return fp;
                }
            }
            return null;
        }

    }

}