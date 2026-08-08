public class PortalModifCostProdController {
    private static String UNAVAILABLE_TOKEN = Label.PORTAL_UNAVAILABLE_TOKEN;
    private static String INVALID_TOKEN = Label.PORTAL_INVALID_TOKEN;

    public String token {set; get;}
    public Account provider {set; get;}

    public String idFactory;
    public List<OppFactProdVerification> verifications {set; get;}
    public Boolean isPageShowed {set; get;}    

    public PortalModifCostProdController() {
        token = ApexPages.CurrentPage().getparameters().get('dbrToken');
        System.debug('Token [' + token + ']');

    }

    public Pagereference loadPage() {
        List<String> idUsers;
        RecordType rt;

        System.debug('Loading page ...........');

        rt = DOBrandsDAO.getRecordType('Proveedor', 'Account');
        if(token == null) {
            System.debug('Msg [' + UNAVAILABLE_TOKEN + ']');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, UNAVAILABLE_TOKEN));
        } else {
            provider = DOBrandsDAO.getProviderByTokenVerificacion(token, rt);
            System.debug('provide [' + provider + ']');
            if(provider == null) {
                isPageShowed = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVALID_TOKEN));
                return null;
            }
        }

        idFactory = provider.Id;
        System.debug('provider [' + provider + ']');
        getProductosToApprove();
        return null;
    }


    public void getProductosToApprove() {
        List<Verificacion_Costo__c> verificacionesCosto;
        verifications = new List<OppFactProdVerification>();
        OppFactProdVerification ofpv;
        String estadoVerificacion;
        List<Verificacion_Costo_Productos__c> verificacionProductos;

        Integer plazoPrecios;
        Date ultimaFechaRevision;
        Date limiteFechaRevision;
        Integer diffDays;

        verificacionesCosto = [SELECT Id, 
                                      Name,
                                      Estado__c,
                                      (SELECT Id,
                                              Name,
                                              Estado__c,
                                              Fecha_Estado__c,   
                                              Opportunity__c,
                                              Opportunity__r.Name,
                                              Factory__c,
                                              Factory__r.Name,
                                              Factory__r.Plazo_Precios_Proveedor__c,
                                              Product__c,
                                              Product__r.CodigoDeProductoBase__c,
                                              Product__r.Codigo_Proveedor__c,
                                              Product__r.PrecioDeFabrica__c,
                                              Product__r.Fecha_revision_costo__c,
                                              Product__r.ProductoBase__r.Descripcion_Larga__c,
                                              Product__r.ProductoBase__r.IDImagen1__c,
                                              Product__r.ProductoBase__r.Imagen1__c,
                                              Product__r.ProductoBase__r.Thumb1__c,
                                              Product__r.ProductoBase__r.ProductName__c,
                                              Product__r.Medidas_del_Producto_Agrupadas2__c,
                                              Product__r.ProductName__c,
                                              Product__r.Name
                                         FROM Verificacion_Costos_Productos__r
                                        WHERE Factory__c = :idFactory
                                          AND Estado__c != 'Aprobado')
                                 FROM Verificacion_Costo__c
                                WHERE Estado__c != 'Verificado'];

        for(Verificacion_Costo__c vc : verificacionesCosto) {
            estadoVerificacion = vc.Estado__c;     
            verificacionProductos = vc.Verificacion_Costos_Productos__r;
            for(Verificacion_Costo_Productos__c vcp : verificacionProductos) {
                ofpv = new OppFactProdVerification();

                if(vcp.Factory__r.Plazo_Precios_Proveedor__c != null) {
                    plazoPrecios = Integer.valueOf(vcp.Factory__r.Plazo_Precios_Proveedor__c);
                } else {
                    plazoPrecios = 0;
                }

                if(vcp.Product__r.Fecha_revision_costo__c != null) {
                    ultimaFechaRevision = vcp.Product__r.Fecha_revision_costo__c;
                    limiteFechaRevision = Date.today();
                    limiteFechaRevision = limiteFechaRevision.addDays(plazoPrecios * -1);
                    diffDays = Date.today().daysBetween(ultimaFechaRevision.addDays(plazoPrecios));
                } else {
                    diffDays = 0;
                }

                ofpv.idVerificacionCosto = vc.Id;
                ofpv.idVerificacionCostoProd = vcp.Id;
            
                ofpv.idOpportunity = vcp.Opportunity__c;
                ofpv.idFactory = vcp.Factory__c;
                ofpv.idProduct = vcp.Product__c;
                ofpv.oppName = vcp.Opportunity__r.Name;
                ofpv.factoryName = vcp.Factory__r.Name;
                ofpv.productName = vcp.Product__r.Name;
                ofpv.fechaUltimaRevision = ultimaFechaRevision;
                ofpv.diasVencimiento = diffDays;
                ofpv.productDescription = vcp.Product__r.ProductoBase__r.Descripcion_Larga__c;
                if(vcp.Product__r.ProductoBase__r.ProductName__c != null) {
                    ofpv.englishProductDescription = vcp.Product__r.ProductoBase__r.ProductName__c + ' ' + vcp.Product__r.Medidas_del_Producto_Agrupadas2__c;
                } else {
                    ofpv.englishProductDescription = '';
                }

                ofpv.productCode = vcp.Product__r.CodigoDeProductoBase__c;

                ofpv.supplierCodeProduct = vcp.Product__r.Codigo_Proveedor__c;
                ofpv.oldCostProduct = vcp.Product__r.PrecioDeFabrica__c;
                ofpv.newCostProduct = vcp.Product__r.PrecioDeFabrica__c;
                ofpv.imageInfo = vcp.Product__r.ProductoBase__r.IDImagen1__c;

                /*if(diffDays > 0) {

                }*/

                verifications.add(ofpv);
            }
        }

    }


    public PageReference aprobar() {
        List<OppFactProdVerification> ofpvsUp;

        UpdateProductPricesController uppc;        
        PageReference pageRef = new PageReference('/portal/PortalModificacionCostoConfirm');
        List<String> idProdsApproved = new List<String>();
        List<Verificacion_Costo_Productos__c> vcpList = new List<Verificacion_Costo_Productos__c>();
        Verificacion_Costo_Productos__c vcp;

        ofpvsUp = new List<OppFactProdVerification>();

        for(OppFactProdVerification ofpv : verifications) {
            System.debug('Price updated [' + ofpv.newCostProduct + ']');

            vcp = new Verificacion_Costo_Productos__c(Id = ofpv.idVerificacionCostoProd,
                                                      Estado__c = ' Verificado',
                                                      Fecha_Estado__c = Date.today(),
                                                      New_Price__c = ofpv.newCostProduct);
            vcpList.add(vcp);

            if(ofpv.newCostProduct <= ofpv.oldCostProduct) {
                vcp.Estado__c = 'Aprobado';
                idProdsApproved.add(ofpv.idProduct);
                ofpvsUp.add(ofpv);
            }/* else {
                vcp = new Verificacion_Costo_Productos__c(Id = ofpv.idVerificacionCostoProd,
                                                          New_Price__c = ofpv.newCostProduct);
                vcpList.add(vcp);
            }*/
        }

        update vcpList;
        //saveVerification(prodsToVerify);

        uppc = new UpdateProductPricesController(ofpvsUp);
        uppc.executeProductUpdateOFPV();
        uppc.executeOppLineItemUpdate();

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Thank you for updating the Price. DO-Brands team will review them and contact you if any further information is necessary'));
        pageRef.setRedirect(false);
        return pageRef;
    }



}