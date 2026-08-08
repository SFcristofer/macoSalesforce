/**
 * iestrada   2020-06-25  Change file names attached in email
 *                        Use email template instead body text
 * 
 * Helper class used in Pedido trigger
 */
public with sharing class PedidoTriggerHelper {
    public static final String INS = 'ins';
    public static final String DEL = 'del';
    public static final String UPD = 'upd';
    
    public static final String AFT = 'after';
    public static final String BEF = 'before';
        
    private String oper;
    private String whenFired;
    
    private static final String SIM = 'SIMULACION';
    private static list<PedidoDeCompra__c> pedidos;
    private String TERMINATOR = 'T-800';
    private String STATUS_EMBARCADO = 'EMBARCADO';
    private Map<String, Boolean> actionsConfig;
    private List<PedidoDeCompra__c> pedidosQB;
 
    //Validate documents
    private Map<Id, PedidoDeCompra__c> oldPedidosMap;
    private List<String> shippedOrdersIds;    

    private static String RECORDTYPE_DOCDO_PEDIDO = 'Documentacion_Pedido';
    private static String DOC_BL = 'BL';
    private static String DOC_FACTURA = 'Factura';
    private static String DOC_PACKING_LIST = 'Packing List';
    private static String CLIENT_DOC_PROCESS = 'Documentación del Cliente';
    private List<String> idsDocumentos;
    private List<String> tiposDocumento;

    public static String LABEL_MAIL_SUBJECT = Label.ORDER_MAIL_SUBJECT;
    public static String LABEL_MAIL_BODY = Label.ORDER_MAIL_BODY;

    public static String LABEL_TASK_SUBJECT = Label.PEDIDO_TRIGGER_TASK_SUBJECT;
    public static String LABEL_TASK_DESC = Label.PEDIDO_TRIGGER_TASK_DESC;

    public static String LABEL_TASK_OK_SUBJECT = Label.PEDIDO_TRIGGER_OK_TASK_SUBJECT;
    public static String LABEL_TASK_OK_DESC = Label.PEDIDO_TRIGGER_OK_TASK_DESC;

    public PedidoTriggerHelper() {
    }

    public PedidoTriggerHelper(list<PedidoDeCompra__c> pdc, String oper, String whenFired,  Map<String, Boolean> actions) {
        pedidos = pdc;
        this.oper = oper;
        this.whenFired = whenFired;
        System.debug('PedidoTriggerHelper [' + this.oper + '] [' + this.whenFired + ']');
        tiposDocumento = new List<String>{DOC_BL, DOC_FACTURA, DOC_PACKING_LIST};
        actionsConfig = actions;
        pedidosQB = new List<PedidoDeCompra__c>();
    }

    public PedidoTriggerHelper(list<PedidoDeCompra__c> pdc, String oper, Map<Id, PedidoDeCompra__c> oldMap, Map<String, Boolean> actions) {
        pedidos = pdc;
        this.oper = oper;
        oldPedidosMap = oldMap;
        shippedOrdersIds = new List<String>();
        tiposDocumento = new List<String>{DOC_BL, DOC_FACTURA, DOC_PACKING_LIST};
        actionsConfig = actions;
        pedidosQB = new List<PedidoDeCompra__c>();
    }

    public void execute() {
        PedidoDeCompra__c singleOrder;
        
        String idAgente;
        System.debug('PedidoTriggerHelper [' + this.oper + ']');
        if(this.oper == DEL)
        {
            /* Formerly only usert with 'T-800' alias was allowed to delete Pedido__c records
             Now we are allowing any sysadmin to do it */
            User u = [SELECT Id,
                             alias,
                             Profile.PermissionsModifyAllData
                        FROM User
                       WHERE Id = :UserInfo.getUserId()
                             limit 1];
            if(!u.Profile.PermissionsModifyAllData){
                pedidos[0].addError('No tiene permiso de eliminar Pedidos. Consulte a un Administrador');
            }
            
        }
        
        
        if(this.oper == INS && this.whenFired == BEF) {
            idAgente = getIdAgentePrederminado();//Cuenta_Agente_DO__c       
            for(PedidoDeCompra__c pedido : pedidos) {
                pedido.Cuenta_Agente_DO__c = idAgente;
                System.debug('INS BEF pedidos name[' + pedido.Name + ']');
                if(pedido.Name != null && !pedido.Name.startsWith('PE') && !pedido.Name.contains(SIM)) {
                    //pedido.Name = Util.getIncrement('pedido');
                    pedido.Name = Util.getIncrement('pedido', pedido.Planificacion_Comercial__c);
                }
            }
        }
        
        if(this.oper == INS && this.whenFired == AFT) {
            for(PedidoDeCompra__c pedido : pedidos) {
                System.debug('INS AFT pedidos name[' + pedido.Name + ']');
                if(pedido.Name != null && !pedido.Name.contains(SIM)) {
                    pedidosQB.add(pedido);
                }                
            }
            
            System.debug('pedidosQB size[' + pedidosQB.size() + ']');
            
            if(pedidosQB.size() == 1) {
                singleOrder = pedidosQB.get(0);
                singleOrder = getPedido(singleOrder.Id);
                System.debug('INS AFT pedidoId[' + singleOrder.Id + ']');
                if(actionsConfig.get('QBAddCustomer')) {
                    System.debug('Adding customer to QB');                
                    if(singleOrder.Proforma__r.Cuenta__r.Parent.IdQbo__c == null) {
                        //agregar a QB
                        System.debug('Add customer to QB  customerId[' + singleOrder.Proforma__r.Cuenta__r.ParentId + '] [' + singleOrder.Proforma__r.Cuenta__r.Parent.Name + ']');
                        addQB(singleOrder.Proforma__r.Cuenta__r.ParentId);
                    }
                }
                if(actionsConfig.get('QBAddVendor')) {
                    System.debug('Adding vendor to QB');
                    if(singleOrder.Proveedor__r.IdQbo__c == null) {
                        //agregar a QB
                        System.debug('Add vendor to QB vendorId[' + singleOrder.Proveedor__c + '] [' + singleOrder.Proveedor__r.Name + ']');
                        addQB(singleOrder.Proveedor__c);
                    }
                }
            }
        }

        if(this.oper == UPD) {
            PedidoDeCompra__c orderToUpdate;
            PedidoDeCompra__c oldPedido;
            List<PedidoDeCompra__c> pedidosReady = new List<PedidoDeCompra__c>();
            List<PedidoDeCompra__c> shippedOrders = new List<PedidoDeCompra__c>();
            for(PedidoDeCompra__c pedido : pedidos) {
                if(isReadyToSend(pedido)) {
                    //pedidosReady.add(pedido);
                }
                if(!pedido.Name.contains(SIM)) {
                    pedidosQB.add(pedido);
                }
                //Check if status2 has changed to 'EMBARCADO'
                oldPedido = oldPedidosMap.get(pedido.Id);
                System.debug('pedido[' + pedido.Estado2__c + ']  oldPedido[' + oldPedido.Estado2__c + ']');
                if(oldPedido.Estado2__c != null && pedido.Estado2__c != null) { // ??  porque UPD 
                    if(pedido.Estado2__c.equals(STATUS_EMBARCADO) && !oldPedido.Estado2__c.equals(STATUS_EMBARCADO)) {
                        shippedOrders.add(pedido);
                        shippedOrdersIds.add(pedido.Id);
                    }
                }
            }

            if(!shippedOrdersIds.isEmpty()) {
                //generate documents
                generateDocuments(shippedOrdersIds, tiposDocumento);

                //send email will be added in as part of trigger

                //aportaciones
                generateAportaciones(shippedOrders);
            }
        }
    }

    private Boolean isReadyToSend(PedidoDeCompra__c pedido) {
        Boolean result = true;
        if(pedido.Booking_Agente__c == null) {
           result = result & false; 
           System.debug('No Booking_Agente__c');
        }
        if(pedido.Fecha_Minima_Embarque__c == null) {
            result = result & false;
        }
        if(pedido.Fecha_Maxima_Embarque__c == null) {
            result = result & false;
        }
        System.debug('isReadyToSend [' + result + ']');
        return result;
    }

    @Future(callout=true)
    public static void generateDocuments(List<String> idOrdersEmbarcado, List<String> tiposDocumento) {
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment att;
        Blob blobPDFFactura;
        Blob blobPDFPacking;
        Blob blobPDFBL;
        List<Documento__c> documents;
        List<PedidoDeCompra__c> orders;
        List<PedidoDeCompra__c> ordersToUpdate;        
        List<String> idsDocumentos = new List<String>();
        OrderDocuments orderDoc;
        List<OrderDocuments> ordersDocs = new List<OrderDocuments>();
        List<ContentDocumentLink> docLinks;
        List<String> idsContentVersion = new List<String>();
        List<ContentVersion> contentsVersions;
        Map<String, OrderDocuments> mapCVOrderDoc = new Map<String, OrderDocuments>();
        List<Task> tasks = new List<Task>();
        Map<String, PackingList__c> mapIdOrderPL;
        PackingList__c pl;
        RecordType rt;
        List<String> proformaCuentaIds = new List<String>();
        Map<String, String> accountContactMap;
        String idContact;
        String accSociedad;

        ordersToUpdate = new List<PedidoDeCompra__c>();      
        rt = DOBrandsDAO.getRecordType('Documentacion_Pedido', 'Documento__c');

        //get 'EMBARCADO' state orders 
        orders = DOBrandsDAO.getOrdersDocuments(idOrdersEmbarcado, tiposDocumento);

        //get map packing lists, order
        mapIdOrderPL = DOBrandsDAO.getPackingList(idOrdersEmbarcado);

        //For each order creates an OrderDocument objet
        //OrderDocument is a wrapper of order, its packinglist and its documents
        for(PedidoDeCompra__c order : orders) {
            orderDoc = new OrderDocuments(order);

            //we will use packinglist in order to verify
            //it it has been approved
            pl = mapIdOrderPL.get(order.Id);
            if(pl != null) {
                orderDoc.packingList = pl;
            }

            proformaCuentaIds.add(order.Proforma__r.Cuenta__c);

            ordersDocs.add(orderDoc);
            documents = order.Documentos__r;
            if(!documents.isEmpty()) {
                //associate each document__c from order to wrapper OrderDocument
                for(Documento__c doc : documents) {
                    System.debug('doctipo [' + doc.Tipo_de_Documento__c + '] [' + doc.Proceso__c +'] [' + doc.Id + '] [' + doc.Archivo_Principal__c + ']');
                    processDocument(doc, orderDoc, idsDocumentos, mapCVOrderDoc);
                }
            }
        }

        //get document links associated to Documento__c
        if(!idsDocumentos.isEmpty()) {
            docLinks = DOBrandsDAO.getContentDocumentLink(idsDocumentos);
        }

        //get the Content Version Id's from document link
        if(docLinks != null ) {
            for(ContentDocumentLink dLink : docLinks) {
                idsContentVersion.add(dLink.ContentDocumentId);
            }
        }

        //get the content version 
        contentsVersions = DOBrandsDAO.getContentVersions(idsContentVersion);

        for(ContentVersion cv : contentsVersions) {
            orderDoc = mapCVOrderDoc.get(cv.ContentDocumentId);
            if(orderDoc != null) {
                //if the order already has a document it is added to wrapper
                orderDoc.addBlob(cv.ContentDocumentId, cv);
            }
        }

        accountContactMap = getAccountContactMap(proformaCuentaIds);

        //for each OrderDocument wrapper:
        //- if it has the complete documents (Invoice, BL, PL) creates a task 
        //- if it has not the comlete documents. Invoice and PL are generated and attached to order
        //- if BL is missing creates a task
        for(OrderDocuments orderDocP : ordersDocs) {

            LABEL_MAIL_SUBJECT = LABEL_MAIL_SUBJECT.replace('{0}', orderDocP.order.Name);
            LABEL_MAIL_BODY = LABEL_MAIL_BODY.replace('{0}', orderDocP.order.Name);

            //Validate order
            orderDocP.validateOrder();

            //if the order contains the documents (invoice, bl, pl) it is
            if(orderDocP.isReadyToSend()) {

                // create a task and notify the order has 'shipped' status
                String taskDesc = LABEL_TASK_OK_DESC;
                taskDesc = taskDesc.replace('{0}', orderDocP.order.Name);
                tasks.add(createTask(LABEL_TASK_OK_SUBJECT, taskDesc, 'Abierta', 'Normal', orderDocP.order.Id, orderDocP.order.OwnerId));

                orderDocP.order.Documentos_Embarcado_Completos__c = true;
                ordersToUpdate.add(orderDocP.order);
            } else {
                if(orderDocP.isPackingListApproved()) {     
                    
                    accSociedad = orderDocP.order.Proforma__r.Cuenta__r.Parent.Sociedad__c;
                    if(orderDocP.order.Numero_de_Factura__c == null) {
                        if(accSociedad != null && accSociedad.equals('Do América')) {
                            orderDocP.order.Numero_de_Factura__c = Util.getIncrement('facturaDoAmerica');
                         }
                         if(accSociedad != null && accSociedad.equals('Do Core')) {
                            orderDocP.order.Numero_de_Factura__c = Util.getIncrement('facturaDoCore');
                         }
                    }

                    //if order has not invoice it is created
                    if(!orderDocP.validFacturaCondition) {
                        //create factura
                        blobPDFFactura = createFileBlob('Factura', orderDocP.order.Id);
                        System.debug('pdffactura [' + blobPDFFactura + ']');
                        orderDocP.documentFacturaFile = blobPDFFactura;

                        String invoiceName = 'INV-' + orderDocP.order.Numero_de_Factura__c;
                        createDocument(blobPDFFactura, invoiceName + '.pdf', 'Factura', rt.Id, orderDocP.order.Id);                    
                    }
                    //if order has not packinglist it is created                
                    if(!orderDocP.validPackingListCondition) {

                        //create packing
                        blobPDFPacking = createFileBlob('Packing', orderDocP.order.Id);
                        System.debug('pdfpacking [' + blobPDFPacking + ']');
                        orderDocP.documentPackingListFile = blobPDFPacking;

                        String packingListName = 'PL-' + orderDocP.order.Numero_de_Factura__c;
                        createDocument(blobPDFPacking, packingListName + '.pdf', 'Packing List', rt.Id, orderDocP.order.Id);
                    }
                }

                //validate order after creates missing documents 
                orderDocP.validateOrder();

                //if order is ready it it is send by email
                if(orderDocP.isReadyToSend()) {
                    String taskDesc = LABEL_TASK_OK_DESC;
                    taskDesc = taskDesc.replace('{0}', orderDocP.order.Name);
                    tasks.add(createTask(LABEL_TASK_OK_SUBJECT, taskDesc, 'Abierta', 'Normal', orderDocP.order.Id, orderDocP.order.OwnerId));

                    orderDocP.order.Fecha_Factura__c = orderDocP.order.Fecha_Factura__c == null ? Date.today() : orderDocP.order.Fecha_Factura__c;
                    orderDocP.order.Documentos_Embarcado_Completos__c = true;
                    ordersToUpdate.add(orderDocP.order);
                } else {
                    // send notification task if order is not complete
                    String taskDesc = LABEL_TASK_DESC;
                    taskDesc = taskDesc.replace('{0}', orderDocP.order.Name);
                    System.debug('NOT SEND OwnerId [' + orderDocP.order.Proforma__r.Oportunidad__r.OwnerId + ']');
                    tasks.add(createTask(LABEL_TASK_SUBJECT, taskDesc, 'Abierta', 'Normal', orderDocP.order.Id, orderDocP.order.OwnerId));
                }
            }
        }
        insert tasks;

        update ordersToUpdate;
    }


    /*private static void buildAndSendMessage(String orderId, String contactId, String subject, String textBody, List<Messaging.EmailFileAttachment> attachments) {
        EmailTemplate emailTemplate;
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

        emailTemplate = getEmailTemplate();
        message.setTargetObjectId(contactId);
        message.setWhatId(orderId);
        message.setTemplateId(emailTemplate.Id);

        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        if(attachments != null && attachments.size() > 0) {
            message.setFileAttachments(attachments);
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }*/


    public static Blob createFileBlob(String type, String idOrder) {
        Blob blobPDF;
        if(type.equals('Factura')) {
            PageReference vfPdf = Page.OrderInvoiceDocument;
            vfPdf.getParameters().put('id',idOrder);

            if(Test.isRunningTest()) {
                blobPDF = Blob.valueOf('Unit.Test');
            } else {
                blobPDF = vfPdf.getContentAsPDF();
            }
        }
        if(type.equals('Packing')) {
            PageReference vfPdf = Page.OrderPackingListDocument;
            vfPdf.getParameters().put('id',idOrder);
            if(Test.isRunningTest()) {
                blobPDF = Blob.valueOf('Unit.Test');
            } else {
                blobPDF = vfPdf.getContentAsPDF();
            }
        }
        return blobPDF;
    }


   /**
    * Crea un objeto de tipo archivo adjunto para ser enviado por correo
    */
    public static Messaging.EmailFileAttachment createEmailFileAttachment(String fileName, Blob file) {
        Messaging.EmailFileAttachment fileAtt = new Messaging.EmailFileAttachment();
        fileAtt.setFileName(fileName);
        fileAtt.setInline(false);
        fileAtt.setBody(file);
        return fileAtt;
    }

    public String getIdAgentePrederminado() {
        Agentes__c agenteCS = [SELECT Id, 
                                     Name, 
                                     ID_Agente__c, 
                                     Predeterminado__c
                                FROM Agentes__c
                               WHERE Predeterminado__c = true];
        return agenteCS.ID_Agente__c;
    }

    private static Task createTask(String subject, String description, String status, String priority, String whatId, String ownerId) {
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

    //Factura, Packing List
    public static void createDocument(Blob contentFile, String fileName, String tipoDoc, String recordTypeId, String orderId) {
        Documento__c doc = new Documento__c();
        doc.PedidoDeCompra__c = orderId;
        doc.RecordTypeId = recordTypeId;
        doc.Proceso__c = CLIENT_DOC_PROCESS;
        doc.Tipo_de_Documento__c = tipoDoc;
        doc.Name = tipoDoc;
        insert doc;

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = contentFile;
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        insert cv;

        List<ContentVersion> cdlist = [SELECT ContentDocumentId
                                    FROM ContentVersion
                                    WHERE Id = :cv.Id
                                    limit 1];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cdlist.get(0).ContentDocumentId;
        cdl.LinkedEntityId = doc.Id;
        cdl.ShareType = 'I';

        insert cdl;

        doc.Archivo_Principal__c = cdlist.get(0).ContentDocumentId;
        update doc;
    }

    
    public static EmailTemplate getEmailTemplate() {
        EmailTemplate emailTemplate = [SELECT Id, Name 
                                         FROM EmailTemplate 
                                        WHERE Name = 'Final Documents POCliente'];
        return emailTemplate;
    }


    /**
     * Get an Account Id - ContactId map
     * The Contact Id associated to Account Id is the newest created contact
     */
    private static Map<String, String> getAccountContactMap(List<String> idAccounts) {
        List<Contact> contacts;
        List<Account> accounts;        
        Map<String, String> accountContact = new Map<String, String>();

        accounts = [SELECT Account.Id, 
                           (SELECT Contact.Id 
                              FROM Contacts 
                          ORDER BY CreatedDate DESC LIMIT 1) 
                      FROM Account 
                     WHERE Account.Id IN (SELECT Contact.accountId 
                                            FROM Contact 
                                           WHERE AccountId IN :idAccounts)];

        for(Account account : accounts) {
            contacts = account.contacts;
            for(Contact contact : contacts) {
                accountContact.put(account.Id, contact.Id);
            }
        }

        return accountContact;
    }


    public static void processDocument(Documento__c doc, OrderDocuments orderDoc, List<String> idsDocumentos, Map<String, OrderDocuments> mapCVOrderDoc) {
        if(doc.Tipo_de_Documento__c != null && 
           doc.Proceso__c.equals(CLIENT_DOC_PROCESS) && 
           (doc.Tipo_de_Documento__c.equals(DOC_BL) || 
            doc.Tipo_de_Documento__c.equals(DOC_FACTURA) || 
            doc.Tipo_de_Documento__c.equals(DOC_PACKING_LIST)) ) {

            orderDoc.addDocument(doc);
            idsDocumentos.add(doc.Id);
            System.debug('map [' + doc.Archivo_Principal__c + ']');
            //In this case archivo_principal__c contains ContentVersion.ContentDocumentId
            mapCVOrderDoc.put(doc.Archivo_Principal__c, orderDoc);
        }
    }

    /**
     * Create or modify scheduled shares in a shipped order
     */
    private void generateAportaciones(List<PedidoDeCompra__c> shippedOrders) {
        System.debug('Generar aportaciones Ini');
        List<ProgramacionDeAportaciones__c> aportacionesProgramadas;
        List<AportacionProgramadaWrapper> apList;
        Map<Id, List<PedidoLineItem__c>> orderItemsMap;
        Map<String, ProgramacionDeAportaciones__c> orderSharesMap;
        Map<String, OpportunityInformation> orderOppInfoMap;

        AportacionProgramadaWrapper appOpp;
        ProgramacionDeAportaciones__c aportacionProgramada;
        Map<String, ProgramacionDeAportaciones__c> oppAportacionesMap;
        Decimal sumaAportacionOld;
        Decimal sumaAportacion;
        List<String> shippedOrdersIds;

        aportacionesProgramadas = new List<ProgramacionDeAportaciones__c>();      
        apList = new List<AportacionProgramadaWrapper>();
        shippedOrdersIds = new List<String>();

        for(PedidoDeCompra__c order : shippedOrders) {
            shippedOrdersIds.add(order.Id);
        }

        orderSharesMap = getAportaciones(shippedOrdersIds);
        orderItemsMap = fetchLineItems(shippedOrdersIds);
        orderOppInfoMap = fetchOpportunityInformation(shippedOrdersIds);

        for(PedidoDeCompra__c order : shippedOrders) {
            sumaAportacion = sumaAportaciones(order.Id, orderItemsMap);

            if(sumaAportacion > 0) {
                aportacionProgramada = orderSharesMap.get(order.Id);
                appOpp = new AportacionProgramadaWrapper();

                if(aportacionProgramada == null) {
                    aportacionProgramada = crearAportacionProgramada(order, sumaAportacion, orderOppInfoMap);
                    appOpp.type = 'new';
                } else {
                    sumaAportacionOld = aportacionProgramada.Importe__c;
                    aportacionProgramada.Importe__c = sumaAportacion;
                    appOpp.type = 'old';
                    appOpp.oldAmount = sumaAportacionOld;
                }
                appOpp.aportacion = aportacionProgramada;
                appOpp.order = order;
                aportacionesProgramadas.add(aportacionProgramada);
                apList.add(appOpp);
             }
        }

        upsert aportacionesProgramadas;
        crearTareas(apList, orderOppInfoMap);
        System.debug('Generar aportaciones Fin');
    }


    private ProgramacionDeAportaciones__c crearAportacionProgramada(PedidoDeCompra__c order, Decimal suma, Map<String, OpportunityInformation> orderCommercialPlanningMap) {
        ProgramacionDeAportaciones__c aportacionProgramada;
        OpportunityInformation oppInfo = orderCommercialPlanningMap.get(order.Id);
        
        if(oppInfo == null || oppInfo.commercialPlanningId == null) {
            order.Name.addError('Opportunuty associated to this order, should have commercial planning');
        }
                
        aportacionProgramada = new ProgramacionDeAportaciones__c(PlanificacionComercial__c = oppInfo.commercialPlanningId,
                                       Aportacion_por_incremento_puntual__c = true,
                                       Comentario__c = 'Aportación generada por incrementos puntuales del pedido [' + order.Name + ']',
                                       Fecha__c = Date.today(),
                                       Pedido_de_Compra__c = order.Id,
                                       Importe__c = suma);
        return aportacionProgramada;
    }


    /**
     * Get a map of shares. This map will be used in order to verify
     * if exists an association between shipped order and share.
     * This association will be used to verify if already exists a share
     */
    private Map<String, ProgramacionDeAportaciones__c> getAportaciones(List<String> idsShippedOrder) {
        Map<String, ProgramacionDeAportaciones__c> pedidoAportacionesMap;
        pedidoAportacionesMap = new Map<String, ProgramacionDeAportaciones__c>();
        List<ProgramacionDeAportaciones__c> aportaciones;
        aportaciones = [SELECT Id, 
                               Name,
                               Importe__c,
                               Pedido_de_Compra__c
                          FROM ProgramacionDeAportaciones__c
                         WHERE Pedido_de_Compra__c IN :idsShippedOrder];

        for(ProgramacionDeAportaciones__c pa : aportaciones) {
            pedidoAportacionesMap.put(pa.Pedido_de_Compra__c, pa);
        }
        return pedidoAportacionesMap;
    }


    /**
     * Get the order line items in order to calculate the shares
     */
    private Map<Id, List<PedidoLineItem__c>> fetchLineItems(List<String> orderIds){
        Map<Id, List<PedidoLineItem__c>> result = new Map<Id, List<PedidoLineItem__c>>();
        for(PedidoLineItem__c pli : [SELECT Id,
                                            PedidoDeCompra__c,
                                            Name,
                                            Aportaciones_2__c,
                                            PrecioDeVentaTot__c,
                                            Porcentaje_Item__c
                                       FROM PedidoLineItem__c
                                      WHERE PedidoDeCompra__c IN :orderIds]) {
            if(result.containsKey(pli.PedidoDeCompra__c)) {
                result.get(pli.PedidoDeCompra__c).add(pli);
            } else {
                result.put(pli.PedidoDeCompra__c, new List<PedidoLineItem__c>{ pli });
            }
        }
        return result;
    }


    private Decimal sumaAportaciones(String orderId, Map<Id, List<PedidoLineItem__c>> orderItemsMap) {
        Decimal suma = 0;
        Decimal porcentajeAportaciones = 0;
        if(orderItemsMap.containsKey(orderId)) {
            for(PedidoLineItem__c item : orderItemsMap.get(orderId)) {
                porcentajeAportaciones = item.Aportaciones_2__c == null ? 0 : item.Aportaciones_2__c;
                suma = suma + (item.PrecioDeVentaTot__c * (porcentajeAportaciones/100));
            }
        }
        return suma;
    }
    
    private Map<String, OpportunityInformation> fetchOpportunityInformation(List<String> orderIds) {
        List<PedidoDeCompra__c> orders;
        Map<String, OpportunityInformation> orderOpportunityInfoMap = new Map<String, OpportunityInformation>();
        OpportunityInformation oppInfo;        
        orders = [SELECT Id,
                         Proforma__r.Oportunidad__r.PlanificacionComercial__c,
                         Proforma__r.Oportunidad__r.Account.Name,
                         Proforma__r.Oportunidad__r.OwnerId
                    FROM PedidoDeCompra__c];

        for(PedidoDeCompra__c order : orders) {
            oppInfo = new OpportunityInformation();
            oppInfo.accountName = order.Proforma__r.Oportunidad__r.Account.Name;
            oppInfo.commercialPlanningId = order.Proforma__r.Oportunidad__r.PlanificacionComercial__c;
            oppInfo.ownerId = order.Proforma__r.Oportunidad__r.OwnerId;
            orderOpportunityInfoMap.put(order.Id, oppInfo);
        }
        return orderOpportunityInfoMap;
    }


    private void crearTareas(List<AportacionProgramadaWrapper> aportacionesW, Map<String, OpportunityInformation> orderOppInfoMap) {
        ProgramacionDeAportaciones__c aportacion;
        String accountName = '';
        OpportunityInformation oppInfo;        
        PedidoDeCompra__c order;
        String idOpp;
        Task task;
        List<Task> tasks = new List<Task>();
        String subjectNew = 'Programación de aportación generada al embarcar el pedido';
        String subjectOld = 'La programación de aportacion ha sido modificada';
        String subject;
        String taskDescription;
        
        for(AportacionProgramadaWrapper appw : aportacionesW) {
            aportacion = appw.aportacion;
            order = appw.order;
            oppInfo = orderOppInfoMap.get(order.Id);
            if(oppInfo != null) {
                accountName = oppInfo.accountName;
            }
          
            if(appw.type.equals('new')) {
                subject = subjectNew;
                taskDescription = 'Programacion de aportación generada al embarcar el pedido ' + order.Name + ', con importe venta bruto ' 
                                    + order.CurrencyISOCode + ' ' + getCents(order.Precio_Total__c) + ', de la cuenta ' + accountName 
                                    + '. Monto de la aportación ' + order.CurrencyISOCode + ' ' + getCents(aportacion.Importe__c) + '.';
            } else {
                subject = subjectOld;
                taskDescription = 'Programacion de aportación modificada para el pedido ' + order.Name + ', con importe venta bruto ' 
                + order.CurrencyISOCode + ' ' + getCents(order.Precio_Total__c) + ', de la cuenta ' + accountName 
                + '. Monto de la aportación ' + order.CurrencyISOCode + ' ' + getCents(aportacion.Importe__c) + '. Antes: ' + order.CurrencyISOCode + ' ' + getCents(appw.oldAmount);
            }

            task = new Task(OwnerId = oppInfo.ownerId,
                          Subject = subject,
                          Status = 'Open',
                          Priority = 'Normal',
                          Description = taskDescription,
                          ActivityDate = Date.today(),
                          whatId = aportacion.Id);
            tasks.add(task);
        }
        insert tasks;
    }

    /**
     * Convert to number format
     */
    public String getCents(Decimal x){
        String y = String.valueOf(x);
        String z = '.';
        if(y.contains(',')) z = ',';
        y = y.substring(0, y.indexOf(z));
        if(x - Decimal.valueOf(y) == 0)
            return String.valueOf(x.format()) + z + '00';
        else return String.valueOf(x.format());
    }
    
    
    private PedidoDeCompra__c getPedido(String idPedido) {
        PedidoDeCompra__c pedido;
        pedido = [SELECT Id, 
                         Name, 
                         Cuenta__c,
                         Proforma__r.Cuenta__c,
                         Proforma__r.Cuenta__r.Name,
                         Proforma__r.Cuenta__r.ParentId,
                         Proforma__r.Cuenta__r.Parent.Name,
                         Proforma__r.Cuenta__r.Parent.IdQbo__c,
                         CuentaRelacion__c, 
                         CuentaRelacion__r.ParentId, 
                         CuentaRelacion__r.Parent.Name, 
                         Cuentarelacion__r.Parent.IdQbo__c, 
                         Proveedor__c, 
                         Proveedor__r.Name, 
                         Proveedor__r.IdQbo__c 
                    FROM PedidoDeCompra__c
                   WHERE Id = :idPedido];
        return pedido;
    }
    
  
    @Future(callout=true)
    public static void addQB(String idAccount) {
        QBSyncAccountController accCtrlr;
        accCtrlr = new QBSyncAccountController(idAccount);
        accCtrlr.syncQB();
    }  
    
/*    
    @Future(callout=true)
    public static void generateDocuments(List<String> idOrdersEmbarcado, List<String> tiposDocumento) {
    
    
        QBSyncAccountController accCtrlr;
        QBSyncAccountController(String idAccount)
*/  


    /**
     * Inner class used only to hold opportunity information
     */
    class OpportunityInformation {
        String accountName;
        String commercialPlanningId;
        String ownerId;
    }

}