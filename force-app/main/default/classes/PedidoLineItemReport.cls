public class PedidoLineItemReport {
    public List<PedidoLineItem__c> listPLI {set; get;}
    public String codigoProductoBase {set; get;}
    public String marca {set; get;}
    public String description {set; get;}
    public String ean {set; get;}
    private Set<String> listContainers {set; get;}
    public String containers {set; get;}
    private Set<String> listSeals {set; get;}
    public String seals {set; get;}
    public Decimal netWeight {set; get;}
    public Decimal grossWeight {set; get;}
    public Decimal cmb {set; get;}
    public Decimal unidades {set; get;}
    public Decimal totalCtn {set; get;}
    public Decimal precioDeVentaTotal {set; get;}
    public Decimal precioUnitario {set; get;}

    public PedidoLineItemReport() {
        listPLI = new List<PedidoLineItem__c>();
        listContainers = new Set<String>();
        listSeals = new Set<String>();
        containers = '';
        seals = '';
        netWeight = 0;
        grossWeight = 0;
        cmb = 0;
        unidades = 0;
        totalCtn = 0;
        precioDeVentaTotal = 0;
        precioUnitario = 0;
    }

    public void aggregateItemsData() {
        String[] tokens;
        for(PedidoLineItem__c pli : listPLI) {

            if(pli.Container_Number__c != null) {
                tokens = pli.Container_Number__c.split(',');
                for(String token : tokens) {
                    listContainers.add(token.trim());
                }
            }

            if(pli.SEAL_Number__c != null ) {
                tokens = pli.SEAL_Number__c.split(',');
                for(String token : tokens) {
                    listSeals.add(token.trim());
                }
            }

            if(pli.PrecioDeVentaTot__c != null) {
                precioDeVentaTotal = precioDeVentaTotal + pli.PrecioDeVentaTot__c;
            }

            if (pli.ProformaLineItem__r.PrecioUnitario__c != null) {
                precioUnitario = precioUnitario + pli.ProformaLineItem__r.PrecioUnitario__c;
            }

            if(pli.Net_Weight__c != null) {
                netWeight = netWeight + pli.Net_Weight__c;
            }

            if(pli.Gross_Weight__c != null) {
                grossWeight = grossWeight + pli.Gross_Weight__c;
            }

            if(pli.CBM__c != null) {
                cmb = cmb + pli.CBM__c;
            }

            if(pli.Unidades__c != null) {
                unidades = unidades + pli.Unidades__c;
            }

        }

        totalCtn = unidades / listPLI[0].UnidadesPorMasterbox__c;

        for(String cont : listContainers) {
            containers = containers + cont + ',';
        }

        if(!containers.equals('')) {
            containers = containers.substring(0, containers.length() - 1);
        }

        for(String cont : listSeals) {
            seals = seals + cont + ',';
        }

        if(!seals.equals('')) {
            seals = seals.substring(0, seals.length() - 1);
        }

    }

    public void setValues() {
        PedidoLineItem__c pli;
        if(!listPLI.isEmpty()) {
            pli = listPLI.get(0);
            codigoProductoBase = pli.ProformaLineItem__r.producto__r.CodigoDeProductoBase__c;
            marca = pli.ProformaLineItem__r.producto__r.Marca2__c;
            if(marca != null) {
                marca = replaceMark(marca);
            }
            description = pli.ProformaLineItem__r.producto__r.Descripcion_Larga__c;
            ean = pli.Producto__r.Codigo_EAN2__c;
        }
    }


    private String replaceMark(String mark) {
        String result = '';
        String[] tokensMarca;
        tokensMarca = mark.split('-');
        if(tokensMarca.size() == 2) {
            result = tokensMarca[1].replaceAll('\\(.*\\)', '');
        } else {
            result = mark;
        }
        return result;
    }
    
}