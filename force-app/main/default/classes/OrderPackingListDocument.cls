public class OrderPackingListDocument {
    public String razonSocial {get;set;}
    public String calle {get;set;}
    public String ciudad {get;set;}
    public String pais {get;set;}
    public String division {get;set;}
    public String telefono {get;set;}
    public String correo {get;set;}
    public String beneficiario {get;set;}
    public String numeroDeCuenta {get;set;}
    public String bancoBeneficiario {get;set;}
    public String direccionBanco {get;set;}
    public String swiftCode {get;set;}
    private PedidoDeCompra__c pedido;
 
    public Decimal cbmTotal {get;set;}
    public Decimal netWt {get;set;}
    public Decimal grossWt {get;set;}
 
    public List<PedidoLineItemReport> listPLIReport {set; get;}
 
    public List<PedidoLineItem__c> pedidoLineItems {get;set;}
 
    public OrderPackingListDocument (ApexPages.StandardController stdController) {
       String sociedad;
       pedido = (PedidoDeCompra__c)stdController.getRecord();
 
       pedidoLineItems = DOBrandsDAO.getPedidoLineItems(pedido.Id);
       listPLIReport = new List<PedidoLineItemReport>();
       System.debug('PLI size[' + pedidoLineItems.size() + ']');
       processPedidoLineItems(pedidoLineItems);
 
       System.debug('pedidoId-cuenta: ' + pedido.Proforma__r.Cuenta__r);
       sociedad = DOBrandsDAO.getSociedadFromOrder(pedido.Id);
       getSociedadInfo(sociedad);
       getOrderTotal(pedido.Id);
    }
 
 
    private void processPedidoLineItems(List<PedidoLineItem__c> pedidoLineItems) {
        String codProdBase;
        PedidoLineItemReport pliReport;
        Map<String, PedidoLineItemReport> mapPli = new Map<String, PedidoLineItemReport>();
        
        for(PedidoLineItem__c pli : pedidoLineItems) {
            codProdBase = pli.ProformaLineItem__r.Producto__r.CodigoDeProductoBase__c;
            pliReport = mapPli.get(codProdBase);
            if(pliReport == null) {
                pliReport = new PedidoLineItemReport();
                mapPli.put(codProdBase, pliReport);
            }
            pliReport.listPLI.add(pli);
        }
 
        for(String codProd : mapPli.keySet()) {
            pliReport = mapPli.get(codProd);
            System.debug('PLI codProd[' + codProd + ']');           
            pliReport.setValues();
            pliReport.aggregateItemsData();
            listPLIReport.add(pliReport);
        }
    }
 
    public void getSociedadInfo(String sociedad) {
       Sociedades__mdt mdt;
       mdt = [SELECT Id, 
                     MasterLabel,
                     Banco_Beneficiario__c,
                     Beneficiario__c,
                     Calle__c,
                     Calle_2__c,
                     Ciudad__c,
                     Correo_Electronico__c,
                     Direccion_Banco__c,
                     Division__c,
                     Nombre__c,
                     Numero_De_Cuenta__c,
                     Pais__c,
                     Razon_Social__c,
                     SWIFT_Code__c,
                     Telefono__c
                FROM Sociedades__mdt 
               WHERE MasterLabel = :sociedad];
       razonSocial = mdt.Razon_Social__c;
       calle = mdt.Calle__c;
       ciudad = mdt.Ciudad__c;
       pais = mdt.Pais__c;
       division = mdt.Division__c;
       telefono = mdt.Telefono__c;
       correo = mdt.Correo_Electronico__c;
       beneficiario = mdt.Beneficiario__c;
       numeroDeCuenta = mdt.Numero_De_Cuenta__c;
       bancoBeneficiario = mdt.Banco_Beneficiario__c;
       direccionBanco = mdt.Direccion_Banco__c;
       swiftCode = mdt.SWIFT_Code__c;
    }
 
 
    public void getOrderTotal(String orderId) {
        Map<String, Decimal> mapRes;
        mapRes = DOBrandsDAO.getPedidoLineItemsTotales(orderId);
 
        cbmTotal = mapRes.get('sumcbm');
        netWt = mapRes.get('netWt');
        grossWt = mapRes.get('grsWt');
    }
 
 }