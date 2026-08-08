public class Catalogo {
    public List<ProductoFamilia> familias {set; get;}
    public Map<String, ProductoFamilia> mapFamilias {set; get;}
    private List<Catalogo_FSC__mdt> catalogoMdts;
    private List<Catalogo_FSC__mdt> catalogoMdtsFS;
    private List<Catalogo_FSC__mdt> catalogoMdtsCL;    
    private Map<String, List<String>> mapFamilaSubfamilia;
    private Map<String, List<String>> mapSubfamiliaClase;

    public ProductoFamilia currentFamily {set; get;}
    public ProductoSubfamilia currentSubfamily {set; get;}
    public List<Product2> productos {set; get;}
    public Map<Id, Boolean> highlightAsNew {get; set;}
    public Map<Id, Boolean> highlightAsBSellerGlobal {get; set;}
    public Map<Id, Boolean> highlightAsBSellerInNOut {get; set;}

    public String tipoClasificacion;
    public String claveActual;

    public String currentClassPrefix{get;set;}
    public String currentClassName{get;set;}

    public String bodyTag {get;set;} //sets the id for body
    private String priceBookCurrencyIsoCode;

    public Catalogo(List<Catalogo_FSC__mdt> pcatalogoMdts, List<Catalogo_FSC__mdt> pcatalogoMdtsFS, List<Catalogo_FSC__mdt> pcatalogoMdtsCL, Map<String, List<String>> mapFS, Map<String, List<String>> mapSC, String isoCode) {
        familias = new List<ProductoFamilia>();
        mapFamilias = new Map<String, ProductoFamilia>();
        catalogoMdts = pcatalogoMdts;
        catalogoMdtsFS = pcatalogoMdtsFS;
        catalogoMdtsCL = pcatalogoMdtsCL;
        mapFamilaSubfamilia = mapFS;
        mapSubfamiliaClase = mapSC;
        highlightAsNew = HighlightProductManager.getHighlightedAsNew();
        highlightAsBSellerGlobal = HighlightProductManager.getBestSellerGlobal();
        highlightAsBSellerInNOut = HighlightProductManager.getBestSellerInNOut();
        priceBookCurrencyIsoCode = isoCode;        
    }

    public void addFamilia(String claveFamilia, String descFamilia, String imagenFamilia, String pidHref, String pimagenSubfamilia) {
        ProductoFamilia pf = new ProductoFamilia();
        pf.clave = claveFamilia;
        System.debug('CATALOGO.ADDFAMILIA [' + descFamilia + ']');
        if(descFamilia.contains('Home')) {
            pf.cssOrStyle = 'DO Home';
        }
        if(descFamilia.contains('Garden')) {
            pf.cssOrStyle = 'DO Garden';
        }
        if(descFamilia.contains('Heating')) {
            pf.cssOrStyle = 'DO Brico';
        }
        if(descFamilia.contains('Kids')) {
            pf.cssOrStyle = 'DO Play';
        }
        
        pf.descripcion = descFamilia;
        pf.imagen = imagenFamilia;
        pf.idHref = pidHref;
        pf.imagenSF = pimagenSubfamilia;
        addFamilia(pf);
    }

    public void addFamilia(ProductoFamilia pf) {
        ProductoFamilia pfExistente;
        pfExistente = mapFamilias.get(pf.clave);
        if(pfExistente == null) {
            mapFamilias.put(pf.clave, pf);
        }
    }


    public void addSubFamilia(String cveFamilia, ProductoSubfamilia psf) {
        ProductoFamilia pfExistente;
        pfExistente = mapFamilias.get(cveFamilia);
        if(pfExistente != null) {
            pfExistente.addSubfamilia(psf);
            //pfExistente.subfamilias.add(psf);
        }
    }


    public void addClase(String cveFamilia, String cveSubfamilia, ProductoClase pc) {
        ProductoFamilia pfExistente;
        List<ProductoSubfamilia> subfamilias;
        ProductoSubfamilia pSubfamilia;
        pfExistente = mapFamilias.get(cveFamilia);
        if(pfExistente != null) {
            subfamilias = pfExistente.subfamilias;
            for(ProductoSubfamilia psf : subfamilias) {
                if(psf.clave.equals(cveSubfamilia)) {
                    pSubfamilia = psf;
                    break;
                }
            }
            pSubfamilia.clases.add(pc);
        }
    }


    public void addFSCItem(String fscItem, String tipo, String cveInmediato, String cvePadre, String cveActual) {
        String claveFamilia;
        String imagenFamilia;
        String descFamilia;
        String idHrefFamilia;
        String imagenSubFamilia;
        String claveSubfamilia;
        String claveClase;
        Catalogo_FSC__mdt catMDT;
        Catalogo_FSC__mdt catMDTSF;
        Catalogo_FSC__mdt catMDTCL;        
        ProductoSubfamilia psf;
        ProductoClase pcl;
        tipoClasificacion = tipo;
        claveActual = cveActual;

        System.debug('FSCITEM[' + fscItem + '] inm[' + cveInmediato + '] p[' + cvePadre + '] tipo[' + tipo + ']');

        claveFamilia = fscItem.substring(0,1);
        catMDT = searchCatalogoMDT(claveFamilia, 'Familia');
        imagenFamilia = catMDT.Imagen__c;
        descFamilia = searchDescription(claveFamilia, 'Familia');
        idHrefFamilia = catMDT.id_href__c;
        imagenSubFamilia = catMDT.ImagenSubF__c;
        addFamilia(claveFamilia, descFamilia, imagenFamilia, idHrefFamilia, imagenSubFamilia);

        if(tipo.equals('Subfamilia')) {
            claveSubfamilia = fscItem.substring(1,2);
            if(claveFamilia.equals(cveInmediato)) {
                catMDTSF = searchCatalogoMDTSF(claveFamilia, claveSubfamilia);
    
                psf = new ProductoSubfamilia();
                psf.clave = catMDTSF.Clave__c;
                psf.descripcion = catMDTSF.Descripcion__c;
                psf.imagen = catMDTSF.Imagen__c;
                addSubFamilia(claveFamilia, psf);
            }
        }
    
        if(tipo.equals('Clase') || tipo.equals('Producto')) {
            claveSubfamilia = fscItem.substring(1,2);
            if(claveFamilia.equals(cvePadre)) {
                catMDTSF = searchCatalogoMDTSF(claveFamilia, claveSubfamilia);
    
                psf = new ProductoSubfamilia();
                psf.clave = catMDTSF.Clave__c;
                psf.descripcion = catMDTSF.Descripcion__c;
                psf.imagen = catMDTSF.Imagen__c;
                addSubFamilia(claveFamilia, psf);
            }

            claveClase = fscItem.substring(2,4);
            if(claveFamilia.equals(cvePadre) && claveSubfamilia.equals(cveInmediato)) {
                catMDTCL = searchCatalogoMDTCL(claveFamilia, claveSubfamilia, claveClase);
                if(catMDTCL != null) {
                    pcl = new ProductoClase();
                    pcl.clave = catMDTCL.Clave__c;
                    pcl.descripcion = catMDTCL.Descripcion__c;
                    pcl.imagen = catMDTCL.Imagen__c;
                    addClase(claveFamilia, claveSubfamilia, pcl);
                }
            }
        }
    }


    private Catalogo_FSC__mdt searchCatalogoMDT(String clave, String tipo) {
        for(Catalogo_FSC__mdt catmdt : catalogoMdts) {
            if(catmdt.Tipo__c.equals(tipo) && catmdt.Clave__c.equals(clave)) {
                return catmdt;
            }
        }
        return null;
    }


    private Catalogo_FSC__mdt searchCatalogoMDTSF(String claveFam, String claveSF) {
        for(Catalogo_FSC__mdt catmdt : catalogoMdtsFS) {
            if(catmdt.Clave_padre_inmediato__c.equals(claveFam) && catmdt.Clave__c.equals(claveSF)) {
                return catmdt;
            }
        }
        return null;
    }


    private Catalogo_FSC__mdt searchCatalogoMDTCL(String claveFam, String claveSF, String claveClase) {
        for(Catalogo_FSC__mdt catmdt : catalogoMdtsCL) {
            if(catmdt.Clave_padre__c.equals(claveFam) && catmdt.Clave_padre_inmediato__c.equals(claveSF) && catmdt.Clave__c.equals(claveClase)) {
                return catmdt;
            }
        }
        return null;
    }

    private String searchDescription(String clave, String tipo) {
        String[] tokensFamilia;
        String tokenClave;
        if(tipo.equals('Familia')) {
            for(String key : mapFamilaSubfamilia.keySet()) {
                tokensFamilia = key.split('-');
                if(tokensFamilia != null && tokensFamilia.size() == 2) {
                    tokenClave = tokensFamilia[0];
                    if(tokenClave.equals(clave)) {
                        return tokensFamilia[1];
                    }
                }
            }
        }
        return null;
    }

    public void buildCatalogo() {
        List<ProductoSubfamilia> subfamilias;      
        ProductoFamilia pf;
        for(String key : mapFamilias.keySet()) {
            pf = mapFamilias.get(key);
            familias.add(pf);
        }

        for(ProductoFamilia pft : familias) {
            if(pft.subfamilias.size() > 0) {
                currentFamily = pft;
                pft.classSubfamiliaMenu = 'active';
                break;
            }
        }

        if(currentFamily != null) {
            subfamilias = currentFamily.subfamilias;
            for(ProductoSubfamilia psf : subfamilias) {
                if(psf.clases.size() > 0) {
                    currentSubfamily = psf;
                }
            }
        }

        List<String> idsProduct = new List<String>();
        List<Product2> productsAux = new List<Product2>();
        productos = new List<Product2>();
        Map<String, PriceBookEntry> mapProductPricebook;
        //For class filtering if no class is specified, adds all classess in Catalogo__c for the subfamily, 
        //otherwise adds only the one matchin currentClassPrefix
        if(currentFamily != null && currentSubfamily != null) {
            ProductoClase pc;
            List<ProductoClase> pcList = currentSubfamily.clases;
            List<String> classesFullName = new List<String>();

            if(pcList != null && !pcList.isEmpty()) {
                for(ProductoClase prc : pcList) {
                    if(currentClassPrefix == null || currentClassPrefix == prc.clave) {
                        classesFullName.add(prc.clave + '-' + prc.descripcion);
                        if(currentClassPrefix == prc.clave) {
                            currentClassName = prc.descripcion;
                            break;
                        }
                    }
                }
                
                System.debug('----------------------------------clss------------------------------------------------');
                for(String cvpr : classesFullName) {
                    System.debug(' cfn [' + cvpr + ']');
                }
                System.debug('----------------------------------clss------------------------------------------------');
                
                productsAux = DOBrandsDAO.getProductsByFamSubFamClasses(currentFamily.clave, currentSubfamily.clave, classesFullName);
                
                System.debug('size prods [' + productsAux.size() + ']');
                
                for(Product2 product : productsAux) {
                    idsProduct.add(product.Id);
                }
                mapProductPricebook = DOBrandsDAO.getMapProductsPriceBook(idsProduct, 'Key Account', priceBookCurrencyIsoCode);
                for(Product2 product : productsAux) {
                    if(mapProductPricebook.containsKey(product.Id)) {
                        productos.add(product);
                    }
                }
                addMissingKeys(productos);
            }
        }

        String equiv;
        if(currentFamily != null) {

            if(currentFamily.descripcion.contains('Home')) {
                equiv = 'DO Home';
            }
            if(currentFamily.descripcion.contains('Garden')) {
                equiv = 'DO Garden';
            }
            if(currentFamily.descripcion.contains('Heating')) {
                equiv = 'DO Brico';
            }
            if(currentFamily.descripcion.contains('Kids')) {
                equiv = 'DO Play';
            }


            //setBodyTag(currentFamily.descripcion);
            setBodyTag(equiv);
        }
    }

    /**
     * Sets the id for the body tag in page
     */
    public void setBodyTag(String fam) {
        if(fam != null) {
            bodyTag = fam.toLowerCase().replace(' ', '-');
        }

    }

    /**
     * Adds the missing keys (based on prods list) to the highlighted maps
     */
    public void addMissingKeys(List<Product2> prods) {
        for(Product2 p : prods) {
            if(!highlightAsNew.containsKey(p.ProductoBase__r.Id)) {
                highlightAsNew.put(p.ProductoBase__r.Id, false);
            }
            if(!highlightAsBSellerGlobal.containsKey(p.ProductoBase__r.Id)) {
                highlightAsBSellerGlobal.put(p.ProductoBase__r.Id, false);
            }
            if(!highlightAsBSellerInNOut.containsKey(p.ProductoBase__r.Id)) {
                highlightAsBSellerInNOut.put(p.ProductoBase__r.Id, false);
            }
        }
    }
}