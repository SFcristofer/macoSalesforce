public class Util {

    public static final Map<Integer, String> MONTHS_TXT = new Map<Integer, String>
                                                     {1 => 'Enero', 
                                                      2 => 'Febrero',
                                                      3 => 'Marzo',
                                                      4 => 'Abril',
                                                      5 => 'Mayo',
                                                      6 => 'Junio',
                                                      7 => 'Julio',
                                                      8 => 'Agosto',
                                                      9 => 'Septiembre',
                                                      10 => 'Octubre',
                                                      11 => 'Noviembre',
                                                      12 => 'Diciembre'};
 
     public static String[] unitsArray = new String[] {'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 
                                                'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'};
     public static String[] tensArray = new String[] {'zero', 'ten', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'};
 
                                              
     /**
      * Return the month as a text string. 
      * Ej, month 1 = 'Enero'
      *
      */
     public static String getMonth(Integer mes)
     {
         if(mes < 13 && mes > 0)
         {
            return MONTHS_TXT.get(mes);
         }
         return '';
     }
 
     /*
      * Get the increment string for Pedido or ProForma
      */
     public static String getIncrement(String name) {
         Incremento_CS__c increaseCS;
         String prefixCS;
         Integer yearCS;
         Integer consecutiveCS;
         String consecutiveAux;
         Integer currentYear;
         Integer maxInvoiceNumber = 0;
         
         // Obtener valores
         increaseCS = [SELECT Id, 
                              Name, 
                              prefix__c, 
                              year__c, 
                              consecutive__c 
                         FROM Incremento_CS__c
                        WHERE Name = :name];
 
         consecutiveAux = String.valueOf(increaseCS.consecutive__c);
         System.debug('aux[' + consecutiveAux + '] length[' + consecutiveAux.length() + '] name[' + name + ']');
 
         // Actualizar
         currentYear = System.today().year();
         System.debug('currentYear[' + currentYear + ']');
         yearCS = (Integer)increaseCS.year__c;
 
         String yearAuxStr = String.valueOf(yearCS);
         if(yearAuxStr.length() == 2) {
             yearCS = yearCS + 2000;
         }

         maxInvoiceNumber = DOBrandsDAO.getMaxInvoiceNumber(increaseCS.prefix__c + (yearCS - 2000));
 
         if(yearCS < currentYear) {
             increaseCS.year__c = currentYear;
             increaseCS.consecutive__c = 1;
             consecutiveAux = String.valueOf(increaseCS.consecutive__c);
             yearCS = (Integer)increaseCS.year__c;
         } else {
             if(maxInvoiceNumber > increaseCS.consecutive__c) {
                 consecutiveAux = String.valueOf(maxInvoiceNumber);
                 increaseCS.consecutive__c = maxInvoiceNumber + 1;
             } else {
                 increaseCS.consecutive__c = increaseCS.consecutive__c + 1;
             }
         }
 
         if(yearCS >= 2000) {
             yearCS = yearCS - 2000;
         }
 
         update increaseCS;
         
         System.debug('consecutiveAux[' + consecutiveAux + ']');
         return getFormatIncrement(name, increaseCS.prefix__c, yearCS, consecutiveAux);
     }


     /*
      * Get the increment string for Pedido or ProForma
      */
     public static String getIncrement(String name, String planificacionName) {
         List<Incremento_CS__c> increaseCSList;
         Incremento_CS__c increaseCS;
         String prefixCS;
         Integer yearCS;
         Integer consecutiveCS;
         String consecutiveAux;
         Integer currentYear;
         Integer maxInvoiceNumber = 0;
         String result;
         
         Integer yearPlanificacion = Integer.valueOf(planificacionName);
         
         if(name.equals('pedido')) {
             prefixCS = 'PE';
         }
         if(name.equals('proforma')) {
             prefixCS = 'PR';
         }
         
         System.debug('prefix [' + prefixCS + '] year [' + yearPlanificacion +']');
         
         increaseCSList = [SELECT Id, 
                                  Name, 
                                  prefix__c, 
                                  year__c, 
                                  consecutive__c 
                             FROM Incremento_CS__c
                            WHERE Name LIKE :name + '%'
                            AND year__c = :yearPlanificacion];

         System.debug('prefix [' + increaseCSList.size() + ']');
                            
         if(increaseCSList.isEmpty()) {
             increaseCS = new Incremento_CS__c(Name = name + planificacionName,
                                               consecutive__c = 1,
                                               Descripcion__c = name + 's ' + planificacionName,
                                               prefix__c = prefixCS,
                                               year__c = Integer.valueOf(planificacionName));
             insert increaseCS;
         
         } else {
             if(increaseCSList.size() > 1) {
                 throw new PedidoDeCompraException('Multiple values for CS year');
             }
             increaseCS = increaseCSList.get(0);
         }
         
         consecutiveAux = String.valueOf(increaseCS.consecutive__c);
         System.debug('consecutive1 [' + consecutiveAux + ']');
         
         yearCS = (Integer)increaseCS.year__c;
         System.debug('yearCS [' + yearCS + ']');
         
         maxInvoiceNumber = DOBrandsDAO.getMaxInvoiceNumber(increaseCS.prefix__c + (yearCS - 2000));         
         System.debug('maxInvoice [' + maxInvoiceNumber + ']');

         if(maxInvoiceNumber > increaseCS.consecutive__c) {
             consecutiveAux = String.valueOf(maxInvoiceNumber);
             increaseCS.consecutive__c = maxInvoiceNumber + 1;
         } else {
             increaseCS.consecutive__c = increaseCS.consecutive__c + 1;
         }

         System.debug('increase2 [' + increaseCS.consecutive__c + ']');         
         update increaseCS;         
         
         if(yearCS >= 2000) {
             yearCS = yearCS - 2000;
         }

         result = getFormatIncrement(name, increaseCS.prefix__c, yearCS, consecutiveAux);
         
         System.debug('result  [' + result + ']');
         
         return result;
     }


 
     private static String getFormatIncrement(String name, String prefix, Integer yearCS, String consecutiveAux)
     {
         String result = '';
         if(name.equals('aportacion') || name.equals('pedido') || name.equals('proforma'))
         {
             result = prefix + yearCS + consecutiveAux.leftPad(3, '0');
             //return prefix + yearCS + consecutiveAux.leftPad(3, '0');
         }
         if(name.equals('facturaDoAmerica') || name.equals('facturaDoCore'))
         {
             result = prefix + yearCS + '/' + consecutiveAux.leftPad(3, '0');
         }
         System.debug('Util - getFormatIncrement - formatIncrement[' + result + ']');
         return result;
     }
 
     public static Solicitud_Transferencia_Intervalo__c getCSTransferenciaIntervalo()
     {
         //name: [intervalo] [intervaloCustom]
         Solicitud_Transferencia_Intervalo__c stCS;
 
         stCS = [SELECT Id, 
                        Name, 
                        meses_atras__c, 
                        fecha_inicio__c, 
                        fecha_fin__c
                   FROM Solicitud_Transferencia_Intervalo__c 
                  WHERE activo__c = true];
 
         return stCS;
     }
 
 
     public static List<ContentVersion> getFileFromContentVersion(String contentDocId)
     {
         List<ContentVersion> contentVersionDocList;
 
         System.debug('cdocid [' + contentDocId + ']');
 
         contentVersionDocList = [SELECT Title,
                                         PathOnClient, 
                                         FileType,
                                         FileExtension,
                                         VersionData
                                    FROM ContentVersion
                                   WHERE ContentDocumentId = :contentDocId];
 
         System.debug('cdocidsize [' + contentVersionDocList.size() + ']');
         return contentVersionDocList;
     }
 
     public static List<Envio_Correos__c> getCSCorreosTransferencia()
     {
         //name: [ordenes] [documentosFaltantes]
         List<Envio_Correos__c> ecCSList;
 
         ecCSList = [SELECT Id, 
                        Name, 
                        correo_electronico__c
                   FROM Envio_Correos__c];
 
         return ecCSList;
     }
 
     public static List<Envio_Correos__c> getCSCorreosTransferencia(String flujo)
     {
         //name: [ordenes] [documentosFaltantes]
         List<Envio_Correos__c> ecCSList;
 
         ecCSList = [SELECT Id, 
                            Name, 
                            correo_electronico__c
                       FROM Envio_Correos__c
                      WHERE flujo__c = :flujo];
 
         return ecCSList;
     }
 
     public static Libra_Cobros_Pagos__c getCSLibraFechaCobrosPagos(String name)
     {
         //name: [Cobros] [Pagos]
         Libra_Cobros_Pagos__c libraCPCS;
 
         libraCPCS = [SELECT Id, 
                             Name, 
                             Fecha_Callout_Exitosa__c
                        FROM Libra_Cobros_Pagos__c
                       WHERE Name = :name];
 
         return libraCPCS;
     }
 
     /**
      * This method convert a date string with the forma dd/mm/yyy to Salesforce Date object
      */
     public static Date convertDateStrToSF(String dateLibra) {
         Date result;
         String datePart;
 
         if(dateLibra == null) {
             throw new DoBrandsException('The string date can not be null');
         }
         String[] tokensInit = dateLibra.split(' ');
         if(tokensInit == null || tokensInit.size() != 2) {
             throw new DoBrandsException('Invalid format');
         }
         datePart = tokensInit[0];
 
         String[] tokens = datePart.split('/');
         if(tokens == null || tokens.size() != 3) {
             throw new DoBrandsException('The string date format must be dd/mm/yyy');
         }
         
         result = date.valueOf(tokens[2] + '-' + tokens[1] + '-' + tokens[0] + ' 00:00:00');
         return result;
     }
 
 
     public static String dobleToWord (String doubleStr) {
         if(doubleStr == null) {
             return '0.0';
         }
         String[] tokens = doubleStr.split('\\.');
         System.debug('tokens[' + tokens.size() + ']');
         Integer integerPart = Integer.valueOf(tokens[0]);
         Integer decimalPart = Integer.valueOf(tokens[1]);
 
         String resInteger = Util.numberToWord(integerPart);
         System.debug('res1[' + resInteger + ']');
 
         String resDecimal = Util.numberToWord(decimalPart);
         System.debug('res2[' + resDecimal + ']');
 
         return resInteger + ' with ' +  resDecimal + ' cents.';
     }
 
 
     public static String numberToWord(Integer numberToConvert) {
 
         String words = '';
         if (numberToConvert == null || numberToConvert == 0) {
             return 'zero';
         }
 
         if (numberToConvert < 0) { // convert the number to a string 
            String numberStr = '' + numberToConvert; 
            numberStr = numberStr.substring(1); 
            return 'minus ' + numberToWord(Integer.valueOf(numberStr));
         } 
 
         if ((numberToConvert / 1000000) > 0) {
             words += numberToWord(numberToConvert / 1000000) + ' million ';
             numberToConvert = Math.mod(numberToConvert, 1000000);
         }
 
         if ((numberToConvert / 1000) > 0) {
             words += numberToWord(numberToConvert / 1000) + ' thousand ';
             numberToConvert = Math.mod(numberToConvert, 1000);
         }
 
         if ((numberToConvert / 100) > 0) {
             words += numberToWord(numberToConvert / 100) + ' hundred ';
             numberToConvert = Math.mod(numberToConvert, 100);
         }
 
         if (numberToConvert > 0) {
             if (numberToConvert < 20) { 
                 words += unitsArray[numberToConvert];
             } else { 
                 words += tensArray[numberToConvert / 10]; 
                 if (Math.mod(numberToConvert,10) > 0) {
                     words += '-' + unitsArray[Math.mod(numberToConvert,10)];
                 }
             }
         }
 
       return words;
    }
 
 
     public static String buildHTMLBody(String salute, String text, Boolean isSupplier, String table, String note, String goodbyeText) {
         String result = '';
         result = result + salute + '<br/><br/>';
         if(! isSupplier) {
            result = result + 'Once the booking is confirmed, please complete the information below (only enter the values after the colons): <br/> HBL: <br/> MBL: <br/> POL: <br/> POD: <br/> CARRIER: <br/> VESSEL/VOYAGE: <br/> ETD: <br/>';
         }
         result = result + text + '<br/><br/>';
         if(isSupplier) {
            result = result + '<strong><u>Forwarder information</u></strong><br/><br/>';
         }
         result = result + table + '<br/>';
         result = result + '<p><i><font color=\"red\">' + note + '</font></i></p><br/>';
         result = result + goodbyeText + '<br/>';                                
         return result;
     }
 
     public static String buildHTMLtable(Map<String, String> dataTable) {
         String result = '<table style=\"border: 1px solid black;border-collapse: collapse;\">';
         for(String key : dataTable.keySet()) {
             result = result + '<tr>';
             result = result + '<td style=\"border-top:1px solid black;border-left:1px solid black;border-right:1px solid black;border-bottom:1px solid black\" >' + key + '</td>';
             result = result + '<td style=\"border-top:1px solid black;border-left:1px solid black;border-right:1px solid black;border-bottom:1px solid black\">' + dataTable.get(key) + '</td>';
             result = result + '</tr>';
         }
         result = result + '</table>';
         System.debug('result [' + result + ']');
         return result;
     }
 
 
     public static String generateToken() {
         Integer rnd = Crypto.getRandomInteger();
         String hashString = String.valueOf(rnd) + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
         Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
         String hexDigest = EncodingUtil.convertToHex(hash);
         return hexDigest;
     }
 
     
     public static Map<String, List<String>> getFieldDependencies(String sobjectName, String parentField, String childField) {
         Map<String, List<String>> controllingInfo = new Map<String, List<String>>();
 
         Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sobjectName).getDescribe();
         Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(parentField).getDescribe();
         Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(childField).getDescribe();
 
         List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
         List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
 
         for(Schema.PicklistEntry currControllingValue : controllingValues) {
             controllingInfo.put(currControllingValue.getLabel(), new List<String>());
         }
 
         for(Schema.PicklistEntry currDependentValue : dependentValues) {
             String jsonString = JSON.serialize(currDependentValue);
             PickListInfo info = (PickListInfo) JSON.deserialize(jsonString, PickListInfo.class);
             String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
 
             Integer baseCount = 0;
 
             for(Integer curr : hexString.getChars()) {
                 Integer val = 0;
 
                 if(curr >= 65) {
                     val = curr - 65 + 10;
                 } else {
                     val = curr - 48;
                 }
 
                 if((val & 8) == 8) {
                     controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
                 }
                 if((val & 4) == 4) {
                     controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());                    
                 }
                 if((val & 2) == 2) {
                     controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());                    
                 }
                 if((val & 1) == 1) {
                     controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());                    
                 }
                 baseCount += 4;
             }
         }
         //System.debug('ControllingInfo: ' + controllingInfo);
         return controllingInfo;
     }
     
     public static Boolean isPositiveInteger(String numberToTest, Integer lengthPositiveInteger) {
          Pattern positiveIntegerPattern = Pattern.compile('^[0]|[1-9]{1}([0-9]{1,' + String.valueOf(lengthPositiveInteger) + '})?$');
          Matcher positiveIntegerMatcher = positiveIntegerPattern.matcher(numberToTest);
          return positiveIntegerMatcher.matches();
     }
 
 }