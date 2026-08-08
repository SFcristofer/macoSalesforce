public class UploadAmountCSVController {
    public static final String FILE_TYPE_PROVIDER = 'Provider';
    public static final String FILE_TYPE_CUSTOMER = 'Customer';
    public static final String FILE_HEADER_PROVIDER = 'Proveedor';
    public static final String FILE_HEADER_CUSTOMER = 'Cliente';

    public transient Blob csvFileBody {get; set;}
    public String csvFileName {get; set;}
    public List<WrapperCSVLine> amountsRecord {get; set;}
    public Boolean notValidData {get; set;}
    public String fileType {get; set;}
    public Boolean isRecordsEmpty {get; set;}

    public UploadAmountCSVController() {
        isRecordsEmpty = true;
    }

    public PageReference readCSV() {
        WrapperCSVLine wrapperLine;
        String[] lines;
        String csvString;
        List<String> accountCodes;
        List<String> invoicesNumber;
        List<String> providerInvoicesNumber;
        Map<String, Account> mapAccount;
        Map<String, PedidoDeCompra__c> mapOrder;
        Map<String, PedidoDeCompra__c> mapOrderProvider;
        Account customer;
        PedidoDeCompra__c order;
        Integer lineCounter = 0;

        amountsRecord = new List<WrapperCSVLine>();
        accountCodes = new List<String>();
        invoicesNumber = new List<String>();
        providerInvoicesNumber = new List<String>();
        mapOrderProvider = new Map<String, PedidoDeCompra__c>();

        notValidData = false;
        String[] headerFileTokens;
        //semicolon
        String[] headerFileTokensSC;
        isRecordsEmpty = true;

        try {
            if(csvFileBody == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Seleccione un archivo'));
                return null;
            }
            csvString = csvFileBody.toString();
            lines = csvString.split('\r\n');
            for(String line : lines) {

                if(lineCounter == 0) {
                    //file header
                    headerFileTokens = line.split(',');
                    headerFileTokensSC = line.split(';');

                    if(headerFileTokens != null && headerFileTokens.size() == 7) {
                        fileType = getFileTypeFromCSVHeader(headerFileTokens);
                    } else if(headerFileTokensSC != null && headerFileTokensSC.size() == 7) {
                        fileType = getFileTypeFromCSVHeader(headerFileTokensSC);
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Formato desconocido'));
                        return null;
                    }
                    if(fileType.equals('Unknown')) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Formato desconocido'));
                        return null;
                    }

                    lineCounter++;
                    continue;
                }

                wrapperLine = new WrapperCSVLine(line, fileType);
                amountsRecord.add(wrapperLine);
                if(wrapperLine.customerCode != null) {
                    accountCodes.add(wrapperLine.customerCode);
                }
                invoicesNumber.add(wrapperLine.formatedInvoiceNumber);
                if(fileType.equals(FILE_TYPE_PROVIDER)) {
                    providerInvoicesNumber.add(wrapperLine.invoiceNumber);
                }
                lineCounter++;
            }
        } catch(Exception e) {
            System.debug('ERROR: ' + e.getMessage());
        }

        mapAccount = getAccountByCode(accountCodes);

        if(fileType.equals(FILE_TYPE_CUSTOMER)) {
            mapOrder = getOrderByInvoiceNumber(invoicesNumber);
        }
        if(fileType.equals(FILE_TYPE_PROVIDER)) {
            getOrderBySearchCondition('invoiceProvider', providerInvoicesNumber, mapOrderProvider);
            getOrderBySearchCondition('orderName', providerInvoicesNumber, mapOrderProvider);
        }
        
        for(WrapperCSVLine wcsvLine : amountsRecord) {
            if(fileType.equals(FILE_TYPE_CUSTOMER)) {
                order = mapOrder.get(wcsvLine.formatedInvoiceNumber);
            }
            if(fileType.equals(FILE_TYPE_PROVIDER)) {
                order = mapOrderProvider.get(wcsvLine.invoiceNumber);
            }
            if(order != null) {
                wcsvLine.order = order;
                wcsvLine.orderName = order.Name;
                wcsvLine.isValidOrderName = true;
            }

            customer = mapAccount.get(wcsvLine.customerCode);
            if(customer != null) {
                wcsvLine.account = customer;
                wcsvLine.customerName = customer.Name;
                wcsvLine.isValidCustomerName = true;
            }
            wcsvLine.validateRecord();
            if(!wcsvLine.isValidLine) {
                notValidData = true;
            }
        }

        isRecordsEmpty = amountsRecord.isEmpty();

        return null;
    }


    private String getFileTypeFromCSVHeader(String[] headerTokens) {
        String fileTypeFromHeader = 'Unknown';
        if(headerTokens[2].contains(FILE_HEADER_PROVIDER)) {
            fileTypeFromHeader = FILE_TYPE_PROVIDER;
        } 
        if (headerTokens[2].contains(FILE_HEADER_CUSTOMER)) {
            fileTypeFromHeader = FILE_TYPE_CUSTOMER;
        }
        return fileTypeFromHeader;
    }

    public PageReference saveAmounts() {
        List<Cartera_Importe__c> amountsToBeDeleted;
        List<Cartera_Importe__c> importes = new List<Cartera_Importe__c>();
        Cartera_Importe__c carteraImporte;

        amountsToBeDeleted = [SELECT Id FROM Cartera_Importe__c WHERE Tipo_Archivo__c = :fileType];
        delete amountsToBeDeleted;

        for(WrapperCSVLine csvRecord : amountsRecord) {
            if(csvRecord.isValidLine) {
                carteraImporte = new Cartera_Importe__c(Name = csvRecord.formatedInvoiceNumber, 
                                                        Cuenta__c = csvRecord.account.Id, 
                                                        Documento__c = csvRecord.formatedInvoiceNumber,
                                                        Fecha_Factura__c = Date.parse(csvRecord.invoiceDate),
                                                        Fecha_Vencimiento__c = Date.parse(csvRecord.expirationDate),
                                                        Importe_Pendiente_EUR__c = Decimal.valueOf(csvRecord.amountPendingEUR == null || csvRecord.amountPendingEUR == '' ? '0' : csvRecord.amountPendingEUR),
                                                        Importe_Pendiente_USD__c = Decimal.valueOf(csvRecord.amountPendingUSD == null || csvRecord.amountPendingUSD == '' ? '0' : csvRecord.amountPendingUSD),
                                                        Tipo_Archivo__c = csvRecord.fileType);

                if(csvRecord.order != null) {
                    carteraImporte.Pedido__c = csvRecord.order.Id;
                }

                importes.add(carteraImporte);
            }
        }

        insert importes;

        amountsRecord.clear();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.CONFIRM, 'La información del archivo <i>' + csvFileName + '</i> ha sido registrada'));
        return null;
    }


    private Map<String, Account> getAccountByCode(List<String> codes) {
        Map<String, Account> mapAccount;
        List<Account> accounts;
        mapAccount = new Map<String, Account>();
        accounts = [SELECT Id,
                           Name,
                           Codigo_rapido__c
                      FROM Account
                     WHERE Codigo_rapido__c IN :codes];
        for(Account account : accounts) {
            mapAccount.put(account.Codigo_rapido__c, account);
        }
        return mapAccount;
    }


    private Map<String, PedidoDeCompra__c> getOrderByInvoiceNumber(List<String> invoiceNumbers) {
        Map<String, PedidoDeCompra__c> mapOrder;
        List<PedidoDeCompra__c> orders;
        mapOrder = new Map<String, PedidoDeCompra__c>();
        orders = [SELECT Id,
                         Name,
                         Numero_de_Factura__c
                    FROM PedidoDeCompra__c
                   WHERE Numero_de_Factura__c IN :invoiceNumbers];
        for(PedidoDeCompra__c order : orders) {
            if(order.Numero_de_Factura__c != null && !order.Numero_de_Factura__c.equals('')) {
                mapOrder.put(order.Numero_de_Factura__c, order);
            }
        }
        return mapOrder;
    }

    private void getOrderBySearchCondition(String searchCondition, List<String> valuesCondition, Map<String, PedidoDeCompra__c> mapConditionOrder) {
        List<PedidoDeCompra__c> orders;
        String fieldCondition = searchCondition.equals('invoiceProvider') ? 'Numero_de_Factura_Proveedor__c ' : 'Name ';
        String queryBase = 'SELECT Id, ' +
                                  'Name, ' +
                                  'Numero_de_Factura_Proveedor__c ' + 
                             'FROM PedidoDeCompra__c ' +
                             'WHERE ';
        queryBase = queryBase + fieldCondition + ' IN :valuesCondition';

        orders = Database.query(queryBase);

        for(PedidoDeCompra__c order : orders) {
            if(searchCondition.equals('invoiceProvider')) {
                if(order.Numero_de_Factura_Proveedor__c != null && !order.Numero_de_Factura_Proveedor__c.equals('')) {
                    mapConditionOrder.put(order.Numero_de_Factura_Proveedor__c, order);
                }
            } else {
                mapConditionOrder.put(order.Name, order);
            }
        }
    }


}