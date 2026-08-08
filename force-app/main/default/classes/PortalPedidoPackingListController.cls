public class PortalPedidoPackingListController {
    private static String UNAVAILABLE_TOKEN = Label.PORTAL_UNAVAILABLE_TOKEN;
    private static String INVALID_TOKEN = Label.PORTAL_INVALID_TOKEN;
    private static String STANDARD_USER = 'Standard';

    public String token {set; get;}
    public String orderNumber {set; get;}

    public String idUserTask {set; get;}
    public PedidoDeCompra__c order {set; get;}
    public Boolean isButtonAddProdEnabled {set; get;}
    public Boolean isFinish {set; get;}

    public Boolean isPageShowed {set; get;}

    public PackingList__c packingList {set; get;}
    public FileInput finputInvoice {set; get;}
    public FileInput finputPL {set; get;}
    public FileInput finputLoadingReport {set; get;}    
    private RecordType rtDocPedido;
    public String plComments {set; get;}
    public String strContainerLoadDate {set; get;}

    public Decimal totalNetWgt {set; get;}
    public Decimal totalGrossWgt {set; get;}
    public Decimal totalCBM {set; get;}

    public String userType {set; get;}

    public List<PortalPedidoLineItem> portalLineItems {set; get;}
    public String numeroFacturaProveedor {set; get;}

    public PortalPedidoPackingListController() {
        token = ApexPages.CurrentPage().getparameters().get('dbrToken');
        orderNumber = ApexPages.CurrentPage().getparameters().get('orderName');
        isPageShowed = true;
        finputInvoice = new FileInput();
        finputPL = new FileInput();
        finputLoadingReport = new FileInput();
    }

    public Pagereference loadPage() {
        List<String> idUsers;
        RecordType rt;
        PackingList__c pl;
        String sociedadName = '';
        String yearorder = '';
        String numOrdr = '';

        portalLineItems = new List<PortalPedidoLineItem>();

        userType = UserInfo.getUserType();

        rtDocPedido = DOBrandsDAO.getRecordType('Documentacion_Pedido', 'Documento__c');

        isButtonAddProdEnabled = True;
        rt = DOBrandsDAO.getRecordType('Principal', 'PedidoDeCompra__c');

        if(!userType.equals(STANDARD_USER)) {
            if(token == null) {
                isButtonAddProdEnabled = False;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, UNAVAILABLE_TOKEN));
            } else {
                order = DOBrandsDAO.getOrderByToken(token);
                if(order == null) {
                    isButtonAddProdEnabled = False;
                    isPageShowed = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVALID_TOKEN));
                    return null;
                }
                pl = DOBrandsDAO.getPackingListByOrder(order.Id);
            }
        } else {
            order = DOBrandsDAO.getOrderByNumber(orderNumber);
            if(order == null) {
                return null;
            }
            pl = DOBrandsDAO.getPackingListByOrder(order.Id);            
        }

        String soc = getSociedadAccount(order.Proforma__r.Cuenta__r.ParentId);
        if(soc != null && soc.equals('Do Core')) {
            sociedadName = 'CO';
        }

        yearorder = order.Name.substring(2,4);
        numOrdr = order.Name.substring(4,7);

        String packingListName = 'PL' + sociedadName + yearorder + '_' + numOrdr;
        
        if(pl == null) {
            packingList = new PackingList__c(Pedido__c = order.Id, Name = packingListName);
        } else {
            packingList = pl;
        }

        //populate portal objects
        for(PedidoLineItem__c pli : order.PedidoLineItems__r) {
            portalLineItems.add(new PortalPedidoLineItem(pli));
        }

        //Tarea_Aportacion__mdt
        idUsers = getIdUsersTasks();
        idUserTask = idUsers.get(0); 

        updateQuantity(order.PedidoLineItems__r);
        getTotals(order.PedidoLineItems__r);

        return null;
    }


    public Pagereference savePL() {
        Task task;
        List<PedidoLineItem__c> pedidoLineItems;

        packingList.Comentarios__c = plComments;
        upsert packingList;

        //update values
        System.debug('Updating values ...');
        for(PortalPedidoLineItem prpli : portalLineItems) {
            prpli.updateValues();
            System.debug('PR-PLI[' + prpli.pli.Quantity__c + '] [' + prpli.pli.Total_Cnts__c + '] [' + prpli.pli.Net_Weight__c + '] [' + prpli.pli.Gross_Weight__c + '] [' + prpli.pli.CBM__c + '] [' + prpli.pli.Container_Number__c + '] [' + prpli.pli.SEAL_Number__c + ']');
        }

        pedidoLineItems = order.PedidoLineItems__r;
        for(PedidoLineItem__c pli : pedidoLineItems) {
            pli.PackingList__c = packingList.Id;
            System.debug('PLI [' + pli.Quantity__c + '] [' + pli.Total_Cnts__c + '] [' + pli.Net_Weight__c + '] [' + pli.Gross_Weight__c + '] [' + pli.CBM__c + '] [' + pli.Container_Number__c + '] [' + pli.SEAL_Number__c + ']');
        }
         
        update pedidoLineItems;

        for(PedidoLineItem__c pli : pedidoLineItems) {
            System.debug('UPD PLI [' + pli.Quantity__c + '] [' + pli.Total_Cnts__c + '] [' + pli.Net_Weight__c + '] [' + pli.Gross_Weight__c + '] [' + pli.CBM__c + '] [' + pli.Container_Number__c + '] [' + pli.SEAL_Number__c + ']');
        }

        uploadFile(finputInvoice, order.Id, 'Pedido Fábrica', 'Factura');
        uploadFile(finputPL, order.Id, 'Pedido Fábrica', 'Packing List');
        uploadFile(finputLoadingReport, order.Id, 'Producción', 'Informe Carga de Contenedor');

        System.debug('numFactprov [' + numeroFacturaProveedor + ']');
        order.Numero_de_Factura_Proveedor__c = numeroFacturaProveedor;
        
        System.debug('order numFactprov [' + order.Numero_de_Factura_Proveedor__c + ']');

        update order;

        System.debug('U numFactprov [' + order.Numero_de_Factura_Proveedor__c + ']');

        task = createTask('Portal-Packing List', 'Packing List para pedido ' + order.Name,'Abierta', 'Normal', order.Id, idUserTask);
        insert task;

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Thank you for updating the Packing List. DO-Brands team will review them and contact you if any further information is necessary'));

        PageReference pageRef = new PageReference('/apex/PortalFinalizarPackingList');
        pageRef.setRedirect(false);
        return pageRef;
    }

    private void updateQuantity(List<PedidoLineItem__c> pedidoLineItems) {
        for(PedidoLineItem__c pli : pedidoLineItems) {
            if(pli.Quantity__c == null) {
                pli.Quantity__c = pli.Unidades__c;
            }
        }
    }


    private void getTotals(List<PedidoLineItem__c> pedidoLineItems) {

        totalNetWgt = 0;
        totalGrossWgt = 0;
        totalCBM = 0;
    
        for(PedidoLineItem__c pli : pedidoLineItems) {
            totalNetWgt = totalNetWgt + (pli.Net_Weight__c == null ? 0 : pli.Net_Weight__c);
            totalGrossWgt = totalGrossWgt + (pli.Gross_Weight__c == null ? 0 : pli.Gross_Weight__c);
            totalCBM = totalCBM + (pli.CBM__c == null ? 0 : pli.CBM__c);
        }
    }



    private List<String> getIdUsersTasks() {
        List<Tarea_Aportacion__mdt> mdts;
        List<String> idUsers = new List<String>();

        mdts = [SELECT Id, Usuario__c, MasterLabel FROM Tarea_Aportacion__mdt WHERE MasterLabel = 'portalProveedorPackingList'];
        for(Tarea_Aportacion__mdt mdt : mdts) {
            idUsers.add(mdt.Usuario__c);
        }

        return idUsers;
    }

    private Task createTask(String subject, String description, String status, String priority, String whatId, String ownerId) {
        Task task = new Task();
        task.Subject = subject;
        task.Status = status;
        task.Priority = priority;
        task.Description = description;
        task.WhatId = whatId;
        task.OwnerId = ownerId;
        task.ActivityDate = System.today();
        task.isReminderSet = true;
        task.reminderDateTime = Datetime.now();
        return task;
    }


    private String getSociedadAccount(String idAccount) {
        Account acc;
        List<Account> accs;
        String sociedad = '';
        accs = [SELECT Id, Name, Sociedad__c FROM Account WHERE Id = :idAccount];
        if(!accs.isEmpty()) {
            acc = accs.get(0);
            sociedad = acc.Sociedad__c;
        }
        return sociedad;
    }


    public void uploadFile(FileInput finput, String idOrder, String documentProcess, String type) {

        Documento__c doc = new Documento__c();
        doc.PedidoDeCompra__c = idOrder;
        doc.RecordTypeId = rtDocPedido.Id;
        doc.Proceso__c = documentProcess;
        doc.Tipo_de_Documento__c = type;
        doc.Name = type;

        Id contentDocumentId;
        ContentVersion cv = new ContentVersion();
        ContentVersion cvl;
        ContentDocumentLink cdl = new ContentDocumentLink();

        if(finput.fileName != null && finput.fileBody != null && idOrder != null) {
            insert doc;

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

}