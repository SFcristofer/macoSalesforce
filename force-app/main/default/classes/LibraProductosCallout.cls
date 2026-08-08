public class LibraProductosCallout extends LibraCallout {

    public LibraProductosCallout(String type) {
        super(type);
    }

    public override String buildPayload(Object param) {
        String[] tokens;
        String aux;
        String payload;
        Product2 prod;
        Product2 prodProv;
        List<Product2> prodToSendLibra;
        ProductBatchLibra pbl;
        LibraProductoPayload prodPayload;
        LibraProductoProveedorPayload proveedorPayload;
        String descripcion = '';

        pbl = (ProductBatchLibra)param;
        prod = pbl.product;

        prodPayload = new LibraProductoPayload();
        prodPayload.codigo_producto = prod.CodigoDeProductoBase__c;
        prodPayload.codigo_empresa = pbl.sociedadIdentifier;
        
        if(prod.Descripcion_Larga__c != null) {
            descripcion = (prod.Descripcion_Larga__c.length() > 50 ? prod.Descripcion_Larga__c.substring(0, 49) : prod.Descripcion_Larga__c);
        }
        
        prodPayload.desc_ventas = descripcion;
        prodPayload.desc_compras = descripcion;

        //prodToSendLibra = prod.FabricasDelProducto__r;
        prodToSendLibra = pbl.baseProducts;
        for(Product2 prodBL : prodToSendLibra) {
           prodProv = prodBL;
           proveedorPayload = new LibraProductoProveedorPayload();
           if(prodProv.Fabrica__r != null) {
               proveedorPayload.codigo_proveedor = prodProv.Fabrica__r.Codigo_rapido__c;
           }
           
           if(proveedorPayload.codigo_proveedor != null) {
               if(prodProv.PlazoDeFabricacion__c != null) {
                   aux = prodProv.PlazoDeFabricacion__c.replace('días','');
                   aux = aux.replace('<','');
                   aux = aux.replace('>','');
                   aux = aux.trim();
                   tokens = aux.split('-');
                   proveedorPayload.aprovi = String.valueOf(tokens[0]);
               } else {
                   proveedorPayload.aprovi = '';
               }
               proveedorPayload.desc_rove = prodProv.Fabrica__r.Description == null ? '' : prodProv.Fabrica__r.Description;
               proveedorPayload.habitua = 'N';
               prodPayload.proveedores.add(proveedorPayload);
           }
        }

        payload = JSON.serialize(prodPayload);

        return payload;        
    }

    public override Object processResponse(String response) {
        return null;
    }

    public override String buildEndpoint() {
        String endpoint;
        endpoint = CS_ENDPOINT + '?' + PARAM_USER + '=' + CS_USER + '&' + PARAM_PWD + '=' + CS_PASS + '&' + PARAM_ALIAS + '=' + CS_ALIAS;
        return endpoint;
    }

}