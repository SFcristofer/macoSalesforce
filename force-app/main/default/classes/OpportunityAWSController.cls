public class OpportunityAWSController {
    private String idOpportunity;
    private Opportunity opportunity;
    public String payload {set; get;}
    private static String IMG_DIRECTORY = 'images';
    private AWS_Generacion_Cotizacion__mdt awsMdt;
    private String awsCotizacionEndpoint;
    private String formatoFOBColor;
    private Integer numberOLIperFile;
    public List<OpportunityLineItem> oliComments {set; get;}
    public Boolean continueSend {set; get;}
    public Boolean renderTable {set; get;}
    public Boolean renderLink {set; get;}    
    public Boolean renderButton {set; get;}    
    public String pushContinueSend {set; get;}
    public Boolean enviada {set; get;}
    public List<PageMessage> pageMessages {set; get;}
    public String urlQuote {set; get;}
    public List<String> urlQuotes {set; get;}

    private String awsURLBase;
    private String awsWebContextName;
    private String awsWebPath;
    private String awsMethodName;
    private String awsTemplateFile;
    private String awsS3BucketName;
    private String awsS3Region;
    private String excelFontName;
    private String excelFontSize;
    private String testItemsToProc;    

    private static final String MARCA_NO_SELECCIONADA = 'No se ha elegido la marca para los productos';
    private static final String CATALOGO_COMENTARIOS = 'Los ítems con comentarios sin atender no serán enviados';      

    public OpportunityAWSController (ApexPages.StandardController stdController) {
        idOpportunity = ApexPages.CurrentPage().getparameters().get('id');
        awsMdt = DOBrandsDAO.getAWSMetadatos('AWSCotizacion');
        if(awsMdt != null) {
            awsURLBase = awsMdt.AWS_URL_Base__c;
            awsWebContextName = awsMdt.AWS_webcontext_name__c;
            awsWebPath = awsMdt.AWS_webpath__c;
            awsMethodName = awsMdt.AWS_call_method_name__c;
            awsTemplateFile = awsMdt.AWS_template_file__c;
            awsS3BucketName = awsMdt.AWS_S3_Bucket_Name__c;
            awsS3Region = awsMdt.AWS_S3_Region__c;

            awsCotizacionEndpoint = awsURLBase + '/' + awsWebContextName + '/' + awsWebPath + '/' + awsMethodName;
            formatoFOBColor = awsMdt.Color_FOB_Price__c;
            numberOLIperFile = (Integer)awsMdt.Numero_OLI__c;
            testItemsToProc = awsMdt.test_items_to_proc__c;
            
            excelFontName = awsMdt.Cotizacion_Font_Name__c;
            excelFontSize = awsMdt.Cotizacion_Font_Size__c;
        }
        
        oliComments = new List<OpportunityLineItem>();
        continueSend = false;
        renderTable = false;
        enviada = false;
        renderLink = false;
        pageMessages = new List<PageMessage>();
        urlQuotes = new List<String>();
    }

    public PageReference confirmSend() {
        PageReference pr;
        pushContinueSend = 'sendit';
        pr = generarJSONAWS();
        return pr;
    }

    public PageReference generarJSONAWS() {
        PageReference newPage;    
        Boolean isBrandSelected = true;
        Boolean isThereComments = false;
        JSON_LOG__c jsonLog;
        List<JSON_LOG__c> jsonlogs;
        OpportunityAWSPayload oawspyload;
        OpportunityLineItemAWSPayload sfPayload;
        List<OpportunityLineItem> olisToSend;
        List<OpportunityLineItem> olisPrecioValido;        
        Integer numOLIsToSend;        
        String[] colorsRGB;
        String colorR = '255';
        String colorG = '255';
        String colorB = '255';
        String payloadBrand;
        Integer numFiles;
        Integer residue;
        List<String> payloadOutList = new List<String>();
        Boolean hasExternalError = false;

        List<OpportunityCostVerification> ocvList;
        List<ProductCostVerification> prodscv;
        ProductCostVerification pcv;
        OpportunityCostVerification ocv;
        System.debug('idOPP [' + idOpportunity + ']');
        opportunity = DOBrandsDAO.getOpportunity(idOpportunity);
        
        List<String> oppsId = new List<String>();
        oppsId.add(idOpportunity);
        ocvList = OpportunityDAO.getOpportunitiesCostVerification(oppsId);
        System.debug('ocvList [' + ocvList + ']');
        if(ocvList != null && ocvList.size() > 0) {
            ocv = ocvList.get(0);
            prodscv = ocv.productsCostV;
            System.debug('prodscv [' + prodscv + ']');
        }

        olisPrecioValido = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli : opportunity.OpportunityLineItems) {
            //buscar en prodsvc
            pcv = searchPCV(oli.Id, prodscv);
            // checar el precio
            //if(pcv.isPrecioVigente) {
            olisPrecioValido.add(oli);
            oli.Product2.Precio_Vigente__c = true;
            //}
        }

        jsonlogs = new List<JSON_LOG__c>();

        if(pushContinueSend != null && pushContinueSend.equals('sendit')) {
            continueSend = true;
        }
        
        //numOLIsToSend = opportunity.OpportunityLineItems.size();
        numOLIsToSend = olisPrecioValido.size();
        if(numberOLIperFile == null) {
            numberOLIperFile = 200;
        }
        numFiles = numOLIsToSend / numberOLIperFile;
        residue = Math.mod(numOLIsToSend, numberOLIperFile);
        if(residue > 0) {
            numFiles ++;
        }
        if(numFiles > 0 && residue == 0) {
            residue = numberOLIperFile;
        }
        
        renderTable = false;
        renderButton = false;
        
        if(opportunity.Is_Brand_Selected__c == null || opportunity.Is_Brand_Selected__c == false) {
            isBrandSelected = false;
            pageMessages.add(new PageMessage('ERROR', MARCA_NO_SELECCIONADA));
        }

        //for (OpportunityLineItem oli : opportunity.OpportunityLineItems) {
        for (OpportunityLineItem oli : olisPrecioValido) {
            if(!oli.Comentario_atendido__c) {
                oliComments.add(oli);
                isThereComments = true;
                renderTable = true;
            }
        }
        
        if(isThereComments) {
            pageMessages.add(new PageMessage('WARNING', CATALOGO_COMENTARIOS));
        }

        if(!isBrandSelected && !isThereComments) {
            return null;
        }

        if(!isBrandSelected && isThereComments) {
            return null;
        }
        
        if(isBrandSelected && isThereComments) {
            renderButton = true;
            if(!continueSend) {
                return null;
            }
        }

        colorsRGB = formatoFOBColor.split(',');
        if(colorsRGB != null && colorsRGB.size() == 3) {
           colorR = colorsRGB[0];
           colorG = colorsRGB[1];
           colorB = colorsRGB[2];
        }

        Integer generalIndex = 1;
        OpportunityLineItem oli;
        Integer start = 0;
        Integer limitUp = 0;        
        
        PageMessage pMessage;        
        //olisToSend = opportunity.OpportunityLineItems; 
        olisToSend = olisPrecioValido;
        System.debug('SIZEEEEEEEEEEE [' + olisToSend.size() + ']');

        for(Integer indexPage = 0; indexPage < numFiles; indexPage ++) {
            start = numberOLIperFile * indexPage;
            if(indexPage == numFiles - 1) {
                limitUp = (numberOLIperFile * indexPage) + residue;
            } else {
                limitUp = numberOLIperFile * (indexPage + 1);
            }

            oawspyload = new OpportunityAWSPayload();
            oawspyload.id_op = opportunity.Id;
            oawspyload.name_op = opportunity.Name;
            oawspyload.fob_pr_r = colorR;
            oawspyload.fob_pr_g = colorG;
            oawspyload.fob_pr_b = colorB;
            oawspyload.template_f = awsTemplateFile;
            oawspyload.s3_bucket = awsS3BucketName;
            oawspyload.s3_region = awsS3Region;
            oawspyload.font_name = excelFontName;
            oawspyload.font_size = excelFontSize;
            oawspyload.test_items_to_proc = testItemsToProc;

            for(Integer indexOli = start; indexOli < limitUp; indexOli++) {
                oli = olisToSend[indexOli];

                generalIndex++;

                if(!oli.Comentario_atendido__c) {
                    continue;
                }
            
                sfPayload = new OpportunityLineItemAWSPayload();
                sfPayload.itm = oli.Product2.CodigoDeProductoBase__c == null ? '' : oli.Product2.CodigoDeProductoBase__c;
                sfPayload.ean = oli.Product2.Codigo_EAN2__c == null ? '' : oli.Product2.Codigo_EAN2__c;
                sfPayload.s_dsc = oli.Product2.Name == null ? '' : oli.Product2.Name;
                sfPayload.itm_inf = oli.Product2.ProductoBase__r.Description == null ? '' : oli.Product2.ProductoBase__r.Description;
                sfPayload.clr = oli.Product2.Color2__c == null ? '' : oli.Product2.Color2__c;
                sfPayload.mtrial = oli.Product2.ProductoBase__r.Material__c == null ? '' : oli.Product2.ProductoBase__r.Material__c;
                sfPayload.qty_crmr = oli.Product2.ProductoBase__r.UnidadesPorMasterBox__c == null ? '' : String.valueOf(oli.Product2.ProductoBase__r.UnidadesPorMasterBox__c);
                sfPayload.pack = oli.Product2.Packaging__c == null ? '' : oli.Product2.Packaging__c.substring(2, oli.Product2.Packaging__c.length());
                sfPayload.brnd = oli.Product2.Marca2__c == null ? '' : oli.Product2.Marca2__c.substring(2, oli.Product2.Marca2__c.length());
                sfPayload.moq = oli.Product2.MOQ__c == null ? '' : String.valueOf(oli.Product2.MOQ__c);
                sfPayload.fob = oli.UnitPrice == null ? '' : String.valueOf(oli.UnitPrice);
    
                sfPayload.ld_tm = oli.Product2.PlazoDeFabricacion__c == null ? '' : oli.Product2.PlazoDeFabricacion__c;
                sfPayload.orig = oli.Product2.Fabrica__r.PaisDelPuerto__c == null ? '' : oli.Product2.Fabrica__r.PaisDelPuerto__c;
                sfPayload.pt_lnd = oli.Product2.Fabrica__r.Puerto__c == null ? '' : oli.Product2.Fabrica__r.Puerto__c;
    
                sfPayload.cod_trff = oli.Product2.ProductoBase__r.CodigoArancelario__c == null ? '' : oli.Product2.ProductoBase__r.CodigoArancelario__c;
                sfPayload.ctr20 = oli.Product2.ProductoBase__r.UnidadesContainer20__c == null ? '' : String.valueOf(oli.Product2.ProductoBase__r.UnidadesContainer20__c);
                sfPayload.ctr40 = oli.Product2.ProductoBase__r.UnidadesContainer40__c == null ? '' : String.valueOf(oli.Product2.ProductoBase__r.UnidadesContainer40__c);
                sfPayload.ctr40H = oli.Product2.ProductoBase__r.UnidadesHQ__c == null ? '' : String.valueOf(oli.Product2.ProductoBase__r.UnidadesHQ__c);

                //largo
                sfPayload.lrg = getMeasuresDetail(oli.Product2.ProductoBase__r.Producto_detalle__c, 
                                                  oli.Product2.ProductoBase__r.Producto2_detalle__c, 
                                                  oli.Product2.ProductoBase__r.Producto3_detalle__c,
                                                  oli.Product2.ProductoBase__r.ProductoLargoCm__c, 
                                                  oli.Product2.ProductoBase__r.Producto2LargoCm__c, 
                                                  oli.Product2.ProductoBase__r.Producto3LargoCm__c);

                //ancho
                sfPayload.wdth = getMeasuresDetail(oli.Product2.ProductoBase__r.Producto_detalle__c, 
                                                   oli.Product2.ProductoBase__r.Producto2_detalle__c,
                                                   oli.Product2.ProductoBase__r.Producto3_detalle__c,
                                                   oli.Product2.ProductoBase__r.ProductoAnchoCm__c, 
                                                   oli.Product2.ProductoBase__r.Producto2AnchoCm__c, 
                                                   oli.Product2.ProductoBase__r.Producto3AnchoCm__c);

                //alto
                sfPayload.hght = getMeasuresDetail(oli.Product2.ProductoBase__r.Producto_detalle__c, 
                                                   oli.Product2.ProductoBase__r.Producto2_detalle__c,
                                                   oli.Product2.ProductoBase__r.Producto3_detalle__c,
                                                   oli.Product2.ProductoBase__r.ProductoAltoCm__c, 
                                                   oli.Product2.ProductoBase__r.Producto2AltoCm__c, 
                                                   oli.Product2.ProductoBase__r.Producto3AltoCm__c);

                //diam
                sfPayload.dmtr = getMeasuresDetail(oli.Product2.ProductoBase__r.Producto_detalle__c,
                                                   oli.Product2.ProductoBase__r.Producto2_detalle__c,
                                                   oli.Product2.ProductoBase__r.Producto3_detalle__c,
                                                   oli.Product2.ProductoBase__r.ProductoDiametroCm__c, 
                                                   oli.Product2.ProductoBase__r.Producto2DiametroCm__c, 
                                                   oli.Product2.ProductoBase__r.Producto3DiametroCm__c);

                //peso
                sfPayload.wght = getMeasuresDetail(oli.Product2.ProductoBase__r.Producto_detalle__c, 
                                                   oli.Product2.ProductoBase__r.Producto2_detalle__c,
                                                   oli.Product2.ProductoBase__r.Producto3_detalle__c,
                                                   oli.Product2.ProductoBase__r.ProductoPesoKg__c, 
                                                   oli.Product2.ProductoBase__r.Producto2PesoKg__c, 
                                                   oli.Product2.ProductoBase__r.Producto3PesoKg__c, 2);
                
                //m3
                sfPayload.m3 = getMeasuresDetail(oli.Product2.ProductoBase__r.Producto_detalle__c, 
                                                 oli.Product2.ProductoBase__r.Producto2_detalle__c,
                                                 oli.Product2.ProductoBase__r.Producto3_detalle__c,
                                                 oli.Product2.ProductoBase__r.ProductoM3__c, 
                                                 oli.Product2.ProductoBase__r.Producto2M3__c, 
                                                 oli.Product2.ProductoBase__r.Producto3M3__c, 4);

                //mbox largo
                sfPayload.xlrg = getMeasuresDetail(oli.Product2.ProductoBase__r.Masterbox1_detalle__c, 
                                                   oli.Product2.ProductoBase__r.Masterbox2_detalle__c,
                                                   oli.Product2.ProductoBase__r.Masterbox3_detalle__c,
                                                   oli.Product2.ProductoBase__r.MasterboxLargoCm__c, 
                                                   oli.Product2.ProductoBase__r.Masterbox2LargoCm__c, 
                                                   oli.Product2.ProductoBase__r.Masterbox3LargoCm__c);

                //mbox ancho
                sfPayload.xwdth = getMeasuresDetail(oli.Product2.ProductoBase__r.Masterbox1_detalle__c, 
                                                    oli.Product2.ProductoBase__r.Masterbox2_detalle__c,
                                                    oli.Product2.ProductoBase__r.Masterbox3_detalle__c,
                                                    oli.Product2.ProductoBase__r.MasterboxAnchoCm__c, 
                                                    oli.Product2.ProductoBase__r.Masterbox2AnchoCm__c, 
                                                    oli.Product2.ProductoBase__r.Masterbox3AnchoCm__c);

                //mbox alto
                sfPayload.xhght = getMeasuresDetail(oli.Product2.ProductoBase__r.Masterbox1_detalle__c, 
                                                    oli.Product2.ProductoBase__r.Masterbox2_detalle__c,
                                                    oli.Product2.ProductoBase__r.Masterbox3_detalle__c,
                                                    oli.Product2.ProductoBase__r.MasterboxAltoCm__c, 
                                                    oli.Product2.ProductoBase__r.Masterbox2AltoCm__c, 
                                                    oli.Product2.ProductoBase__r.Masterbox3AltoCm__c);

                //mbox peso
                sfPayload.xwght = getMeasuresDetail(oli.Product2.ProductoBase__r.Masterbox1_detalle__c, 
                                                    oli.Product2.ProductoBase__r.Masterbox2_detalle__c,
                                                    oli.Product2.ProductoBase__r.Masterbox3_detalle__c,
                                                    oli.Product2.ProductoBase__r.MasterboxPesoKg__c, 
                                                    oli.Product2.ProductoBase__r.Masterbox2PesoKg__c, 
                                                    oli.Product2.ProductoBase__r.Masterbox3PesoKg__c, 2);

                //mbox m3
                sfPayload.xm3 = getMeasuresDetail(oli.Product2.ProductoBase__r.Masterbox1_detalle__c, 
                                                  oli.Product2.ProductoBase__r.Masterbox2_detalle__c,
                                                  oli.Product2.ProductoBase__r.Masterbox3_detalle__c,
                                                  oli.Product2.ProductoBase__r.MasterboxM3__c, 
                                                  oli.Product2.ProductoBase__r.Masterbox2M3__c, 
                                                  oli.Product2.ProductoBase__r.Masterbox3M3__c, 4);

                sfPayload.vcst = oli.Product2.Precio_Vigente__c ? 'Y' : 'N';
                System.debug('preciov field[' + oli.Product2.Precio_Vigente__c + '] vcspayload[' + sfPayload.vcst + ']');

                oawspyload.items.add(sfPayload);

            }

            String payloadOut = JSON.serialize(oawspyload);
            payloadOutList.add(payloadOut);            
    
            if(oawspyload.items != null && oawspyload.items.size() > 0) {
                payload = payloadOut;
                String res;
                res = callout(payloadOut);

                jsonLog = new JSON_LOG__c();
                jsonLog.name = 'AWSCotizaciones';
                jsonLog.endpoint__c = awsCotizacionEndpoint;
                jsonLog.Fecha_Envio__c = Datetime.now();
                jsonLog.json__c = payloadOut;
                jsonLog.Response_JSON__c = res;
                jsonlogs.add(jsonLog);

                AWSOportunityResult awsRes;
                String urlOpp;
                if(res != null) {
                    try {
                        awsRes = (AWSOportunityResult)JSON.deserialize(res, AWSOportunityResult.class);                    
                    } catch(JSONException jse) {
                        hasExternalError = true;
                        pMessage = new PageMessage('ERROR', 'External error [' + jse.getmessage() + ']');                        
                    }
                    
                    if(!hasExternalError) {
                        urlOpp = awsRes.URL;
                        opportunity.URL_Cotizacion__c = urlOpp;
                        urlQuote = urlOpp;
                        urlQuotes.add(urlQuote);
                        renderLink = true;
                    }
                }
                if (!hasExternalError) {
                    pMessage = new PageMessage('CONFIRM', 'La cotización fue generada');
                }
            } else {
                pMessage = new PageMessage('WARNING', 'La cotización no fue generada porque no habia elementos para cotizar');            
            }
        }


        Integer nF = 1;
        String finalstr = '';
        
        if(!hasExternalError) {        
            for(String urlq : urlQuotes) {
                finalstr = finalstr + '<a href=\'' + urlq + '\'>' + 'Cotización en XLS ' + nF + '</a><br/>';
                nF++;
            }
            opportunity.urls_cotizacion__c = finalstr;
            update opportunity;
        }

        insert jsonlogs;

        pageMessages.clear();
        
        enviada = true;

        oliComments.clear();
        isThereComments = false;
        renderTable = false;
        renderButton = false;        

        pageMessages.add(pMessage);
        return null;
    }


    private String getMeasuresDetail(String productOneDetail, String productTwoDetail, String productThreeDetail, String measureProductOne, String measureProductTwo, String measureProductThree) {
        String finalString = '';

        finalString = getMeasureDetail(productOneDetail, measureProductOne, finalString);
        finalString = getMeasureDetail(productTwoDetail, measureProductTwo, finalString);
        finalString = getMeasureDetail(productThreeDetail, measureProductThree, finalString);
        //System.debug('FSTR[' + finalString + ']');
        finalString = finalString.replace(',', ',\n');
        return finalString;
    }

    private String getMeasureDetail(String productDetail, String measureProduct, String resultMeasures) {
        String measureDetail;
        String auxProductDetail;
        String auxMeasure;

        auxProductDetail = productDetail == null ? '' : productDetail;
        auxMeasure = measureProduct == null || measureProduct == '' ? '' : measureProduct;
        measureDetail = auxMeasure != '' ? (auxMeasure == '' ? '' : auxMeasure + (auxProductDetail == '' ? '' : ' ' + auxProductDetail)) : '';
        resultMeasures = resultMeasures == '' ? resultMeasures + measureDetail : resultMeasures + (measureDetail == '' ? '' : ',' + measureDetail);
        return resultMeasures;
    }

    private String getMeasuresDetail(String productOneDetail, String productTwoDetail, String productThreeDetail, Decimal measureProductOne, Decimal measureProductTwo, Decimal measureProductThree, Integer scale) {
        return getMeasuresDetail(productOneDetail, productTwoDetail, productThreeDetail, formatNumber(measureProductOne, scale), formatNumber(measureProductTwo, scale), formatNumber(measureProductThree, scale));
    }


    private String formatNumber(Decimal numberToBeFormated, Integer scale) {
        Decimal scaleNumber;
        if(numberToBeFormated == null || numberToBeFormated == 0) {
            return '';
        }
        scaleNumber = numberToBeFormated.setScale(scale);
        List<String> formats = new String[]{'0','number','###,###.####'};
        return String.format(String.valueOf(scaleNumber), formats);
    }


    private String callout(String body) {
        String result;
        String httpMethod = 'POST';
        Map<String, String> httpHeaders;
        //http://infolasticaws-env.z6f7asutqq.us-west-2.elasticbeanstalk.com/test/testinfo/pingws  (ping)
        //http://infolasticaws-env.z6f7asutqq.us-west-2.elasticbeanstalk.com/test/testinfo/orderLine  (cotizacion)
        String endpoint = awsCotizacionEndpoint;
        
        httpHeaders  = new Map<String, String>();
        httpHeaders.put('Content-Type', 'application/json');
        httpHeaders.put('Accept', 'application/json');

        result = RestCall.restCall(endpoint, httpMethod, httpHeaders, body);
        return result;
    }


    private ProductCostVerification searchPCV(String oliId, List<ProductCostVerification> pcvList) {
        for(ProductCostVerification pcv : pcvList) {
            if(pcv.oppLineItemID.equals(oliId)) {
                return pcv;
            }
        }
        return null;
    }
    

    class PageMessage {
        //type = CONFIRM, ERROR, WARNING
        public String type {set; get;}
        public String typeClass {set; get;}
        public String idDiv {set; get;}
        public String idSpan {set; get;}
        public String summary {set; get;}
        public String titleSummary {set; get;}        
        
        public PageMessage(String mtype, String msummary) {
            type = mtype.toUpperCase();
            typeClass = 'message ' + mtype.toLowerCase() +'M3';
            idDiv = 'idDiv' + mtype.toLowerCase();
            idSpan = 'idSpan' + mtype.toLowerCase();
            summary = msummary;
            if(type.equals('WARNING')) {
                titleSummary = 'Advertencia';
            }
            if(type.equals('ERROR')) {
                titleSummary = 'Error';
            }
            if(type.equals('CONFIRM')) {
                titleSummary = 'Correcto';
            }
            
        }
    }

}