public class VencimientoCostoProduct implements Comparable {
    public Product2 product {set; get;}

    public Date fechaUltimaRevision {set; get;}
    public Integer diasVencimiento {set; get;}
    public Integer numberRow {set; get;}
    public Boolean isMarkedForVerification {set; get;}
    public Boolean isPrecioVigente {set; get;}
    public String msgDescription {set; get;}
    public String estadoVencimientoProducto {set; get;}

    public VencimientoCostoProduct(Product2 pprod) {
        product = pprod;
        msgDescription = '';
        setDays();
    }

    private void setDays() {

        Integer plazoPrecios;
        Date ultimaFechaRevision;
        Date limiteFechaRevision;
        Integer diffDays;

        if(product != null) {

            //System.debug('fr [' + product.Fecha_revision_costo__c + ']');
            if(product.Fabrica__r.Plazo_Precios_Proveedor__c == null) {
                msgDescription = 'La fábrica no tiene plazo';
            }

            if(product.Fecha_revision_costo__c == null) {
                msgDescription = 'Producto no tiene fecha de revisión de costo';
            }

            if(product.Fabrica__r.Plazo_Precios_Proveedor__c != null && product.Fecha_revision_costo__c != null) {
                plazoPrecios = Integer.valueOf(product.Fabrica__r.Plazo_Precios_Proveedor__c);
                ultimaFechaRevision = product.Fecha_revision_costo__c;
                limiteFechaRevision = Date.today();
                limiteFechaRevision = limiteFechaRevision.addDays(plazoPrecios * -1);
                diffDays = Date.today().daysBetween(ultimaFechaRevision.addDays(plazoPrecios));
    
                diasVencimiento = diffDays;
                if(diasVencimiento < 0) {
                    isPrecioVigente = false;
                } else {
                    isPrecioVigente = true;
                }
            } else {
                isPrecioVigente = false;
                diasVencimiento = 0;
            }
            System.debug(' dv [' + diasVencimiento + '] [' + product.ProductCode + ']');
        }
    }
    
    public Integer compareTo(Object compareTo) {
        VencimientoCostoProduct compareToVCProd = (VencimientoCostoProduct)compareTo;

        if (product != null) {
            if(product.Fabrica__c != null) {
                if(product.Fabrica__r.Name != null) {
                    if(product.Fabrica__r.Name > compareToVCProd.product.Fabrica__r.Name) return 1;
                    if(product.Fabrica__r.Name < compareToVCProd.product.Fabrica__r.Name) return -1;
                    if(product.Fabrica__r.Name.equals(compareToVCProd.product.Fabrica__r.Name)) return 0;
                }
            }
        } else {
            return -1;
        }
        return 0;
    }

}