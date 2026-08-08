public class ContainerPLPDFController {
    public PedidoDeCompra__c pedido {get; set;}
    public PLPDFDocument pdfDoc {get; set;}
    
    public ContainerPLPDFController(ApexPages.StandardController stdController) {
        pedido = (PedidoDeCompra__c)stdController.getRecord();
        //load pedido , accoutn (cliente)
        //loadPedido(pedido.Id);
        //load containers
        //loadContainers(pedido.Id);
        
        pdfDoc = new PLPDFDocument(loadAddress('Pacific Global USD'), loadPedido(pedido.Id), loadContainers(pedido.Id), loadItemsFacturaCliente(pedido.Id));
    }
    
    public Sociedades__mdt loadAddress(String labelName) {
        List<Sociedades__mdt> sociedades;
        Sociedades__mdt sociedad;
        sociedades = [SELECT Id,
                             Razon_Social__c,
                             Calle__c,
                             Ciudad__c,
                             Pais__c,
                             ZIP_CODE__c,
                             Tax_ID__c,
                             MasterLabel 
                        FROM Sociedades__mdt 
                       WHERE MasterLabel = :labelName];
        
        if(sociedades != null && sociedades.size() > 0) {
            sociedad = sociedades.get(0);
        }
        
        return sociedad;
    }

    
    public PedidoDeCompra__c loadPedido(String idPedido) {
        List<PedidoDeCompra__c> pedidos;
        PedidoDeCompra__c pedido;
        
        pedidos = [SELECT Id,
                          Name,
                          Numero_de_Factura__c,
                          Fecha_Factura__c,
                          Total_Cantidad__c,
                          Fecha_de_Carga_de_Contenedor__c,
                          Total_Cajas__c,
                          CuentaRelacion__c,
                          CuentaRelacion__r.Name,
                          CuentaRelacion__r.ParentId,
                          CuentaRelacion__r.Parent.RazonSocial__c,
                          CuentaRelacion__r.Parent.Name,
                          CuentaRelacion__r.Parent.BillingStreet,
                          CuentaRelacion__r.Parent.BillingCity,
                          CuentaRelacion__r.Parent.BillingState,
                          CuentaRelacion__r.Parent.BillingPostalCode,
                          CuentaRelacion__r.Parent.BillingCountry,
                          CuentaRelacion__r.Parent.NroIdFiscal__c,
                          CuentaRelacion__r.Parent.Phone,
                          CuentaRelacion__r.Parent.BillingAddress,
                          Numero_de_Orden__c //PO Cliente
                     FROM PedidoDeCompra__c
                    WHERE Id = :idPedido];
                    
        if(pedidos != null && pedidos.size() > 0) {
            pedido = pedidos.get(0);
        }

        return pedido;
    }

    
    public Map<String, ItemDeFacturaDeCliente__c> loadItemsFacturaCliente(String idPedido) {
        List<FacturaDeCliente__c> facturasCliente;
        Map<String, ItemDeFacturaDeCliente__c> mapItemsFacturaCliente;
        List<ItemDeFacturaDeCliente__c> itemsFacturaCliente;
        List<String> idFacturasIds;
        
        idFacturasIds = new List<String>();
        itemsFacturaCliente = new List<ItemDeFacturaDeCliente__c>();
        mapItemsFacturaCliente = new Map<String, ItemDeFacturaDeCliente__c>();
        
        facturasCliente = [SELECT Id, 
                                  Name, 
                                  PedidoPrincipal__c 
                             FROM FacturaDeCliente__c 
                            WHERE PedidoPrincipal__c = :idPedido];
                            
        for (FacturaDeCliente__c customerInvoice : facturasCliente) {
            idFacturasIds.add(customerInvoice.Id);
        }
        
        itemsFacturaCliente = [SELECT Id, 
                                      Name,
                                      Descripcion__c,
                                      MarcaDeProducto__c,
                                      CodigoDeProducto__c
                                 FROM ItemDeFacturaDeCliente__c 
                                WHERE Factura__c IN :idFacturasIds];
                                
        for (ItemDeFacturaDeCliente__c itemFactura : itemsFacturaCliente) {
            mapItemsFacturaCliente.put(itemFactura.CodigoDeProducto__c, itemFactura);
        }
        
        return mapItemsFacturaCliente;
    }
    
    
    public List<Container__c> loadContainers(String idPedido) {
        List<Container__c> containers;
        containers = [SELECT Id,
                             Name,
                             Cajas__c,
                             Total_Productos__c,
                             Total_Net_W__c,
                             Total_Gross_W__c,
                             Total_CBM__c,
                             Pedido__c,
                             Pedido__r.Name,
                             SEAL__c,
                             Type__c,
                             (
                              SELECT Id,
                                     Producto__c,
                                     Producto__r.Name,
                                     Producto__r.CodigoDeProductoBase__c,
                                     Producto__r.Codigo_Proveedor2__c,                                     
                                     Producto__r.ProductoBase__r.ProductName__c,
                                     Producto__r.ProductoBase__r.CodigoDeProductoBase__c,
                                     Producto__r.ProductoBase__r.Codigo_Proveedor2__c,
                                     Producto__r.ProductoBase__r.Codigo_EAN2__c,
                                     Gross_Weight__c,
                                     Net_Weight__c,
                                     CBM__c,
                                     Cajas__c,
                                     Total_Productos__c
                                FROM Container_Pedido_Line_Items1__r
                             )
                        FROM Container__c
                        WHERE Pedido__c = :idPedido];

        System.debug('[' + idPedido + ']  Containers size[' + containers.size() + ']');
        return containers;
    }

    class PLPDFDocument {
        private Integer MAX_SIZE_LINE_ADDRESS = 35;
        public String staticResourceName {set; get;}    
        public String imageName {set; get;}
        public String namePG {set; get;}
        
        public String companyName {set; get;}
        public String companyAddressLine1 {set; get;}
        public String companyAddressLine2 {set; get;}
        public String companyAddressLine3 {set; get;}

        public String documentName {set; get;}
                
        public String customerRazonSocial {set; get;}
        public String customerBillingStreet {set; get;}
        public String customerBillingCity {set; get;}
        public String customerBillingState {set; get;}
        public String customerBillingPostalCode {set; get;}
        public String customerBillingCountry {set; get;}
        public String customerIDFiscal {set; get;}
        public String customerPhone {set; get;}
                
        public Date invoiceDate {set; get;}
        public String invoiceNumber {set; get;}
        
        public String poCliente {set; get;}
        
        public List<ContainerPDF> containersPDF {set; get;}
        
        public TotalsSummaryContainersPDF summary {set; get;}
        
        private Sociedades__mdt sociedad;
        private PedidoDeCompra__c pedido;
        private List<Container__c> containers;
        private Map<String, ItemDeFacturaDeCliente__c> itemsFactura;
        
        public PLPDFDocument(Sociedades__mdt psociedadInfo, PedidoDeCompra__c ppedido, List<Container__c> pcontainers, Map<String, ItemDeFacturaDeCliente__c> pitemsFactura) {
            staticResourceName = 'pdfresources';
            imageName = 'DB_logo.png';
            documentName = 'PACKING LIST';
            
            sociedad = psociedadInfo;
            generateCompanyInfo();
            
            pedido = ppedido;
            generateOrderCustomerInfo();
            
            containers = pcontainers;
            generateContainersItems();
            
            itemsFactura = pitemsFactura;
            associateItemsFacturaContainer();
            
            genereateTotals();
        }
        
        private void generateCompanyInfo() {
            if(sociedad != null) {
                companyName = sociedad.Razon_Social__c;
                companyAddressLine1 = sociedad.Calle__c;
                companyAddressLine2 = sociedad.Ciudad__c + ' ' + sociedad.ZIP_CODE__c + ', ' + sociedad.Pais__c;
                companyAddressLine3 = 'TAX ID: ' + sociedad.Tax_ID__c;
            }
        }
        
        private void generateOrderCustomerInfo() {
            Address customerFullAddress;
            String customerFullAddressStr;
            String[] tokens;
            Integer sizeJoinTokens;
            String aux = '';
            List<String> addressLines;
            
            System.debug('cn [' + pedido.CuentaRelacion__r.Parent.Name + ']');
            
            if(pedido != null) {
            
                customerRazonSocial = pedido.CuentaRelacion__r.Parent.RazonSocial__c;

                customerBillingStreet = pedido.CuentaRelacion__r.Parent.BillingStreet;
                customerBillingCity = pedido.CuentaRelacion__r.Parent.BillingCity;
                customerBillingState = pedido.CuentaRelacion__r.Parent.BillingState;
                customerBillingPostalCode = pedido.CuentaRelacion__r.Parent.BillingPostalCode;
                customerBillingCountry = pedido.CuentaRelacion__r.Parent.BillingCountry;
                customerIDFiscal = pedido.CuentaRelacion__r.Parent.NroIdFiscal__c;
                customerPhone = pedido.CuentaRelacion__r.Parent.Phone;
                
                invoiceDate = pedido.Fecha_Factura__c;
                invoiceNumber = pedido.Numero_de_Factura__c;
                poCliente = pedido.Numero_de_Orden__c;
            }
        }
        
        
        private void generateContainersItems() {
            if(containers != null) {
                containersPDF = new List<ContainerPDF>();
            
                for(Container__c cntr : containers) {
                    containersPDF.add(new ContainerPDF(cntr));
                }
            }
        }
        
        
        private void associateItemsFacturaContainer() {
            ItemDeFacturaDeCliente__c itemFactura;
        
            for(ContainerPDF cntrPdf : containersPDF) {
                for(ContainerItemPDF cntrItemPdf : cntrPdf.items) {
                    itemFactura = itemsFactura.get(cntrItemPdf.pgRef);
                    if(itemFactura != null) {
                        cntrItemPdf.brandItemInvoice = itemFactura.MarcaDeProducto__c;
                        cntrItemPdf.englishName = itemFactura.Descripcion__c;
                    }
                }
            }
        }
        
        private void genereateTotals() {
            Decimal totDecUnits = 0;
            Decimal totDecCnt = 0;
            Decimal totDecNetW = 0;
            Decimal totDecGrossW = 0;
            Decimal totDecCBM = 0;
            
            for(Container__c cntr : containers) {
                totDecUnits = totDecUnits + cntr.Total_Productos__c;
                totDecCnt = totDecCnt + cntr.Cajas__c;
                totDecNetW = totDecNetW + cntr.Total_Net_W__c;
                totDecGrossW = totDecGrossW + cntr.Total_Gross_W__c;
                totDecCBM = totDecCBM + cntr.Total_CBM__c;
            }
            
            summary = new TotalsSummaryContainersPDF();
            summary.totalQty = totDecUnits;
            summary.totalCnt = totDecCnt;
            summary.totalUnits = totDecUnits;
            summary.totalNetWt = totDecNetW;
            summary.totalGrossWt = totDecGrossW;
            summary.totalCBM = totDecCBM;
        }
    }
  
    public class ContainerPDF {
        public String containerNumber {set; get;}
        public String seal {set; get;}
        public String containerType {set; get;}
        
        public String totalWeight {set; get;}
        public String totalCBM {set; get;}
        
        public List<ContainerItemPDF> items {set; get;}
        
        private Container__c objContainer;
        private List<Container_Pedido_Line_Item__c> objContainerItems;        
        
        public ContainerPDF(Container__c pcntr) {
            objContainer = pcntr;
            containerNumber = objContainer.Name;
            seal = objContainer.SEAL__c;
            containerType = objContainer.Type__c;
            totalWeight = objContainer.Total_Gross_W__c.toString();
            totalCBM = objContainer.Total_CBM__c.toString();
            
            objContainerItems = objContainer.Container_Pedido_Line_Items1__r;
            
            generateContainerItemsPDF(objContainerItems);
        }
        
        private void generateContainerItemsPDF(List<Container_Pedido_Line_Item__c> pobjContainerItems) {
            if(pobjContainerItems != null) {
                items = new List<ContainerItemPDF>();
                for(Container_Pedido_Line_Item__c objCntrItem : pobjContainerItems) {
                    items.add(new ContainerItemPDF(objCntrItem));
                }
            }
        }
    }
    
    
    public class TotalsSummaryContainersPDF {
        public Decimal totalQty {set; get;}
        public Decimal totalCnt {set; get;}
        public Decimal totalUnits {set; get;}

        public Decimal totalNetWt {set; get;}
        public Decimal totalGrossWt {set; get;}
        public Decimal totalCBM {set; get;}

        public TotalsSummaryContainersPDF() {

        }
        
    }
    
    
    public class ContainerItemPDF {
        public String pgRef {set; get;}
        
        //marca item de factura
        public String brandItemInvoice {set; get;}
        public String spanishName {set; get;}
        public String englishName {set; get;}
        public Decimal qty {set; get;}
        public Decimal cnt {set; get;}
        public Decimal units {set; get;}
        
        Decimal decNetW;
        Decimal decGrossW;
        Decimal decCBM;        
        
        public List<ContainerItemFeaturePDF> features {set; get;}
        
        private Container_Pedido_Line_Item__c objContainerItem;
        
        public ContainerItemPDF(Container_Pedido_Line_Item__c pobjCntrItem) {
            List<String> args = new String[]{'0','number','###,###,##0.00#'};        
        
            features = new List<ContainerItemFeaturePDF>();
            objContainerItem = pobjCntrItem;
            pgRef = objContainerItem.Producto__r.ProductoBase__r.CodigoDeProductoBase__c;
            brandItemInvoice = objContainerItem.Producto__r.Codigo_Proveedor2__c;
            spanishName = objContainerItem.Producto__r.Name;
            
            englishName = objContainerItem.Producto__r.ProductoBase__r.ProductName__c;
            
            qty = objContainerItem.Total_Productos__c;
            cnt = objContainerItem.Cajas__c;
            units = objContainerItem.Total_Productos__c;
            
            features = new List<ContainerItemFeaturePDF>();
            decNetW = objContainerItem.Net_Weight__c;
            addFeature('NET WT:', String.format(decNetW.format(), args) + ' KG');
            decGrossW = objContainerItem.Gross_Weight__c;
            addFeature('GROSS WT:', String.format(decGrossW.format(), args) + ' KG');
            decCBM = objContainerItem.CBM__c;
            addFeature('CBM:', String.format(decCBM.format(), args) + ' CBM');
            addFeature('EAN:', objContainerItem.Producto__r.ProductoBase__r.Codigo_EAN2__c);
        }
        
        public void addFeature(String name, String value) {
            features.add(new ContainerItemFeaturePDF(name, value));
        }
    }
    
    public class ContainerItemFeaturePDF {
        public String featureName {set; get;}
        public String featureValue {set; get;}
        public String featureUnit {set; get;}
        public String cssClassLbl {set; get;}
        public String cssClassVal {set; get;}        
        
        public ContainerItemFeaturePDF(String pfeat, String pvalue) {
            featureName = pfeat;
            featureValue = pvalue;

            if(featureName.equals('NET WT:')) {
                cssClassLbl = 'itemfnetw';
                cssClassVal = 'itemfnetwval'; 
                featureUnit = ' KG';
            }
            if(featureName.equals('GROSS WT:')) {
                cssClassLbl = 'itemfgrossw';
                cssClassVal = 'itemfgrosswval';
                featureUnit = ' KG';
            }
            if(featureName.equals('CBM:')) {
                cssClassLbl = 'itemfcbm';
                cssClassVal = 'itemfcbmval';
                featureUnit = ' CBM';                
            }                        
            if(featureName.equals('EAN:')) {
                cssClassLbl = 'itemfean';
                cssClassVal = 'itemfeanval';
                featureUnit = '';
            }
        }
    }
    
}