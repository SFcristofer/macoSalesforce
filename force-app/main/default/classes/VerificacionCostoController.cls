public class VerificacionCostoController {
    public List<OppFactProdVerification> verifications {set; get;}

    public VerificacionCostoController() {
        getVerifications();
        verifications.sort();
    }


    public void getVerifications() {
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
                                              Product__r.Name
                                         FROM Verificacion_Costos_Productos__r
                                        WHERE Estado__c != 'Aprobado')
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

                ultimaFechaRevision = vcp.Product__r.Fecha_revision_costo__c;
                limiteFechaRevision = Date.today();
                limiteFechaRevision = limiteFechaRevision.addDays(plazoPrecios * -1);
                if(ultimaFechaRevision != null) {
                    diffDays = Date.today().daysBetween(ultimaFechaRevision.addDays(plazoPrecios));
                } else {
                    diffDays = 0;
                }

                ofpv.idVerificacionCosto = vc.Id;
                ofpv.idVerificacionCostoProd = vcp.Id;
            
                ofpv.idOpportunity = vcp.Opportunity__c;
                if(ofpv.idOpportunity == null) {
                    ofpv.numOps = 0;
                }
                ofpv.idFactory = vcp.Factory__c;
                ofpv.idProduct = vcp.Product__c;
                ofpv.oppName = vcp.Opportunity__r.Name;
                ofpv.factoryName = vcp.Factory__r.Name;
                ofpv.productName = vcp.Product__r.Name;
                ofpv.fechaUltimaRevision = ultimaFechaRevision;
                ofpv.diasVencimiento = diffDays;
                ofpv.productDescription = vcp.Product__r.ProductoBase__r.Descripcion_Larga__c;
                ofpv.productCode = vcp.Product__r.CodigoDeProductoBase__c;
                ofpv.estado = vcp.Estado__c;
                ofpv.fechaStatus = vcp.Fecha_Estado__c;

                System.debug('estado [' + ofpv.estado + '] fechaestado[' + ofpv.fechaStatus + ']');

                verifications.add(ofpv);
            }
        }
    } 
    
    
}