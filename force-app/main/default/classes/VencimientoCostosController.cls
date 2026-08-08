public class VencimientoCostosController {
    public List<VencimientoCostoProduct> productsVC {set; get;}
    public List<VencimientoCostoProduct> prodsToVerify;    

    public VencimientoCostosController() {
        getProducts();
    }


    public void getProducts() {
        System.debug('GPPPPP');
        List<Product2> products;
        productsVC = new List<VencimientoCostoProduct>();
        VencimientoCostoProduct productVC;
        Integer consecutive = 0;
        List<Verificacion_Costo_Productos__c> listVCP;
        Map<String, String> mapProdEstado;
        String estadoV;

        mapProdEstado = new Map<String, String>();

        products = [SELECT Id,
                           Name,
                           CodigoDeProductoBase__c,
                           ProductCode,
                           PrecioDeFabrica__c,
                           Fecha_revision_costo__c,
                           Estado_verificacion_costo__c,
                           Precio_Vigente__c,
                           ProductoBase__r.Descripcion_Larga__c,
                           ProductoBase__r.IDImagen1__c,
                           ProductoBase__r.Imagen1__c,
                           ProductoBase__r.Thumb1__c,
                           ProductoBase__r.ProductCode,
                           Fabrica__c,
                           Fabrica__r.Name,
                           Fabrica__r.Plazo_Precios_Proveedor__c
                      FROM Product2
                     WHERE isActive = true
                       AND RecordType.DeveloperName = 'ProductoDeFabrica'                     
                       AND CodigoDeProductoBase__c != '22222222' LIMIT 1000];
                       
                       
        listVCP = [SELECT Id, 
                          Product__c, 
                          Estado__c 
                     FROM Verificacion_Costo_Productos__c 
                    WHERE Estado__c != 'Aprobado'];
                    
        for(Verificacion_Costo_Productos__c vcp : listVCP) {
            mapProdEstado.put(vcp.Product__c, vcp.Estado__c);
        }

        for(Product2 p : products) {
            productVC = new VencimientoCostoProduct(p);
            estadoV = mapProdEstado.get(p.Id);

            //System.debug(' diasVnc [' + productVC.diasVencimiento + ']');
            if (productVC.diasVencimiento <= 15) {
                if(estadoV == null) {
                    consecutive++;
                    productVC.numberRow = consecutive;
                    productsVC.add(productVC);
                }
            }
        }
        
        productsVC.sort();

        System.debug('sz [' + productsVC.size() + ']');
    }



    public PageReference verification() {
        PageReference pageRef = new PageReference('/lightning/o/Opportunity/list');
        prodsToVerify = new List<VencimientoCostoProduct>();

        for(VencimientoCostoProduct pcv : productsVC) {
            if(!pcv.isPrecioVigente) {
                prodsToVerify.add(pcv);
            }
        }
        saveVerification(prodsToVerify);
        return pageRef;
    }

    public PageReference manualVerification() {
        PageReference pageRef = new PageReference('/lightning/o/Opportunity/list');
        prodsToVerify = new List<VencimientoCostoProduct>();

        for(VencimientoCostoProduct pcv : productsVC) {
            if(pcv.isMarkedForVerification) {
                prodsToVerify.add(pcv);
            }
        }

        saveVerification(prodsToVerify);
        return pageRef;
    }


    public PageReference factoryVerification() {
        VencimientoCostoProduct vcpSelected;
        PageReference pageRef = new PageReference('/lightning/o/Opportunity/list');
        prodsToVerify = new List<VencimientoCostoProduct>();

        for(VencimientoCostoProduct pcv : productsVC) {
            if(pcv.isMarkedForVerification) {
               vcpSelected = pcv;
               break;
            }
        }
        
        if(vcpSelected != null) {
            for(VencimientoCostoProduct pcv : productsVC) {
                if(pcv.product.Fabrica__r.Name != null && vcpSelected.product.Fabrica__r.Name != null) {
                    if(pcv.product.Fabrica__r.Name.equals(vcpSelected.product.Fabrica__r.Name)) {
                        prodsToVerify.add(pcv);                    
                    }
                }
            }
        }

        saveVerification(prodsToVerify);
        return pageRef;
    }


    private void saveVerification(List<VencimientoCostoProduct> pdsToVerify) {
        Verificacion_Costo__c vc;
        List<Verificacion_Costo_Productos__c> vcpList;
        Verificacion_Costo_Productos__c vcp;

        vc = new Verificacion_Costo__c(Name = 'PROD-' + Date.today(),
                                       Estado__c = 'En Verificacion');
        
        insert vc;

        vcpList = new List<Verificacion_Costo_Productos__c>();

        for(VencimientoCostoProduct pvc : pdsToVerify) {
            vcp = new Verificacion_Costo_Productos__c(Verificacion_Costo__c = vc.Id,
                                                      Estado__c = 'Pendiente',
                                                      Fecha_Estado__c = Date.today(),
                                                      Factory__c  = pvc.product.fabrica__c,
                                                      Product__c = pvc.product.Id);
            vcpList.add(vcp);                                        
        }

        insert vcpList;
    }
    
}