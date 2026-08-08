/**
 * Container controller
 */
public class ContainerController {

    public String idPedido {get; set;}
    public String idContainer {get; set;}
    public String containerNumber {get; set;}    
    public String containerType {get; set;}
    public String containerSEAL {get; set;}
    public Decimal totalCajasContainers {get; set;}
    public Decimal totalProductosContainers {get; set;}
    //public Integer totalCajasContainers {get; set;}
    
    public List<Container__c> containers {get; set;}
    public List<PedidoDeCompra__c> pedidos {get; set;}
    public PedidoDeCompra__c pedido {get; set;}
    public Container__c container {get; set;}
    
    public List<SelectOption> containerTypeOptions {get; set;}
    public String containerTypeNew {get; set;}
    
    public List<ContainerWrapper> containersWrpr {get; set;}
    public List<ContainerPedidoLineItem> cpLineItems {get; set;}
    public Boolean isAddItems {set; get;}
    
    public ContainerTableSumarize tableSumarize {set; get;}
    
    public FileInput finputInvoice {set; get;}
    public FileInput finputPL {set; get;}
    public FileInput finputLoadingReport {set; get;}
    public List<Documento__c> invoiceDocs {set; get;}
    public List<Documento__c> plDocs {set; get;}
    //public Map<String, Documento__c> mapLoadCntrDocs {set; get;}
    public Map<String, List<Documento__c>> mapLoadCntrDocs {set; get;}
    public List<Documento__c> listDocsOrderCntr {set; get;}    

    public ContainerController() {
    //    idOrder = ApexPages.CurrentPage().getparameters().get('id');
        System.debug('No params');
    }

    /**
     * Constructor
     * @param idAccount this value must be the parent Account identifier
     */
    public ContainerController(String idPedido) {
        System.debug('param idpedido');
    }
    
    
    public ContainerController(ApexPages.StandardController stdController) {
        String cancelOp;
        Map<String, Container_Pedido_Line_Item__c> mapContainerItems;
        List<Container__c> orderContainers;        
    
        finputInvoice = new FileInput();
        finputPL = new FileInput();
        finputLoadingReport = new FileInput();
            
        pedido = (PedidoDeCompra__c)stdController.getRecord();
        isAddItems = false;
        idPedido = pedido.Id;
        System.debug('AAA id[' + idPedido + '] [' + isAddItems + ']');
        //System.debug('id[' + pedido.Id + '] name[' + pedido.Name + ']');
        if(idPedido == null) {
            idPedido = ApexPages.CurrentPage().getparameters().get('idp');
            idContainer = ApexPages.CurrentPage().getparameters().get('idc');
            cancelOp = ApexPages.CurrentPage().getparameters().get('cai');
            if(idPedido != null && idContainer != null) {
                System.debug('cai [' + cancelOp + ']');
                //if(cancelOp != null) {
                    isAddItems = true;
                //}
            }
        }
        System.debug('id[' + idPedido + '] [' + isAddItems + ']');
        pedidos = loadPedido(idPedido);
        
        loadDocuments(idPedido);
        
        System.debug('size[' + pedidos.size() + ']');
        if(pedidos.size() > 0) {
            pedido = pedidos.get(0);
            System.debug('load containers');
            orderContainers = loadContainers(pedido.Id);
            System.debug('asociate');
            relatePLItoCNLI(pedido, orderContainers);
        }
        
        containerTypeOptions = getSelectOptions(Container__c.Type__c);
        System.debug('id[' + pedido.Id + '] name[' + pedido.Name + ']');
        
        if(!isAddItems) {
            //createContainerWrapperList(loadContainers(pedido.Id));
            createContainerWrapperList(orderContainers);
        }
        if(isAddItems) {
            cpLineItems = loadPedidoLineItems(pedido.Id);
            container = loadContainer(pedido.Id, idContainer);
            mapContainerItems = loadConatinerLineItems(idContainer);
            updateCPLineItems(cpLineItems, mapContainerItems);
            
            listDocsOrderCntr = mapLoadCntrDocs.get(pedido.Id + '-' + idContainer);
        }
        
    }
    
    
    public void relatePLItoCNLI(PedidoDeCompra__c pedido, List<Container__c> listCntnrs) {
        Map<String, ContainerLineItem> mapCItems;
        Map<String, ContainerPedidoLineItem> mapItems;
        List<PedidoLineItem__c> lineItems;
        ContainerPedidoLineItem cpli;
        ContainerLineItem cli;        
        
        List<Container_Pedido_Line_Item__c> cplitems;
        
        mapItems = new Map<String, ContainerPedidoLineItem>();
        mapCItems = new Map<String, ContainerLineItem>();

        lineItems = pedido.PedidoLineItems__r;
        
        System.debug('pedido items size[' + lineItems.size() + '] listCntnrs size[' + listCntnrs.size() + ']');

        for(PedidoLineItem__c pli : lineItems) {
           cpli = mapItems.get(pli.Producto__r.CodigoDeProductoBase__c);
           if(cpli == null) {
               mapItems.put(pli.Producto__r.CodigoDeProductoBase__c, new ContainerPedidoLineItem(pli));
           } else {
               cpli.addNumberItems(pli);
           }
        }

        
        for(Container__c cntr : listCntnrs) {
            cplitems = cntr.Container_Pedido_Line_Items1__r;
            for(Container_Pedido_Line_Item__c ocpli : cplitems) {
                cli = mapCItems.get(ocpli.Producto__r.CodigoDeProductoBase__c);
                if(cli == null) {
                    mapCItems.put(ocpli.Producto__r.CodigoDeProductoBase__c, new ContainerLineItem(ocpli));                
                } else {
                    cli.addNumberItems(ocpli);
                }
            }
        }
        
        System.debug('map pedido items size[' + mapItems.size() + '] map cntr items size[' + mapCItems.size() + ']');
        
        tableSumarize = new ContainerTableSumarize(mapItems, mapCItems);
        tableSumarize.createRows();
    }
    
    
    public PageReference saveContainer() {
        Container__c newContainer;
        System.debug('idPedido[' + pedido.Id + '] num[' + containerNumber + '] seal[' + containerSEAL + '] type[' + containerTypeNew + ']');
        newContainer = new Container__c();
        newContainer.Pedido__c = pedido.Id;
        newContainer.Name = containerNumber;
        newContainer.SEAL__c = containerSEAL;
        newContainer.Type__c = containerTypeNew;
        
        if(containerNumber == null) {
        
            ApexPages.Message msgcn = new ApexPages.Message(ApexPages.Severity.Error, 'Missing Container Number');
            ApexPages.addMessage(msgcn);

            return null;
        }

        if(containerNumber.equals('')) {
            ApexPages.Message msgcn = new ApexPages.Message(ApexPages.Severity.Error, 'Missing Container Number');
            ApexPages.addMessage(msgcn);

            return null;
        }        

        if(containerSEAL == null || containerSEAL.equals('')) {
            ApexPages.Message msgcs = new ApexPages.Message(ApexPages.Severity.Error, 'Missing Container SEAL');
            ApexPages.addMessage(msgcs);
            return null;
        }
        
        insert newContainer;
        
        createContainerWrapperList(loadContainers(pedido.Id));
        //containersWrpr
        
        PageReference tempPage = ApexPages.currentPage();            
        tempPage.setRedirect(true);
        return tempPage;        
    }
    


    public PageReference deleteContainer() {
        List<Container__c> containersToDelete;
        
        String idCntr = ApexPages.CurrentPage().getparameters().get('idContainer');        
        System.debug('id container to delete [' + idCntr + ']');
        System.debug('id container NOT P delete [' + idContainer + ']');        
        
        //containersToDelete = [SELECT Id, Name FROM Container__c WHERE Id = :idCntr];
        containersToDelete = [SELECT Id, Name FROM Container__c WHERE Id = :idContainer];
        
        delete containersToDelete;
        
        //createContainerWrapperList(loadContainers(pedido.Id));
        
        PageReference tempPage = ApexPages.currentPage();            
        tempPage.setRedirect(true);
        return tempPage;
    }

    
    public PageReference saveItems() {
        
        List<Container_Pedido_Line_Item__c> containersToDelete;
        List<Container_Pedido_Line_Item__c> containersToSave;
        Container_Pedido_Line_Item__c cntrToSave;

        containersToSave = new List<Container_Pedido_Line_Item__c>();

        System.debug('idp['+ idPedido +'] idc [' + idContainer + ']');
        
        containersToDelete = [SELECT Id FROM Container_Pedido_Line_Item__c WHERE Container__c = :idContainer];
        
        delete containersToDelete;
        
        for(ContainerPedidoLineItem cpli: cpLineItems) {
            //System.debug('item [' + cpli.pedidoLineItem.Producto__r.ProductoBase__r.ProductName__c + ']  cajas [' + cpli.cantidadCajasCntr + ']');
            if(cpli.cantidadCajasCntr > 0) {
                cntrToSave = new Container_Pedido_Line_Item__c(Container__c = idContainer,
                                                               Producto__c = cpli.pedidoLineItem.Producto__c,
                                                               Cajas__c = cpli.cantidadCajasCntr,
                                                               CBM__c = cpli.cbm,
                                                               Gross_Weight__c = cpli.grossWeight,
                                                               Net_Weight__c = cpli.netWeight,
                                                               Unidades_por_Masterbox__c = cpli.pedidoLineItem.UnidadesPorMasterbox__c);
                containersToSave.add(cntrToSave);
            }
        }
        
        insert containersToSave;
        
        PageReference pageRef = new PageReference('/apex/ContainerAddToPedido');
        pageRef.getParameters().put('idp',idPedido);        
        pageRef.setRedirect(true);
        return pageRef;
    }    
    
    
    private void createContainerWrapperList(List<Container__c> containers) {
        ContainerWrapper cntnrWraper;
        containersWrpr = new List<ContainerWrapper>();
        List<Documento__c> docs;
        
        totalCajasContainers = 0;
        
        for(Container__c cntnr : containers) {
            cntnrWraper = new ContainerWrapper(cntnr);
            containersWrpr.add(cntnrWraper);
            totalCajasContainers = totalCajasContainers + cntnr.Cajas__c;
        }
        
        //debug print, delete or comment
        for(ContainerWrapper cw : containersWrpr) {
            System.debug('container id[' + cw.idContainer + '] name[' + cw.containerNumber + ']');
        }
        
        for(ContainerWrapper cntnrW : containersWrpr) {
            docs = mapLoadCntrDocs.get(cntnrW.idPedido + '-' + cntnrW.idContainer);
            if(docs != null && docs.size() > 0) {
                cntnrW.hasLoadCntrDoc = true;
                cntnrW.loadCntrDocInfo = 'UPLOADED';
                //cntnrW.imageNameInfo = 'acrobatWhite.png';
                cntnrW.imageNameInfo = 'small-ok-green.png';                
                cntnrW.imageInfoTooltip = 'Report Uploaded';                
            }
        }        
    }
    
    public List<Documento__c> loadDocuments (String idPedido) {
        List<Documento__c> listDocsCntr;
        invoiceDocs = new List<Documento__c>();
        plDocs = new List<Documento__c>();
        mapLoadCntrDocs = new Map<String, List<Documento__c>>();
    
        System.debug('LOAD DOCS');
    
        List<Documento__c> docs;
        docs = [SELECT Id, 
                       Name, 
                       Tipo_de_Documento__c, 
                       PedidoDeCompra__c, 
                       Container__c 
                  FROM Documento__c
                 WHERE PedidoDeCompra__c = :idPedido];
                 
        System.debug('doc s[' + docs.size() + ']');                 
        
        for(Documento__c doc : docs) {
            if(doc.Tipo_de_Documento__c.equals('Factura')) {
                invoiceDocs.add(doc);
            }
            if(doc.Tipo_de_Documento__c.equals('Packing List')) {
                plDocs.add(doc);
            }
            if(doc.Tipo_de_Documento__c.equals('Informe Carga de Contenedor')) {
                listDocsCntr = mapLoadCntrDocs.get(doc.PedidoDeCompra__c + '-' + doc.Container__c);
                if(listDocsCntr == null) {
                    listDocsCntr = new List<Documento__c>();
                }
                listDocsCntr.add(doc);
                mapLoadCntrDocs.put(doc.PedidoDeCompra__c + '-' + doc.Container__c, listDocsCntr);
            }
        }
        
        return null;
    }
    
    public List<Container__c> loadContainers(String idPedido) {
        totalProductosContainers = 0;
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
                                     Gross_Weight__c,
                                     Net_Weight__c,
                                     CBM__c,
                                     Cajas__c,
                                     Total_Productos__c
                                FROM Container_Pedido_Line_Items1__r
                             )
                        FROM Container__c
                        WHERE Pedido__c = :idPedido];

        for(Container__c cntr : containers) {
            totalProductosContainers = totalProductosContainers + cntr.Total_Productos__c;
        }

        return containers;
    }
    
    
    public Container__c loadContainer(String idPedido, String idContainer) {
        Container__c result;
        List<Container__c> containersAddItems;
        containers = [SELECT Id,
                             Name,
                             Cajas__c,                             
                             Pedido__c,
                             Pedido__r.Name,
                             Fecha_Carga_Contenedor__c,
                             SEAL__c,
                             Type__c
                        FROM Container__c
                       WHERE Pedido__c = :idPedido
                         AND Id = :idContainer];
                         
        if(containers.size() > 0) {
            result = containers.get(0);
        }
        return result;
    }
    
    
    public List<PedidoDeCompra__c> loadPedido(String idPedido) {
        pedidos = [SELECT Id,
                          Name,
                          Proveedor__c,
                          Proveedor__r.Name,
                          Total_Cantidad__c,
                          Fecha_Factura_Proveedor__c,
                          Numero_de_Factura_Proveedor__c,
                          Fecha_de_Carga_de_Contenedor__c,
                          Total_Cajas__c,
                          (
                            SELECT Id, 
                                   Name, 
                                   Producto__c, 
                                   Producto__r.Name, 
                                   Producto__r.CodigoDeProductoBase__c, 
                                   Producto__r.Codigo_EAN2__c,
                                   Producto__r.ProductName__c,
                                   Producto__r.Codigo_Proveedor2__c,
                                   Producto__r.ProductoBase__r.ProductName__c,
                                   Producto__r.ProductoBase__r.IDImagen1__c,
                                   PedidoDeCompra__c, 
                                   PedidoDeCompra__r.Name,
                                   NumeroDeCajas__c,
                                   UnidadesPorMasterbox__c,
                                   Unidades__c 
                              FROM PedidoLineItems__r 
                          )
                     FROM PedidoDeCompra__c
                    WHERE Id = :idPedido];
        return pedidos;
    }
    
    
    public List<ContainerPedidoLineItem> loadPedidoLineItems(String idPedido) {
        Map<String, ContainerPedidoLineItem> mapItems;
        List<PedidoLineItem__c> lineItems;
        List<ContainerPedidoLineItem> clineItems;
        ContainerPedidoLineItem cpli;
        
        mapItems = new Map<String, ContainerPedidoLineItem>();
        clineItems = new List<ContainerPedidoLineItem>();

        lineItems = [SELECT Id, 
                            Name, 
                            Producto__c, 
                            Producto__r.Name, 
                            Producto__r.CodigoDeProductoBase__c, 
                            Producto__r.Codigo_EAN2__c,
                            Producto__r.ProductName__c,
                            Producto__r.Codigo_Proveedor2__c,
                            Producto__r.ProductoBase__r.ProductName__c,
                            Producto__r.ProductoBase__r.IDImagen1__c,
                            PedidoDeCompra__c, 
                            PedidoDeCompra__r.Name,
                            NumeroDeCajas__c,
                            UnidadesPorMasterbox__c,
                            Unidades__c 
                       FROM PedidoLineItem__c 
                      WHERE PedidoDeCompra__c = :idPedido];
                      
        for(PedidoLineItem__c pli : lineItems) {
           cpli = mapItems.get(pli.Producto__r.CodigoDeProductoBase__c);
           if(cpli == null) {
               mapItems.put(pli.Producto__r.CodigoDeProductoBase__c, new ContainerPedidoLineItem(pli));
           } else {
               cpli.addNumberItems(pli);
           }
        }
        
        for(String prodCod : mapItems.KeySet()) {
            clineItems.add(mapItems.get(prodCod));
        }
        
        return clineItems;
    }
    
    private Map<String, Container_Pedido_Line_Item__c> loadConatinerLineItems(String idContainer) {
        List<Container_Pedido_Line_Item__c> containerItems;
        Map<String, Container_Pedido_Line_Item__c> mapContainerItems;
        mapContainerItems = new Map<String, Container_Pedido_Line_Item__c>();
        
        containerItems = [SELECT Id, 
                                 Producto__c, 
                                 Cajas__c,
                                 CBM__c,
                                 Gross_Weight__c,
                                 Net_Weight__c
                            FROM Container_Pedido_Line_Item__c 
                           WHERE Container__c = :idContainer];
        
        for(Container_Pedido_Line_Item__c cplio : containerItems) {
            mapContainerItems.put(cplio.Producto__c, cplio);
        }
        
        System.debug('map idcontnr[' + idContainer + '] size[' + mapContainerItems.size() + ']');
        
        return mapContainerItems;
    }
    
    
     private void updateCPLineItems(List<ContainerPedidoLineItem> cpLineItems, Map<String, Container_Pedido_Line_Item__c> mapContainerItems) {
         Container_Pedido_Line_Item__c cplio;
         for(ContainerPedidoLineItem cpli : cpLineItems) {
             cplio = mapContainerItems.get(cpli.pedidoLineItem.Producto__c);
             if(cplio != null) {
                 System.debug('found');
                 cpli.cantidadCajasCntr = cplio.Cajas__c;
                 cpli.netWeight = cplio.Net_Weight__c;
                 cpli.grossWeight = cplio.Gross_Weight__c;
                 cpli.cbm = cplio.CBM__c;                 
             }
         }
     }
    
    
    private List<SelectOption> getSelectOptions(SObjectField pobjField) {
        List<SelectOption> listSelectOptions = new List<SelectOption>();
        Schema.DescribeFieldResult fieldList =  pobjField.getDescribe();
        List<Schema.PicklistEntry> ple = fieldList.getPicklistValues();
        for( Schema.PicklistEntry pickListValue : ple) {
           listSelectOptions.add(new SelectOption(pickListValue.getValue(), pickListValue.getLabel()));
        }
        return listSelectOptions;
    }
    


    public Pagereference saveOrder() {
    
        System.debug('order f[' + pedido.Numero_de_Factura_Proveedor__c + '] order d[' + pedido.Fecha_Factura_Proveedor__c + ']');
    
        uploadFile(finputInvoice, pedido.Id, null, 'Pedido Fábrica', 'Factura');
        uploadFile(finputPL, pedido.Id, null, 'Pedido Fábrica', 'Packing List');

        update pedido;

        /*ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Thank you for updating the Packing List. Pacific Global team will review them and contact you if any further information is necessary'));*/

        PageReference pageRef = new PageReference('/' + pedido.Id);
        pageRef.setRedirect(false);
        return pageRef;
    }
    
    public Pagereference saveOrderC() {

        // save items    
        List<Container_Pedido_Line_Item__c> containersToDelete;
        List<Container_Pedido_Line_Item__c> containersToSave;
        Container_Pedido_Line_Item__c cntrToSave;

        containersToSave = new List<Container_Pedido_Line_Item__c>();

        System.debug('idp['+ idPedido +'] idc [' + idContainer + ']');
        // save items fin   
    
        System.debug('save container f[' + container.Fecha_Carga_Contenedor__c + '] idpedido[' + pedido.Id + ']');
        
        System.debug('f[' + finputLoadingReport.fileName + '] [' + finputLoadingReport.fileBody +']');        
        
        uploadFile(finputLoadingReport, pedido.Id, container.Id, 'Producción', 'Informe Carga de Contenedor');

        update container;
        
        // save items
        containersToDelete = [SELECT Id FROM Container_Pedido_Line_Item__c WHERE Container__c = :idContainer];
        delete containersToDelete;
        
        for(ContainerPedidoLineItem cpli: cpLineItems) {
            //System.debug('item [' + cpli.pedidoLineItem.Producto__r.ProductoBase__r.ProductName__c + ']  cajas [' + cpli.cantidadCajasCntr + ']');
            if(cpli.cantidadCajasCntr > 0) {
                cntrToSave = new Container_Pedido_Line_Item__c(Container__c = idContainer,
                                                               Producto__c = cpli.pedidoLineItem.Producto__c,
                                                               Cajas__c = cpli.cantidadCajasCntr,
                                                               CBM__c = cpli.cbm,
                                                               Gross_Weight__c = cpli.grossWeight,
                                                               Net_Weight__c = cpli.netWeight,
                                                               Unidades_por_Masterbox__c = cpli.pedidoLineItem.UnidadesPorMasterbox__c);
                containersToSave.add(cntrToSave);
            }
        }
        
        insert containersToSave;
        
        // save items fin
        
        System.debug('cancel container items');
        PageReference pageRef = new PageReference('/apex/ContainerAddToPedido');
        pageRef.getParameters().put('idp',idPedido);
        pageRef.setRedirect(true);
        return pageRef;
        
        //return null;
    } 
    
    public Pagereference cancelCntnrs() {
        PageReference pageRef = new PageReference('/' + pedido.Id);
        pageRef.setRedirect(false);
        return pageRef;    
    }


    public Pagereference cancelCntnrItems() {
        System.debug('cancel container items');
        //PageReference pageRef = new PageReference('/apex/ContainerAddToPedido/idp=' + pedido.Id + '&cai=t');
        //pageRef.setRedirect(false);
        //return pageRef;
        return Page.ContainerAddToPedido;
    }
    
    public void uploadFile(FileInput finput, String idOrder, String idContainer, String documentProcess, String type) {
        RecordType rtDocPedido;
        
        rtDocPedido = DOBrandsDAO.getRecordType('Documentacion_Pedido', 'Documento__c');
        
        Documento__c doc = new Documento__c();
        doc.PedidoDeCompra__c = idOrder;
        doc.Container__c = idContainer;
        doc.RecordTypeId = rtDocPedido.Id;
        doc.Proceso__c = documentProcess;
        doc.Tipo_de_Documento__c = type;
        doc.Name = finput.fileName;

        Id contentDocumentId;
        ContentVersion cv = new ContentVersion();
        ContentVersion cvl;
        ContentDocumentLink cdl = new ContentDocumentLink();

        System.debug('fname[' + finput.fileName + '] fb[' + finput.fileBody + '] idor[' + idOrder + ']');

        if(finput.fileName != null && finput.fileBody != null && idOrder != null) {
            insert doc;
            
            System.debug('INSERT DOC');

            cv.ContentLocation = 'S';
            cv.ContentDocumentId = contentDocumentId;
            cv.VersionData = finput.fileBody;
            cv.Title = type + '-' + finput.fileName;
            cv.PathOnClient = finput.fileName;

            insert cv;

            cvl = [SELECT ContentDocumentId
                     FROM ContentVersion
                    WHERE Id = :cv.Id];

            cdl.ContentDocumentId = cvl.ContentDocumentId;
            cdl.LinkedEntityId = doc.Id;
            cdl.ShareType = 'I';

            insert cdl;

            doc.Archivo_Principal__c = cvl.ContentDocumentId;
            update doc;
    
        }

    }


    /*
     * Inner class controller
     */
    public class FileInput  {
        public Blob fileBody {get;set;}
        public String fileName {get;set;}
    }    
    
 
 
    public class ContainerTableSumarize {
        public Map<String, ContainerPedidoLineItem> mapCPLI {set; get;}
        public Map<String, ContainerLineItem> mapCLI {set; get;}
        private ContainerPedidoLineItem cpli;
        private ContainerLineItem cli;
        public List<ContainerTableRow> tableRows {set; get;}
        private ContainerTableRow tableRow;
        
        public Decimal totalProds {set; get;}
        public Decimal totalBox {set; get;}
        public Decimal totalProdsCntr {set; get;}
        public Decimal totalBoxCntr {set; get;}
        public Decimal totalProdsRemain {set; get;}
        public Decimal totalBoxRemain {set; get;}
                
        
        public ContainerTableSumarize(Map<String, ContainerPedidoLineItem> pmapCPLI, Map<String, ContainerLineItem> pmapCLI) {
            mapCPLI = pmapCPLI;
            mapCLI = pmapCLI;
            totalProds = 0;
            totalBox = 0;
            totalProdsCntr = 0;
            totalBoxCntr = 0;
            totalProdsRemain = 0;
            totalBoxRemain = 0;
        }
        
        public void createRows() {
            tableRows = new List<ContainerTableRow>();
            for(String plikey : mapCPLI.keySet()) {
                cpli = mapCPLI.get(plikey);
                cli = mapCLI.get(plikey);
                tableRow = new ContainerTableRow(cpli, cli);
                tableRows.add(tableRow);
            }
            
            for(ContainerTableRow ctr : tableRows) {
                totalProds = totalProds + ctr.decTotalProd;
                totalBox = totalBox + ctr.decTotalCajas;
                totalProdsCntr = totalProdsCntr + ctr.decTotalProdCntr;
                totalBoxCntr = totalBoxCntr + ctr.decTotalCajasCntr;
                totalProdsRemain = totalProdsRemain + ctr.decFaltanteProds;
                totalBoxRemain = totalBoxRemain + ctr.decFaltanteCajas;
            }
        }
        
    }
    
    
  
    
    public class ContainerTableRow {
        public ContainerPedidoLineItem cpli {set; get;}
        public ContainerLineItem cli {set; get;}
        public String nameProd {set; get;}
        public String pgref {set; get;}
        public String factoryref {set; get;}                
        
        public Decimal decTotalProd {set; get;}
        public Decimal decTotalCajas {set; get;}
        public Decimal decTotalProdCntr {set; get;}
        public Decimal decTotalCajasCntr {set; get;}
        public Decimal decFaltanteProds {set; get;}
        public Decimal decFaltanteCajas {set; get;}
        
        
        public ContainerTableRow (ContainerPedidoLineItem pcpli, ContainerLineItem pcli) {
            cpli = pcpli;
            cli = pcli;
            nameProd = pcpli.pedidoLineItem.Producto__r.ProductoBase__r.ProductName__c;
            //pgref = pcpli.pedidoLineItem.Producto__r.ProductoBase__r.CodigoDeProductoBase__c;
            pgref = pcpli.pedidoLineItem.Producto__r.CodigoDeProductoBase__c;            
            //factoryref = pcpli.pedidoLineItem.Producto__r.ProductoBase__r.Codigo_Proveedor2__c;
            factoryref = pcpli.pedidoLineItem.Producto__r.Codigo_Proveedor2__c;            
            
            decTotalProd = pcpli.cantidadTotalItems;
            decTotalCajas = pcpli.cantidadTotalCajas;
            if(pcli != null) {
                decTotalProdCntr = pcli.cantidadTotalItems;
                decTotalCajasCntr = pcli.cantidadTotalCajas;
            } else {
                decTotalProdCntr = 0;
                decTotalCajasCntr = 0;
            }
            
            decFaltanteProds = decTotalProd - decTotalProdCntr;
            decFaltanteCajas = decTotalCajas - decTotalCajasCntr;
        }
        
    }
    
 
    public class ContainerLineItem {

        public Container_Pedido_Line_Item__c containerLineItem {set; get;}
        public Decimal cantidadTotalItems {set; get;}
        public Decimal cantidadTotalCajas {set; get;}
        public Decimal cantidadCajasCntr {set; get;}
        public Decimal netWeight {set; get;}
        public Decimal grossWeight {set; get;}
        public Decimal cbm {set; get;}

        public ContainerLineItem () {
            cantidadTotalItems = 0;
            cantidadTotalCajas = 0;
        }


        public ContainerLineItem (Container_Pedido_Line_Item__c ocpli) {
            cantidadTotalItems = 0;
            cantidadTotalCajas = 0;
            containerLineItem = ocpli;
            cantidadTotalItems = ocpli.Total_Productos__c;
            cantidadTotalCajas = ocpli.Cajas__c;
        }
    
    
        public void addNumberItems(Container_Pedido_Line_Item__c ocpli) {
            cantidadTotalItems = cantidadTotalItems + ocpli.Total_Productos__c;
            cantidadTotalCajas = cantidadTotalCajas + ocpli.Cajas__c;
        }
    
    }
    
}