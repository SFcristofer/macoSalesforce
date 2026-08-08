public class WrapperCSVLine {
    public String fileType {set; get;}
    private static final Integer VALID_SIZE = 7;

    public static final String FILE_TYPE_PROVIDER = 'Provider';
    public static final String FILE_TYPE_CUSTOMER = 'Customer';

    private String REGEX_DATE = '\\d{2}/\\d{2}/\\d{4}';
    private String REGEX_NUMBER = '^(\\d+(\\.\\d{1,2})?)|(\\-{1}\\d+(\\.\\d{1,2})?)$';
    private String REGEX_NUMBER_FMT = '^((\\d{1,3}\\.{0,1})+(\\,\\d{1,2})?)|(\\-{1}(\\d{1,3}\\.{0,1})+(\\,\\d{1,2})?)$';
    private String REGEX_TRANSACTION_TYPE = '[A-Z]{3}';
    private String REGEX_CUSTOMER = '^([A-Z]{2}\\d{5})|([A-Z]\\d{5})|([0-9]{5})$';
    private String REGEX_INVOICE = '([A-Z]\\d{2}/\\d{6})|([A-Z]\\d{2}/\\d{6}\\-\\d{1})|([A-Z]{3}/\\d{6})';

    public Account account {set; get;}
    public PedidoDeCompra__c order {set; get;}
    public String csvLine {set; get;}

    public String expirationDate {set; get;}
    public String customerCode {set; get;}
    public String customerName {set; get;}
    public String invoiceNumber {set; get;}
    public String formatedInvoiceNumber {set; get;}
    public String invoiceDate {set; get;}
    public String typeCurrency {set; get;}
    public String amount {set; get;}
    public String amountPendingEUR {set; get;}
    public String amountPendingUSD {set; get;}
    public String orderName {set; get;}    


    public Boolean isValidExpirationDate {set; get;}
    public Boolean isValidCustomerCode {set; get;}
    public Boolean isValidCustomerName {set; get;}
    public Boolean isValidInvoiceNumber {set; get;}
    public Boolean isValidOrderName {set; get;}
    public Boolean isValidInvoiceDate {set; get;}
    public Boolean isValidAmount {set; get;}
    public Boolean isValidAmountPendingEUR {set; get;}
    public Boolean isValidAmountPendingUSD {set; get;}

    public Boolean isValidLine {set; get;}

    public String errorMessage {set; get;}

    public WrapperCSVLine(String line, String strFileType) {
        fileType = strFileType;
        csvLine = line;
        isValidLine = true;
        isValidExpirationDate = true;
        isValidCustomerCode = true;
        isValidCustomerName = false;
        isValidInvoiceNumber = true;
        if(fileType.equals(FILE_TYPE_CUSTOMER)) {
            isValidOrderName = false;
        } else {
            isValidOrderName = true;
        }

        isValidInvoiceDate = true;
        isValidAmount = true;
        isValidAmountPendingEUR = true;
        isValidAmountPendingUSD = true;

        errorMessage = '';
        processLine();
    }


    public void processLine() {
        String[] tokens;
        if(csvLine != null) {
            tokens = csvLine.split(',');
            System.debug('tokens [' + tokens + '] tokens size[' + tokens.size() + '] fileType[' + fileType + ']');
            if(tokens.size() >= VALID_SIZE) {
                extractValueFromTokens(tokens);
            } else {
                tokens = csvLine.split(';');
                if(tokens.size() >= VALID_SIZE) {
                    extractValueFromTokens(tokens);
                }
            }
        } 
    }


    private void extractValueFromTokens(String[] tokens) {

        expirationDate = tokens[0];
        isValidExpirationDate = extractContent(expirationDate, REGEX_DATE);

        customerCode = tokens[1];        
        if(fileType.equals(FILE_TYPE_CUSTOMER)) {
            isValidCustomerCode = extractContent(customerCode, REGEX_CUSTOMER);
        }

        customerName = tokens[2];        

        invoiceNumber = tokens[3];
        if(fileType.equals(FILE_TYPE_CUSTOMER)) {
            isValidInvoiceNumber = extractContent(invoiceNumber, REGEX_INVOICE);
            if(isValidInvoiceNumber) {
                formatInvoice(invoiceNumber);
            }
        }

        invoiceDate = tokens[4];
        isValidInvoiceDate = extractContent(invoiceDate, REGEX_DATE);

        amountPendingEUR = getValidAmount(tokens[5], 'EUR');
        amountPendingUSD = getValidAmount(tokens[6], 'USD');
    }


    private String getValidAmount(String strValue, String currencyp) {
        String result;
        String[] decimalStrTokens;
        String intToken;
        String decToken;
        Boolean isValidAmount = false;

        result = strValue;

        isValidAmount = extractContent(strValue, REGEX_NUMBER);
        if(!isValidAmount) {
            isValidAmount = extractContent(strValue, REGEX_NUMBER_FMT);
            if(isValidAmount) {
                decimalStrTokens = strValue.split(',');
                decToken = decimalStrTokens[1];
                intToken = decimalStrTokens[0];
                intToken = intToken.replace('.','');
                result = intToken + '.' + decToken;
            } else {
                if(currencyp.equals('USD')) {
                    isValidAmountPendingUSD = false;
                }
                if(currencyp.equals('EUR')) {
                    isValidAmountPendingEUR = false;
                }
            }
        }
        return result;
    }


    public void validateRecord() {
        isValidLine = isValidExpirationDate && isValidCustomerCode && isValidCustomerName && isValidInvoiceDate;
        if(fileType.equals(FILE_TYPE_CUSTOMER)) {
            isValidLine = isValidLine && isValidAmountPendingUSD && isValidAmountPendingEUR;
        } else {
            isValidLine = isValidLine && isValidAmount;
        }

        if(!isValidExpirationDate) {
            errorMessage = errorMessage + 'fecha de vencimiento no válida, ';
        }
        if(!isValidCustomerCode) {
            errorMessage = errorMessage + 'código de cliente no válido, ';
        }
        if(!isValidCustomerName) {
            errorMessage = errorMessage + 'cliente desconocido, ';
        }
        if(!isValidInvoiceDate) {
            errorMessage = errorMessage + 'fecha de factura no válida, ';
        }
        if(fileType.equals(FILE_TYPE_CUSTOMER)) { 
            if(!isValidAmountPendingUSD) {
                errorMessage = errorMessage + 'importe en dólares no válido, ';
            }
            if(!isValidAmountPendingEUR) {
                errorMessage = errorMessage + 'importe en euros no válido, ';
            }
        } else {
            if(!isValidAmount) {
                errorMessage = errorMessage + 'importe no válido, ';
            }
        }
        if(errorMessage.length() > 0) {
            errorMessage = errorMessage.substring(0, errorMessage.length() - 2).capitalize();
        }
    }

    private Boolean extractContent(String stringToverify, String regex) {
        Boolean result;
        if(stringToverify == null || stringToverify.equals('')) {
            return false;
        }
        Pattern matchPattern = Pattern.compile(regex);
        Matcher contentMatcher = matchPattern.matcher(stringToverify);

        result = contentMatcher.matches();
        return result;
    }


    private void formatInvoice(String invoice) {
        String[] tokens;
        String invoiceNumber;
        String invoiceSerie;        
        tokens = invoice.split('/');
        invoiceSerie = tokens[0];
        invoiceNumber = tokens[1];
        invoiceNumber = invoiceNumber.substring(3, 6);
        formatedInvoiceNumber = invoiceSerie + '/' + invoiceNumber;
    }
    
    /** 
     * Not used in this release, however it can be used in the future
     * This method get information using regex pattern, all matched strings
     */
    private List<String> extractContent(String regex) {
        List<String> matches = new List<String>();
        String stringMatch;
        Pattern matchPattern = Pattern.compile(regex);
        Matcher contentMatcher = matchPattern.matcher(csvLine);

        while (contentMatcher.find()) { 
            stringMatch = contentMatcher.group();
            System.debug('regex[' + regex + '] match[' + stringMatch + ']');
            matches.add(stringMatch);
        }
        return matches;
    }

}