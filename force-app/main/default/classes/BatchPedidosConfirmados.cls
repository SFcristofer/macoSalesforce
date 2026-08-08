global class BatchPedidosConfirmados implements Database.Batchable<sObject> {
    private String ESTATUS_PEDIDO_CONFIRMADO = 'PEDIDO CONFIRMADO';//confirmo el cliente
    private String ESTATUS_PEDIDO_PACKAGING = 'PACKAGING';//Confirmo el proveedor
    private String TIPODOC_CONFIRMACION = 'Confirmación Proveedor';
    private String TIPODOC_FACTURA = 'Factura';
    private String TIPOPROC_PEDIDO_FABRICA = 'Pedido Fábrica';
    private String TIPOPROC_DOC_PEDIDO_PROVEEDOR = 'Documentación del Pedido Proveedor';
    private String INTERVALO = 'intervalo';
    private String INTERVALO_CUSTOM = 'intervaloCustom';
    private String DEPOSITO = 'DEPOSITO';
    private String REMANENTE = 'REMANENTE';
    private String MAIL_SUBJECT_ST = 'Solicitud de Transferencia Depósito';
    private String MAIL_SUBJECT_ST_BALANCE = 'Solicitud de Transferencia Balance';
    private String MAIL_BODY_ST = 'Documentos de la solicitud de transferencia';
    private String MAIL_SUBJECT_ST_DOC_FALT = 'Solicitud de Transferencia - Pedidos con documentacion faltante';
    private String MAIL_BODY_ST_DOC_FALT = 'Pedidos sin documentos\n';
    private String tipoBatch;
    private Date fechaIni;
    private Date fechaFin;
    private List<String> correosOrdenes;
    private List<String> correosDocsFaltantes;
 
    //
    // Documentacion de pedido - factura
    //
    global BatchPedidosConfirmados(String tipo) {
       tipoBatch = tipo;
       initCustomSettings();
    }
 
    /**
     * Inicializa custom settings
     */
    private void initCustomSettings() {
       Integer diasAtras;
       Solicitud_Transferencia_Intervalo__c stCS;
       List<Envio_Correos__c> ecSCList;
 
       correosOrdenes = new List<String>();
       correosDocsFaltantes = new List<String>();
 
       ecSCList = Util.getCSCorreosTransferencia('pedidosConfirmados');
       for(Envio_Correos__c ec : ecSCList) {
          if(ec.Name.equals('documentosFaltantes')) {
             correosDocsFaltantes.add(ec.correo_electronico__c);
          } else {
             correosOrdenes.add(ec.correo_electronico__c);
          }
       }
    }
 
    /**
     * get the documents
     */
    global Database.QueryLocator start(Database.BatchableContext context) {
       
       if(tipoBatch.equals(DEPOSITO)) {
          System.debug('Deposito-------------------------------------------');
          return Database.getQueryLocator([SELECT Id, 
                                                  Proceso__c, 
                                                  Tipo_de_Documento__c, 
                                                  PedidoDeCompra__c,  
                                                  PedidoDeCompra__r.Name, 
                                                  PedidoDeCompra__r.Estado2__c, 
                                                  PedidoDeCompra__r.FechaConfirmacionCliente__c,
                                                  PedidoDeCompra__r.Aprobada_Transferencia_Balance__c,
                                                  PedidoDeCompra__r.Proveedor__r.PorcentajeDeposito__c,
                                                  PedidoDeCompra__r.Proveedor__c,
                                                  PedidoDeCompra__r.Proveedor__r.Name,
                                                  PedidoDeCompra__r.Proveedor__r.BillingStreet,
                                                  PedidoDeCompra__r.Proveedor__r.BillingCity,
                                                  PedidoDeCompra__r.Proveedor__r.BillingState,
                                                  PedidoDeCompra__r.Proveedor__r.BillingPostalCode,
                                                  PedidoDeCompra__r.Proveedor__r.BillingCountry,
                                                  PedidoDeCompra__r.Proveedor__r.NumeroCuenta__c,
                                                  PedidoDeCompra__r.Proveedor__r.NombreBanco__c,
                                                  PedidoDeCompra__r.Proveedor__r.DireccionBanco__c,
                                                  PedidoDeCompra__r.Proveedor__r.SWIFT__c,
                                                  PedidoDeCompra__r.Proveedor__r.TitularCuenta__c,
                                                  PedidoDeCompra__r.Proforma__r.Cuenta__r.Name,
                                                  PedidoDeCompra__r.Proforma__r.Cuenta__r.Parent.Sociedad__c,
                                                  PedidoDeCompra__r.PorcentajeDepositoAFabrica__c,
                                                  PedidoDeCompra__r.CostoOrigen__c,
                                                  PedidoDeCompra__r.Monto_deposito__c,
                                                  PedidoDeCompra__r.Correo_Pago_Deposito__c 
                                             FROM Documento__c 
                                            WHERE PedidoDeCompra__r.Correo_Pago_Deposito__c = false
                                              AND PedidoDeCompra__r.Aprobada_Transferencia_Deposito__c = true
                                              AND PedidoDeCompra__r.RecordType.DeveloperName = 'Principal'
                                              AND Proceso__c = :TIPOPROC_PEDIDO_FABRICA
                                              AND Tipo_de_Documento__c = :TIPODOC_CONFIRMACION]);
                                              //check aprobado deposito*/
       }
       
       if(tipoBatch.equals(REMANENTE)) {
          System.debug('Balance-------------------------------------------');
          return Database.getQueryLocator([SELECT Id, 
                                                  Proceso__c, 
                                                  Tipo_de_Documento__c, 
                                                  PedidoDeCompra__c,  
                                                  PedidoDeCompra__r.Name, 
                                                  PedidoDeCompra__r.Estado2__c, 
                                                  PedidoDeCompra__r.FechaConfirmacionCliente__c,
                                                  PedidoDeCompra__r.Aprobada_Transferencia_Deposito__c,
                                                  PedidoDeCompra__r.Proveedor__c,
                                                  PedidoDeCompra__r.Proveedor__r.Name,
                                                  PedidoDeCompra__r.Proveedor__r.BillingStreet,
                                                  PedidoDeCompra__r.Proveedor__r.BillingCity,
                                                  PedidoDeCompra__r.Proveedor__r.BillingState,
                                                  PedidoDeCompra__r.Proveedor__r.BillingPostalCode,
                                                  PedidoDeCompra__r.Proveedor__r.BillingCountry,
                                                  PedidoDeCompra__r.Proveedor__r.NumeroCuenta__c,
                                                  PedidoDeCompra__r.Proveedor__r.NombreBanco__c,
                                                  PedidoDeCompra__r.Proveedor__r.DireccionBanco__c,
                                                  PedidoDeCompra__r.Proveedor__r.SWIFT__c,
                                                  PedidoDeCompra__r.Proveedor__r.TitularCuenta__c,
                                                  PedidoDeCompra__r.Proforma__r.Cuenta__r.Name,
                                                  PedidoDeCompra__r.Proforma__r.Cuenta__r.Parent.Sociedad__c,
                                                  PedidoDeCompra__r.PorcentajeDepositoAFabrica__c,
                                                  PedidoDeCompra__r.CostoOrigen__c,
                                                  PedidoDeCompra__r.Monto_deposito__c,
                                                  PedidoDeCompra__r.Correo_Pago_Deposito__c
                                             FROM Documento__c 
                                            WHERE Proceso__c = :TIPOPROC_PEDIDO_FABRICA
                                              AND Tipo_de_Documento__c = :TIPODOC_FACTURA
                                              AND PedidoDeCompra__r.Aprobada_Transferencia_Balance__c = true 
                                              AND PedidoDeCompra__r.Correo_pago_balance__c = false
                                              AND PedidoDeCompra__r.RecordType.DeveloperName = 'Principal']);
                                              //check aprobado balance 
       }
        return null;
    }
 
    public void execute(Database.BatchableContext BC, List<Documento__c> scope) {
       List<PedidoDeCompra__c> pedidos = new List<PedidoDeCompra__c>();
       List<PedidoDeCompra__c> pedidosNoDoc = new List<PedidoDeCompra__c>();
       List<ContentVersion> contentVersionDocList;
       ContentVersion contentVersionDoc;      
       PedidoDeCompra__c pedido;
       Documento__c docAux;
       List<ContentDocumentLink> cdlList;
       ContentDocumentLink cdl;
       Messaging.EmailFileAttachment att;
       Messaging.EmailFileAttachment attcv;
       Integer sizePedidos = scope.size();
       List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
       String subject;
       String tipo = 'adelanto';
       String numeroPedidos = '';
       Map<String, Map<String, Set<PedidoTransferenciaSplit>>> pedidosProveedorSociedad;
       Map<String, Set<PedidoTransferenciaSplit>> proveedorSociedadMap;
       Set<PedidoTransferenciaSplit> pedidoTransferSplitList;
       PedidoTransferenciaSplit pedidoTransferSplit;
 
       pedidosProveedorSociedad = new Map<String, Map<String, Set<PedidoTransferenciaSplit>>>();
       
       subject = MAIL_SUBJECT_ST;
       if(tipoBatch.equals(REMANENTE)) {
          tipo = 'remanente';
            subject = MAIL_SUBJECT_ST_BALANCE;
       }
 
       // Por cada pedido asociado a un documento, se debe generar un correo con las ordenes a enviar 
       for(Documento__c documento : scope) {
          pedido = new PedidoDeCompra__c(Id = documento.PedidoDeCompra__c, 
                                         Name = documento.PedidoDeCompra__r.Name);
          cdlList = hasValidDocument(documento.Id);
          if(cdlList.size() > 0) {
             cdl = cdlList.get(0);
 
             pedidoTransferSplit = new PedidoTransferenciaSplit();
             pedidoTransferSplit.pedidoId = documento.PedidoDeCompra__c;
             pedidoTransferSplit.pedidoName = documento.PedidoDeCompra__r.Name;
             pedidoTransferSplit.pedidoSociedad = documento.PedidoDeCompra__r.Proforma__r.Cuenta__r.Parent.Sociedad__c;
             pedidoTransferSplit.pedidoProveedor = documento.PedidoDeCompra__r.Proveedor__c;
             pedidoTransferSplit.pedidoProveedorName = documento.PedidoDeCompra__r.Proveedor__r.Name;

             pedidoTransferSplit.billingStreet = documento.PedidoDeCompra__r.Proveedor__r.BillingStreet;
             pedidoTransferSplit.billingCity = documento.PedidoDeCompra__r.Proveedor__r.BillingCity;
             pedidoTransferSplit.billingState = documento.PedidoDeCompra__r.Proveedor__r.BillingState;
             pedidoTransferSplit.billingPostalCode = documento.PedidoDeCompra__r.Proveedor__r.BillingPostalCode;
             pedidoTransferSplit.billingCountry = documento.PedidoDeCompra__r.Proveedor__r.BillingCountry;
             pedidoTransferSplit.bankAccountNumber = documento.PedidoDeCompra__r.Proveedor__r.NumeroCuenta__c;
             pedidoTransferSplit.bankName = documento.PedidoDeCompra__r.Proveedor__r.NombreBanco__c;
             pedidoTransferSplit.bankAddress = documento.PedidoDeCompra__r.Proveedor__r.DireccionBanco__c;
             pedidoTransferSplit.swiftCode = documento.PedidoDeCompra__r.Proveedor__r.SWIFT__c;
             pedidoTransferSplit.bankAccountBeneficiary = documento.PedidoDeCompra__r.Proveedor__r.TitularCuenta__c;
         
             pedidoTransferSplit.costoOrigen = documento.PedidoDeCompra__r.CostoOrigen__c;
             pedidoTransferSplit.porcentajeDepositoFabrica = documento.PedidoDeCompra__r.PorcentajeDepositoAFabrica__c;
             pedidoTransferSplit.montoDeposito = documento.PedidoDeCompra__r.Monto_deposito__c;
 
             proveedorSociedadMap = pedidosProveedorSociedad.get(pedidoTransferSplit.pedidoProveedor);
             if(proveedorSociedadMap == null) {
                proveedorSociedadMap = new Map<String, Set<PedidoTransferenciaSplit>>();
                pedidosProveedorSociedad.put(pedidoTransferSplit.pedidoProveedor, proveedorSociedadMap);
             }
 
             pedidoTransferSplitList = proveedorSociedadMap.get(pedidoTransferSplit.pedidoSociedad);
             if(pedidoTransferSplitList == null) {
                pedidoTransferSplitList = new Set<PedidoTransferenciaSplit>();
                proveedorSociedadMap.put(pedidoTransferSplit.pedidoSociedad, pedidoTransferSplitList);
             }
             pedidoTransferSplitList.add(pedidoTransferSplit);
 
             contentVersionDocList = Util.getFileFromContentVersion(cdl.ContentDocumentId); 
             if(contentVersionDocList.size() > 0) {
                contentVersionDoc = contentVersionDocList.get(0);
                attcv = createFileAttachmentFromContentVersion(documento.PedidoDeCompra__r.Proveedor__r.Name, documento.PedidoDeCompra__r.Name, contentVersionDoc);
 
                attachments.add(attcv);
             }
 
             if(tipo.equals('adelanto')) {
                pedido.Correo_Pago_Deposito__c = true;
             }
             if(tipo.equals('remanente')) {
                pedido.Correo_pago_balance__c = true;
             }
             pedidos.add(pedido);
          } else {
             pedidosNoDoc.add(pedido);
          }
       }
 
       String key;
       String keySoc;
       Map<String, Set<PedidoTransferenciaSplit>> tstPtMap;
       Set<PedidoTransferenciaSplit> tstLst;
       PedidoTransferenciaSplit ptso;
       Decimal importe;
       String typeConcept;
       String concept = '';
       String transferType;
       String providerName;
       String beneficiary;

       String billingStreet;
       String billingCity;
       String billingState;
       String billingPostalCode;
       String billingCountry;
       String bankAccount;
       String bankName;
       String bankAddress;
       String swift;
 
       for(String prov : pedidosProveedorSociedad.keySet()) {
           key = prov;
           tstPtMap = pedidosProveedorSociedad.get(key);
           for(String soc : tstPtMap.keySet()) {
               keySoc = soc;
               tstLst = tstPtMap.get(keySoc);
               concept = '';
               importe = 0;
               //
               for(PedidoTransferenciaSplit pts : tstLst) {
                   if(tipo.equals('adelanto')) {
                       importe = importe + calcularMontoDeposito(pts);
                       transferType = 'DEPOSIT';
                       typeConcept = 'DEPOSITO-';
                   }
                   if(tipo.equals('remanente')) {
                       importe = importe + calcularBalance(pts);
                       transferType = 'BALANCE';
                       typeConcept = 'BALANCE-';
                   }
                   concept = concept + pts.pedidoName + ',';
                   providerName = pts.pedidoProveedorName;
                   beneficiary = pts.bankAccountBeneficiary;

                   billingStreet = pts.billingStreet;
                   billingCity = pts.billingCity;
                   billingState = pts.billingState;
                   billingPostalCode = pts.billingPostalCode;
                   billingCountry = pts.billingCountry;
                   bankAccount = pts.bankAccountNumber;
                   bankName = pts.bankName;
                   bankAddress = pts.bankAddress;
                   swift = pts.swiftCode;

               }

               concept = typeConcept + concept;
               if(concept != null && concept.length() > 0) {
                   concept = concept.substring(0, concept.length() - 1);
               }

               att = createFileAttachment(providerName, 
                                          key, 
                                          keySoc, 
                                          tipo, 
                                          String.valueOf(importe), 
                                          concept, 
                                          beneficiary,
                                          billingStreet,
                                          billingCity,
                                          billingState,
                                          billingPostalCode,
                                          billingCountry,
                                          bankAccount,
                                          bankName,
                                          bankAddress,
                                          swift);
               attachments.add(att);
           }
 
       }
 
       if(attachments != null && attachments.size() > 0) {
          buildAndSendMessage(correosOrdenes, subject, MAIL_BODY_ST, attachments);
       }
       update pedidos;
       if(pedidosNoDoc.size() > 0) {
          numeroPedidos = '';
          for(PedidoDeCompra__c p : pedidosNoDoc) {
             numeroPedidos = numeroPedidos + p.Name + '\n';
          }
          buildAndSendMessage(correosDocsFaltantes, MAIL_SUBJECT_ST_DOC_FALT, MAIL_BODY_ST_DOC_FALT + numeroPedidos, null);
       }
    }


    public Decimal calcularMontoDeposito(PedidoTransferenciaSplit pedidoC) {
        Decimal resultado = 0;
        String porcentaje = '0';
        Decimal costo = 0;
        Decimal porcentajeDepositoFabrica = 0;

        costo = pedidoC.costoOrigen != null ? pedidoC.costoOrigen : costo;        
        porcentajeDepositoFabrica = pedidoC.porcentajeDepositoFabrica != null ? pedidoC.porcentajeDepositoFabrica : porcentajeDepositoFabrica;

        resultado = (porcentajeDepositoFabrica/100) * costo;
        return resultado;
    }

    public Decimal calcularBalance(PedidoTransferenciaSplit pedidoC) {
        Decimal resultado = 0;
        Decimal costo = 0;
        Decimal deposito = 0;

        costo = pedidoC.costoOrigen != null ? pedidoC.costoOrigen : costo;
        deposito = pedidoC.montoDeposito != null ? pedidoC.montoDeposito : deposito;

        resultado = costo - deposito;
        return resultado;
    }

     
    global void finish(Database.BatchableContext BC) {
         
    }
 
    //** schedulable */
    private Messaging.EmailFileAttachment createFileAttachment(String pnombreProveedor, 
                                                               String pidProveedor, 
                                                               String psociedad, 
                                                               String tipo,
                                                               String importe,
                                                               String concept,
                                                               String beneficiary,
                                                               String billingStreet,
                                                               String billingCity,
                                                               String billingState,
                                                               String billingPostalCode,
                                                               String billingCountry,
                                                               String bankAccount,
                                                               String bankName,
                                                               String bankAddress,
                                                               String swift) {
       Date dateToday = Date.today();
       String substringProveedorName;
       Integer lengthName;
       
       Blob blobPDF;
       Messaging.EmailFileAttachment fileAtt;
 
       lengthName = pnombreProveedor.length();
       if(lengthName > 15) {
          substringProveedorName = pnombreProveedor.substring(0, 15);
       } else {
          substringProveedorName = pnombreProveedor;
       }
 
       PageReference vfPdf =  Page.SolicitudTransferenciaInternacional;
       vfPdf.getParameters().put('idProv', pidProveedor);
       vfPdf.getParameters().put('soc', psociedad);
       vfPdf.getParameters().put('typeOrdr', tipo); 
       vfPdf.getParameters().put('importe', importe);
       vfPdf.getParameters().put('concept', concept);
       vfPdf.getParameters().put('beneficiary', beneficiary);
       vfPdf.getParameters().put('billingSt', billingStreet); 
       vfPdf.getParameters().put('billingCty', billingCity);
       vfPdf.getParameters().put('billingStt', billingState);
       vfPdf.getParameters().put('billingPC', billingPostalCode);
       vfPdf.getParameters().put('billingCtry', billingCountry); 
       vfPdf.getParameters().put('bankAcc', bankAccount);
       vfPdf.getParameters().put('bankNm', bankName);
       vfPdf.getParameters().put('bankAddr', bankAddress);
       vfPdf.getParameters().put('swift', swift); 

       if(Test.isRunningTest()) {
          blobPDF = Blob.valueOf('Unit.Test');
       } else {
          blobPDF = vfPdf.getContentAsPDF();
       }
 
       fileAtt = createEmailFileAttachment(substringProveedorName + '-' + dateToday.day() + '.' + dateToday.month() + '.' + dateToday.year() + '.pdf', blobPDF);
       
       return fileAtt;
    }
 
    private Messaging.EmailFileAttachment createFileAttachmentFromContentVersion(String pproveedorName, String orderNumber, ContentVersion contentVersion) {
       String substringProveedorName;
       Integer lengthName;
 
       Blob blobFile;
       Messaging.EmailFileAttachment fileAtt;
       blobFile = contentVersion.VersionData;
 
       lengthName = pproveedorName.length();
       if(lengthName > 15) {
          substringProveedorName = pproveedorName.substring(0, 15);
       } else {
          substringProveedorName = pproveedorName;
       }
 
 
       fileAtt = createEmailFileAttachment(substringProveedorName + '-' + orderNumber + '.' + contentVersion.FileExtension, blobFile);
 
       return fileAtt;
    }
 
 
    public List<ContentDocumentLink> hasValidDocument(String idDoc) {
       List<ContentDocumentLink> cdlList;
       cdlList = [SELECT Id, 
                         ContentDocumentId, 
                         LinkedEntityId
                    FROM ContentDocumentLink 
                   WHERE LinkedEntityId = :idDoc];
 
       return cdlList;
    }
 
 
    private static void buildAndSendMessage(List<String> deliveryMail, String subject, String textBody, List<Messaging.EmailFileAttachment> attachments) {      
       Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
       message.toAddresses = deliveryMail;
       message.subject = subject;
       message.plainTextBody = textBody;
       Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
 
       if(attachments != null && attachments.size() > 0) {
          message.setFileAttachments(attachments);
       }
       Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }
 
    /**
     * Crea un objeto de tipo archivo adjunto para ser enviado por correo
     */
    private Messaging.EmailFileAttachment createEmailFileAttachment(String fileName, Blob file) {
       Messaging.EmailFileAttachment fileAtt = new Messaging.EmailFileAttachment();
       fileAtt.setFileName(fileName);
       fileAtt.setInline(false);
       fileAtt.setBody(file);
       return fileAtt;
    }
 
 }