/**
 * iestrada   2020-06-25  Add SOQL fields to be used in <code>PedidoTriggerHelper</code>
 * 
 * Facade class for data access
 */
public class DOBrandsDAO {

    public static RecordType getRecordType(String devName, String psObject) {
       RecordType rt;
       rt = [SELECT Id,
                    Name,
                    DeveloperName,
                    SObjectType
               FROM RecordType
              WHERE SObjectType = :psObject
                AND DeveloperName = :devName];
       return rt;
    }

    
    public static List<Account> getAccountByCodigoRapido(List<String> codigosProveedor, RecordType rt) {
        List<Account> proveedores;
        proveedores = [SELECT Id, 
                              Name,
                              Codigo_rapido__c
                         FROM Account
                        WHERE RecordTypeId = :rt.Id
                          AND Codigo_rapido__c IN :codigosProveedor];
        return proveedores;
    }


    public static Account getProvider(String idProvider, RecordType rt) {
        Account provider;
        provider = [SELECT Id, 
                           Name,
                           EmailComercial__c,
                           Portal_Token__c,
                           Portal_Token_Verificacion__c
                      FROM Account
                     WHERE RecordTypeId = :rt.Id
                       AND Id = :idProvider];
        return provider;
    }

    public static Account getProviderByToken(String token, RecordType rt) {
        List<Account> providers;
        Account provider;        
        providers = [SELECT Id, 
                               Name,
                               EmailComercial__c,
                               Portal_Token__c
                          FROM Account
                         WHERE RecordTypeId = :rt.Id
                           AND Portal_Token__c = :token];
        if(providers.size() > 0) {
            provider = providers.get(0);
        }
        return provider;
    }

    public static Account getProviderByTokenVerificacion(String token, RecordType rt) {
        List<Account> providers;
        Account provider;        
        providers = [SELECT Id, 
                               Name,
                               EmailComercial__c,
                               Portal_Token_Verificacion__c,
                               Portal_Token__c
                          FROM Account
                         WHERE RecordTypeId = :rt.Id
                           AND Portal_Token_Verificacion__c = :token];
        if(providers.size() > 0) {
            provider = providers.get(0);
        }
        return provider;
    }

    public static Account getAccount(String idAccount) {
        Account account;
        List<Account> accounts;
        accounts = [SELECT Id, 
                            Name,
                            parent.Codigo_pais2__c,
                            parent.RazonSocial__c,
                            parent.NroIdFiscal__c,
                            parent.Sociedad__c,
                            parent.Codigo_rapido__c,
                            parent.BillingPostalCode,
                            parent.Alta_Libra__c,
                            parent.Registrar_Libra__c,
                            parent.PlazoPago__c,
                            parent.Portal_Token__c,
                            parent.FormaPago__c,
                            parent.CurrencyIsoCode,
                            parent.Credito_autorizado__c,
                            Puerto__c,
                            PaisDelPuerto__c
                            FROM Account
                            WHERE Id = :idAccount];
        if(accounts.size() > 0) {
            account = accounts.get(0);
        }
        return account;
    }

    public static PedidoDeCompra__c getOrder(String orderId, RecordType rt) {
        PedidoDeCompra__c order;
        order = [SELECT Id, 
                         Name, 
                         Email_Facturacion_Cliente__c,
                         Portal_Token__c,
                         Proforma__r.Oportunidad__r.OwnerId,
                         Proforma__c,
                         Proforma__r.Cuenta__r.ContactoFinanciero__c,
                         Proveedor__r.EmailComercial__c,
                         RecordTypeId,
                         Email_Fabrica__c
                    FROM PedidoDeCompra__c
                   WHERE Id = :orderId
                     AND RecordTypeId = :rt.Id];
        return order;
    }

    public static List<PedidoDeCompra__c> getOrdersDocuments(List<String> ordersIds, List<String> tiposDocumento) {
        List<PedidoDeCompra__c> orders;
        orders = [SELECT Id, 
                         Name, 
                         Email_Facturacion_Cliente__c,
                         Numero_de_Factura__c,
                         Fecha_Factura__c,
                         Proforma__r.Oportunidad__r.OwnerId,
                         Proforma__c,
                         Proforma__r.Cuenta__c,
                         Proforma__r.Cuenta__r.ContactoFinanciero__c,
                         Proforma__r.Cuenta__r.Parent.Sociedad__c,
                         OwnerId,
                         Documentos_Embarcado_Completos__c,
                         Correo_Documentos_Embarcado__c,
                         (SELECT Id, 
                                 Name,
                                 Tipo_de_Documento__c,
                                 Proceso__c,
                                 Archivo_Principal__c
                            FROM Documentos__r
                           WHERE Tipo_de_Documento__c IN :tiposDocumento) 
                    FROM PedidoDeCompra__c
                   WHERE Id IN :ordersIds];
        return orders;
    }


    public static PedidoDeCompra__c getOrderByToken(String token) {
        return getOrderBySearchCondition('Portal_Token__c', token);
    }


    public static PedidoDeCompra__c getOrderByNumber(String orderNumber) {
        return getOrderBySearchCondition('Name', orderNumber);
    }

    
    private static PedidoDeCompra__c getOrderBySearchCondition(String searchField, String searchValue) {
        String soqlBaseQuery = 
        'SELECT Id, ' +
               'Name, ' +
               'Email_Facturacion_Cliente__c, ' +
               'Proforma__r.Oportunidad__r.OwnerId,' +
               'Proforma__c,' +
               'Portal_Token__c,' +
               'Proveedor__r.Name,' +
               'Proforma__r.Cuenta__r.ContactoFinanciero__c,' +
               'Proforma__r.Cuenta__r.ParentId,' +
               'Fecha_de_Carga_de_Contenedor__c, ' +
               'Fecha_Factura_Proveedor__c, ' +
               'Numero_de_Factura_Proveedor__c, ' +
               '(SELECT Id, ' +
                       'Name,' +
                       'DescripcionProducto__c,' +
                       'Producto__c,' +
                       'Producto__r.PrecioDeFabrica__c,' +
                       'Producto__r.ProductoBase__r.IDImagen1__c,' +
                       'Producto__r.Codigo_EAN__c,' +
                       'Producto__r.Codigo_EAN2__c,' +
                       'Producto__r.CodigoDeProductoBase__c,' +
                       'Producto__r.Codigo_Proveedor__c,' +
                       'Producto__r.Codigo_Proveedor2__c,' +
                       'Producto__r.ProductoBase__r.ProductName__c,' +
                       'Producto__r.ProductoBase__r.Name,' +
                       'Quantity__c,' +
                       'Total_Cnts__c,' +
                       'Net_Weight__c,' +
                       'Gross_Weight__c,' +
                       'CBM__c,' +
                       'Container_Number__c,' +
                       'Unidades__c,' +
                       'SEAL_Number__c ' +
                  'FROM PedidoLineItems__r) ' +
          'FROM PedidoDeCompra__c ' +
         'WHERE ';

        List<PedidoDeCompra__c> orders;
        PedidoDeCompra__c order;

        soqlBaseQuery = soqlBaseQuery + searchField + ' = :searchValue';
        orders = Database.query(soqlBaseQuery);

        if(orders.size() > 0) {
            order = orders.get(0);
        }
        return order;
    }

    public static PackingList__c getPackingListByOrder(String idOrder) {
        PackingList__c pl;
        List<PackingList__c> listPL;

        listPL = [SELECT Id, Name, Pedido__c FROM PackingList__c WHERE Pedido__c = :idOrder];

        if(listPL.size() > 0) {
            pl = listPL.get(0);
        }

        return pl;
    }

    public static List<ContentDocumentLink> getContentDocumentLink(List<String> docIds) {
        List<ContentDocumentLink> contentDocLinks;

        contentDocLinks = [SELECT Id, 
                                  LinkedEntityId, 
                                  ContentDocumentId 
                             FROM ContentDocumentLink 
                            WHERE LinkedEntityId IN :docIds];
        return contentDocLinks;
    }

    public static List<ContentVersion> getContentVersions(List<String> docIds) {
        List<ContentVersion> contentVersion;
        contentVersion = [SELECT Id,
                                 ContentLocation,
                                 ContentDocumentId,
                                 VersionData,
                                 Title, 
                                 PathOnClient 
                            FROM ContentVersion 
                           WHERE ContentDocumentId IN :docIds];
        return contentVersion;
    }


    public static Map<String, Decimal> getPedidoLineItemsTotales(String idPedido) {
        Map<String, Decimal> mapResults = new Map<String, Decimal>();
        AggregateResult[] results = null;

        results = [SELECT SUM(CBM__c) sumcbm, 
                          SUM(Net_Weight__c) netWt, 
                          SUM(Gross_Weight__c) grsWt  
                     FROM PedidoLineItem__c 
                    WHERE PedidoDeCompra__c = :idPedido];

        for (AggregateResult ar : results) {
            addMapEntry(ar, 'sumcbm', mapResults);
            addMapEntry(ar, 'netWt', mapResults);
            addMapEntry(ar, 'grsWt', mapResults);
        }

        return mapResults;
    }


    private static void addMapEntry(AggregateResult ar, String param, Map<String, Decimal> mapRes) {
        Decimal total;
        total = (Decimal)ar.get(param);
        if(total == null) {
            total = 0;
        }
        mapRes.put(param, total);
    }

    public static String getSociedadFromOrder(String orderId) {
        String sociedad;
        PedidoDeCompra__c pedido;
        pedido = [SELECT Id, 
                         Proforma__r.Cuenta__r.Parent.Sociedad__c,
                         Proforma__r.Cuenta__r.Parent.CurrencyISOCode, 
                         Name 
                    FROM PedidoDeCompra__c
                   WHERE Id = :orderId];
        
        sociedad = pedido.Proforma__r.Cuenta__r.Parent.Sociedad__c + ' ' + pedido.Proforma__r.Cuenta__r.Parent.CurrencyISOCode;
        return sociedad;
    }

    public static Sociedades__mdt getSociedadInfo(String sociedad) {
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
       return mdt;
   }


   public static AWS_Generacion_Cotizacion__mdt getAWSMetadatos(String label) {
      //AWSCotizacion   
      AWS_Generacion_Cotizacion__mdt mdt;
      mdt = [SELECT Id, 
                    MasterLabel,
                    DeveloperName,
                    Color_FOB_Price__c,
                    Numero_OLI__c,
                    test_items_to_proc__c,                    
                    Cotizacion_Font_Name__c,
                    Cotizacion_Font_Size__c,
                    AWS_URL_Base__c,
                    AWS_webcontext_name__c,
                    AWS_webpath__c,
                    AWS_call_method_name__c,
                    AWS_template_file__c,
                    AWS_S3_Bucket_Name__c,
                    AWS_S3_Region__c
               FROM AWS_Generacion_Cotizacion__mdt 
              WHERE MasterLabel = :label];
       return mdt;
   }


   public static EmailParserConfig__mdt getEmailParserMetadatos(String label) {
    EmailParserConfig__mdt mdt;
    mdt = [SELECT Id, 
                  MasterLabel,
                  DeveloperName,
                  Regex_Report_URL__c,
                  Subject_audit__c
             FROM EmailParserConfig__mdt 
            WHERE MasterLabel = :label];
     return mdt;
 }


   public static List<Sociedades__mdt> getSociedades() {
      List<Sociedades__mdt> mdts;
      mdts = [SELECT Id, 
                     MasterLabel,
                     Banco_Beneficiario__c,
                     Beneficiario__c,
                     Calle__c,
                     Calle_2__c,
                     Ciudad__c,
                     Correo_Electronico__c,
                     Direccion_Banco__c,
                     Divisa_de_la_Cuenta__c,
                     Division__c,
                     Identificador_Sociedad__c,
                     Nombre__c,
                     Numero_De_Cuenta__c,
                     Pais__c,
                     Razon_Social__c,
                     SWIFT_Code__c,
                     Telefono__c
                FROM Sociedades__mdt
            ORDER BY Identificador_Sociedad__c];
       return mdts;
    }

    public static List<Sociedades__mdt> getSociedades(String currencyp) {
        List<Sociedades__mdt> mdts;
        mdts = [SELECT Id, 
                       MasterLabel,
                       Banco_Beneficiario__c,
                       Beneficiario__c,
                       Calle__c,
                       Calle_2__c,
                       Ciudad__c,
                       Correo_Electronico__c,
                       Direccion_Banco__c,
                       Divisa_de_la_Cuenta__c,
                       Division__c,
                       Identificador_Sociedad__c,
                       Nombre__c,
                       Numero_De_Cuenta__c,
                       Pais__c,
                       Razon_Social__c,
                       SWIFT_Code__c,
                       Telefono__c
                  FROM Sociedades__mdt
                 WHERE Divisa_de_la_Cuenta__c = :currencyp
              ORDER BY Identificador_Sociedad__c];
         return mdts;
     }
  


    public static Portal_DO_Brands__c getPortalCS(String name) {
        Portal_DO_Brands__c portalConfig;
        portalConfig = [SELECT Id, 
                               Name, 
                               URL_Portal__c 
                          FROM Portal_DO_Brands__c 
                         WHERE Name = :name];
        return portalConfig;
    }

    public static List<SelectOption> getSelectOptions(SObjectField pobjField) {
        List<SelectOption> listSelectOptions = new List<SelectOption>();
        Schema.DescribeFieldResult fieldList =  pobjField.getDescribe();
        List<Schema.PicklistEntry> ple = fieldList.getPicklistValues();
        for( Schema.PicklistEntry pickListValue : ple) {
           listSelectOptions.add(new SelectOption(pickListValue.getValue(), pickListValue.getLabel()));
        }
        return listSelectOptions;
    }


    public static Map<String, PackingList__c> getPackingList(List<String> idsOrders) {
        Map<String, PackingList__c> mapIdOrderPL = new Map<String, PackingList__c>();
        List<PackingList__c> listPL;

        listPL = [SELECT Id, Name, Estado__c, Pedido__c FROM PackingList__c WHERE Pedido__c IN :idsOrders];
        for(PackingList__c pl : listPL) {
            mapIdOrderPL.put(pl.Pedido__c, pl);
        }
        return mapIdOrderPL;
    }

    public static Opportunity getOpportunity(String idOpp) {
        //origin : china
        //port of landing
        Opportunity opp;
        opp = [SELECT Id,
                      Name,
                      AccountId,
                      CurrencyIsoCode,
                      URL_Cotizacion__c,
                      CostoFOB__c,
                      Is_Brand_Selected__c,
                      Pricebook2Id,
                      Pricebook2.Margen__c,
                      PlanificacionComercial__r.PorcentajeAportaciones__c,
                      PlanificacionComercial__r.PorcentajeConvenio__c,
                      (SELECT Id,
                              ComentariosCatalogo__c,
                              ComentarioPackagingNuevo__c,
                              Name,
                              Porcentaje_Item__c,
                              Precio_Minimo__c,
                              UnitPrice, //precio de venta - precio fob
                              Quantity,
                              Product2Id,
                              Product2.Marca2__c,
                              Product2.Color2__c,
                              Comentario_atendido__c,
                              Producto_Packaging__c,
                              Producto_Packaging__r.Packaging__c,
                              Producto_Packaging__r.CostoPackaging__c,
                              RequierePackagingNuevo__c,
                              Product2.CostoImportacionUnidad__c,
                              Product2.PrecioDeFabrica__c,                              
                              Product2.Codigo_EAN2__c,
                              Product2.PlazoDeFabricacion__c, //lead time
                              Product2.CodigoDeProductoBase__c,//suppliers item
                              Product2.Marca__c,
                              Product2.CostoPackaging__c,
                              Product2.Name,  //spanish description
                              Product2.Precio_Vigente__c,
                              Product2.RecordType.DeveloperName,
                              Product2.ProductoBase__r.Description, //
                              Product2.ProductoBase__r.Descripcion_Larga__c,
                              Product2.ProductoBase__r.Material__c, //Composition(material)
                              Product2.ProductoBase__r.UnidadesPorMasterBox__c, // (quantuty per carton master)
                              Product2.Packaging__c, //packaging
                              Product2.MOQ__c, //MOQ
                              Product2.ProductoBase__r.IDImagen1__c,
                              Product2.ProductoBase__r.Imagen1__c,
                              Product2.ProductoBase__r.UnidadesHQ__c,
                              Product2.ProductoBase__r.UnidadesContainer40__c, // agregar json, java, columnas
                              Product2.ProductoBase__r.UnidadesContainer20__c,
                              Product2.ProductoBase__r.ProductoAltoCm__c, // H(cm)
                              Product2.ProductoBase__r.ProductoAnchoCm__c, // W(cm)
                              Product2.ProductoBase__r.ProductoLargoCm__c, //L(cm)
                              Product2.ProductoBase__r.Producto_detalle__c,
                              Product2.ProductoBase__r.ProductoDiametroCm__c, //diam
                              Product2.ProductoBase__r.ProductoPesoKg__c, //w(kg)
                              Product2.ProductoBase__r.ProductoM3__c, //cubic meter
                              Product2.ProductoBase__r.Producto2AltoCm__c, // H(cm)
                              Product2.ProductoBase__r.Producto2AnchoCm__c, // W(cm)
                              Product2.ProductoBase__r.Producto2LargoCm__c, //L(cm)
                              Product2.ProductoBase__r.Producto2_detalle__c,
                              Product2.ProductoBase__r.Producto2DiametroCm__c,
                              Product2.ProductoBase__r.Producto2PesoKg__c,
                              Product2.ProductoBase__r.Producto2M3__c,
                              Product2.ProductoBase__r.Producto3AltoCm__c, // H(cm)
                              Product2.ProductoBase__r.Producto3AnchoCm__c, // W(cm)
                              Product2.ProductoBase__r.Producto3LargoCm__c, //L(cm)
                              Product2.ProductoBase__r.Producto3_detalle__c,
                              Product2.ProductoBase__r.Producto3DiametroCm__c,
                              Product2.ProductoBase__r.Producto3PesoKg__c,
                              Product2.ProductoBase__r.Producto3M3__c,
                              Product2.ProductoBase__r.Masterbox1_detalle__c,
                              Product2.ProductoBase__r.MasterboxAltoCm__c,
                              Product2.ProductoBase__r.MasterboxAnchoCm__c,
                              Product2.ProductoBase__r.MasterboxLargoCm__c,
                              Product2.ProductoBase__r.MasterboxM3__c,
                              Product2.ProductoBase__r.MasterboxPesoKg__c,
                              Product2.ProductoBase__r.Masterbox2AltoCm__c,
                              Product2.ProductoBase__r.Masterbox2AnchoCm__c,
                              Product2.ProductoBase__r.Masterbox2LargoCm__c,
                              Product2.ProductoBase__r.Masterbox2M3__c,
                              Product2.ProductoBase__r.Masterbox2PesoKg__c,
                              Product2.ProductoBase__r.Masterbox2_detalle__c,
                              Product2.ProductoBase__r.Masterbox3AltoCm__c,
                              Product2.ProductoBase__r.Masterbox3AnchoCm__c,
                              Product2.ProductoBase__r.Masterbox3LargoCm__c,
                              Product2.ProductoBase__r.Masterbox3M3__c,
                              Product2.ProductoBase__r.Masterbox3PesoKg__c,
                              Product2.ProductoBase__r.Masterbox3_detalle__c,
                              Product2.ProductoBase__r.CodigoArancelario__c,
                              Product2.ProductoBase__r.Name,
                              Product2.ProductoBase__r.Clase__c,
                              Product2.ProductoBase__r.Subfamilia__c,
                              Product2.ProductoBase__r.Family,   
                              Product2.ProductoBase__r.Medidas_Agrupadas__c,  
                              Product2.ProductoBase__r.Packaging__c,
                              Product2.ProductoBase__r.Color__c,
                              Product2.Fabrica__r.PaisDelPuerto__c,
                              Product2.Fabrica__r.Puerto__c,
                              Product2.ProductoBase__r.ProductCode   //<ProductCode>.jpg
                         FROM OpportunityLineItems 
                     ORDER BY Product2.Name)
                 FROM Opportunity
                WHERE Id = :idOpp];
        return opp;
    }



    public static Opportunity getOpportunityMP(String idOpp) {
        //origin : china
        //port of landing
        Opportunity opp;
        opp = [SELECT Id,
                      Name,
                      CurrencyIsoCode,
                      CostoFOB__c,
                      Is_Brand_Selected__c,
                      Pricebook2Id,
                      Pricebook2.Margen__c,
                      PlanificacionComercial__r.PorcentajeAportaciones__c,
                      PlanificacionComercial__r.PorcentajeConvenio__c,
                      (SELECT Id,
                              ComentariosCatalogo__c,
                              Name,
                              Porcentaje_Item__c,
                              Precio_Minimo__c,
                              UnitPrice, //precio de venta - precio fob
                              Quantity,
                              Product2Id,
                              Product2.Marca2__c,
                              Comentario_atendido__c,
                              Producto_Packaging__c,
                              Producto_Packaging__r.Packaging__c,
                              Producto_Packaging__r.CostoPackaging__c,
                              RequierePackagingNuevo__c,
                              Product2.Descripcion_Larga__c,
                              Product2.CostoImportacionUnidad__c,
                              Product2.PrecioDeFabrica__c,                              
                              Product2.CodigoDeProductoBase__c,//suppliers item
                              Product2.Marca__c,
                              Product2.CostoPackaging__c,
                              Product2.Name,  //spanish description
                              Product2.RecordType.DeveloperName,
                              Product2.Packaging__c, //packaging
                              Product2.ProductoBase__r.IDImagen1__c,
                              Product2.ProductoBase__r.Imagen1__c,
                              Product2.ProductoBase__r.CodigoArancelario__c,
                              Product2.ProductoBase__r.Name,
                              Product2.ProductoBase__r.ProductCode   //<ProductCode>.jpg
                         FROM OpportunityLineItems)
                 FROM Opportunity
                WHERE Id = :idOpp];
        return opp;
    }




    public static List<PedidoLineItem__c> getPedidoLineItems(String idPedido) {
        List<PedidoLineItem__c> pli;
        pli = [SELECT Id,
                      ProformaLineItem__r.Producto__r.CodigoDeProductoBase__c,
                      ProformaLineItem__r.producto__r.Marca2__c,
                      ProformaLineItem__r.producto__r.Descripcion_Larga__c,
                      ProformaLineItem__r.PrecioUnitario__c,
                      Net_Weight__c,
                      Gross_Weight__c,
                      CBM__c,
                      Producto__r.Codigo_EAN2__c,
                      SEAL_Number__c,
                      Container_Number__c,
                      Unidades__c,
                      UnidadesPorMasterbox__c,
                      PrecioDeVentaTot__c
                 FROM PedidoLineItem__c 
                WHERE PedidoDeCompra__c = :idPedido];
        return pli;
    }

    public static List<ProformaLineItem__c> getProformaLineItems(String idProforma) {
        List<ProformaLineItem__c> prli;
        prli = [SELECT Id
                  FROM ProformaLineItem__c 
                 WHERE Proforma__c = :idProforma];
        return prli;
    }


    public static List<Exchange_Rate__c> getExchangeRates(List<String> exchangeDates) {
        List<Exchange_Rate__c> exchangeRates;
        exchangeRates = [SELECT Id, 
                                Currency_Code__c, 
                                Exchange_Date__c, 
                                Name, 
                                Rate__c,
                                Rate_Euro_Currency__c 
                           FROM Exchange_Rate__c  
                          WHERE Name IN :exchangeDates];
        return exchangeRates;
    }


    public static List<Exchange_Rate__c> getExchangeRates(Date startDate, Date endDate) {
        List<Exchange_Rate__c> exchangeRates;
        exchangeRates = [SELECT Id, 
                                Currency_Code__c, 
                                Exchange_Date__c, 
                                Name, 
                                Rate__c,
                                Rate_Euro_Currency__c 
                           FROM Exchange_Rate__c  
                          WHERE Exchange_Date__c >= :startDate
                            AND Exchange_Date__c <= :endDate];
        return exchangeRates;
    }


    public static Proforma__c getProformaBase(String idProforma) {
        List<Proforma__c> proformas;
        Proforma__c proforma;
        proformas = [SELECT Id,
                            Name,
                            Cuenta__c,
                            Cuenta__r.Name,
                            Oportunidad__c,
                            Oportunidad__r.PlanificacionComercial__c,
                            Oportunidad__r.PlanificacionComercial__r.Name                            
                       FROM Proforma__c
                      WHERE Id = :idProforma];
        if (proformas != null && proformas.size() > 0) {
            proforma = proformas.get(0);
        }
        return proforma;
    }


    public static List<Proforma__c> getProformas(String idProforma, String idCuenta, String idPlanificacion) {
        List<Proforma__c> proformas;
        proformas = [SELECT Id,
                            Name,
                            Cuenta__c,
                            Cuenta__r.Name,
                            Oportunidad__c,
                            Oportunidad__r.Name,
                            Oportunidad__r.PlanificacionComercial__c,
                            Oportunidad__r.PlanificacionComercial__r.Name,
                            (SELECT Id,
                                    Name,
                                    Producto__c,
                                    Producto__r.Name,
                                    Unidades__c,
                                    Proforma__c
                               FROM ProformaLineItems__r),
                            (SELECT Id,
                                    Name,
                                    Proforma__c 
                               FROM PedidosDeCompra__r)
                       FROM Proforma__c
                      WHERE Cuenta__c = :idCuenta
                        AND Oportunidad__r.PlanificacionComercial__c = :idPlanificacion
                        AND Id != :idProforma
                   ORDER BY Oportunidad__r.Name];
        return proformas;
    }


    public static List<Proforma__c> getProformas(List<String> idProformas) {
        List<Proforma__c> proformas;
        proformas = [SELECT Id,
                            Name,
                            Cuenta__c,
                            Cuenta__r.Name,
                            Cuenta__r.ParentId,
                            Oportunidad__c,
                            Oportunidad__r.Name,
                            ConfirmacionCliente__c,
                            (SELECT Id,
                                    Name,
                                    Producto__c,
                                    Producto__r.Name,
                                    CostoTotal__c,
                                    Codigo_de_Producto__c,
                                    CostoTotalUnitario__c,
                                    CostoExtraUnitario__c,
                                    CostoExtraTot__c,
                                    CostoFabrica__c,
                                    CostoFabricaTot__c,
                                    Proforma__c
                               FROM ProformaLineItems__r)
                       FROM Proforma__c
                      WHERE Id IN :idProformas];
        return proformas;
    }

    
    public static Map<String, OpportunityLineItem> getOpportunityLineItems(List<String> idsOpps, List<String> productCodes) {
        List<OpportunityLineItem> oppLineItems;
        Map<String, OpportunityLineItem> results = new Map<String, OpportunityLineItem>();
        oppLineItems = [SELECT Id,
                               Name,
                               OpportunityId, 
                               Codigo_de_Producto__c,
                               CostoProducto__c
                          FROM OpportunityLineItem
                         WHERE OpportunityId IN :idsOpps
                           AND Codigo_de_Producto__c IN :productCodes];
        for(OpportunityLineItem oppLineItem : oppLineItems) {
            results.put(oppLineItem.OpportunityId + '-' + oppLineItem.Codigo_de_Producto__c, oppLineItem);
        }
        return results;
    }


    public static List<Documento__c> getDocumentosProforma(List<String> idsProforma) {
        List<Documento__c> docs;
        docs = [SELECT Id,
                       Name,
                       Proceso__c,
                       Tipo_de_Documento__c,
                       Proforma__c
                  FROM Documento__c
                 WHERE Proforma__c IN :idsProforma];
        return docs;
    }


    public static Catalogo__c getCatalogoByToken(String token) {
        Catalogo__c catalogo;        
        List<Catalogo__c> catalogos;
        catalogos = [SELECT Id, 
                        Name,
                        Familias__c,
                        Cliente__c,
                        Cliente__r.Name,
                        Cliente__r.CurrencyIsoCode,
                        Clases__c,
                        Portal_Token__c                            
                        FROM Catalogo__c
                        WHERE Portal_Token__c = :token];

        if (catalogos != null && catalogos.size() > 0) {
            catalogo = catalogos.get(0);
        }
        return catalogo;
    }


    public static List<Catalogo_FSC__mdt> getCatalogosFSCMetadatos(String tipo, String cveInmediato, String cvePadre) {
        List<Catalogo_FSC__mdt> mdts;
        mdts = [SELECT Id, 
                       MasterLabel,
                       Clave__c,
                       Descripcion__c,
                       Imagen__c,
                       id_href__c,
                       ImagenSubF__c,
                       Clave_padre_inmediato__c,
                       Clave_padre__c,
                       Tipo__c
                  FROM Catalogo_FSC__mdt
                 WHERE Tipo__c = :tipo
                   AND Clave_padre_inmediato__c = :cveInmediato
                   AND Clave_padre__c = :cvePadre];
         return mdts;
     }

     public static List<Product2> getProductsByFamSubFamClasses(String famPref, String subfamPref, List<String> cls) {
        String fam = famPref + '%', subFam = subfamPref + '%';
        List<Product2> productos;
        productos = [SELECT Id,
                             ProductoBase__r.Id,
                             ProductoBase__r.Name,
                             ProductoBase__r.ProductName__c,
                             ProductoBase__r.ProductCode,
                             ProductoBase__r.IDImagen1__c,                             
                             ProductoBase__r.Imagen1__c,
                             ProductoBase__r.Imagen2__c,
                             ProductoBase__r.Imagen3__c,
                             ProductoBase__r.Imagen4__c,
                             ProductoBase__r.Medidas_Agrupadas__c,
                             ProductoBase__r.Color__c,
                     	     ProductoBase__r.Material__c,
                             ProductoBase__r.Clase__c
                        FROM Product2
                       WHERE RecordType.DeveloperName = 'ProductoDeFabrica'
                         AND ProductoBase__r.Clase__c IN :cls
                         AND ProductoBase__r.Listado_en_catalogo__c = true
                         AND isActive = true
                         ORDER BY ProductoBase__r.Name, ProductoBase__r.Orden_Medidas__c, ProductoBase__r.Color__c LIMIT 500];
       return productos;
    }


    public static Map<String, PriceBookEntry> getMapProductsPriceBook(List<String> idsProduct, String priceBookName, String currencyPriceBook) {
        Map<String, PriceBookEntry> mapResult = new Map<String, PriceBookEntry>();
        List<PriceBookEntry> pbeList = [SELECT Id, 
                                               CurrencyIsoCode,
                                               Product2Id, 
                                               Product2.isActive,
                                               PriceBook2Id, 
                                               PriceBook2.Name, 
                                               Product2.Name,
                                               Product2.RecordType.DeveloperName
                                          FROM PriceBookEntry 
                                         WHERE PriceBook2.Name = :priceBookName 
                                           AND Product2Id IN :idsProduct
                                           AND Product2.isActive = true
                                           AND CurrencyIsoCode = :currencyPriceBook
                                      ORDER BY Product2Id ];
        for(PriceBookEntry pbe : pbeList) {
            mapResult.put(pbe.Product2Id, pbe);
        }
        return mapResult;
    }


    public static List<Product2> getProductsByProductCode(List<String> codigos) {
        List<Product2> productos;
        productos = [SELECT Id, 
                            ProductoBase__r.Id,
                            ProductoBase__r.Name, 
                            ProductoBase__r.ProductCode,
                            ProductoBase__r.ProductName__c,
                            ProductoBase__r.Family,
                            ProductoBase__r.Subfamilia__c,
                            ProductoBase__r.Clase__c,
                            ProductoBase__r.IDImagen1__c,
                            ProductoBase__r.IDImagen2__c,
                            ProductoBase__r.IDImagen3__c,
                            ProductoBase__r.IDImagen4__c,
                            ProductoBase__r.Imagen1__c,
                            ProductoBase__r.Imagen2__c,
                            ProductoBase__r.Imagen3__c,
                            ProductoBase__r.Imagen4__c,
                            ProductoBase__r.Medidas_Agrupadas__c,
                            ProductoBase__r.Material__c,
                            ProductoBase__r.Color__c,
                            ProductoBase__r.Packaging__c,
                            ProductoBase__r.UnidadesPorMasterBox__c,
                            ProductoBase__r.UnidadesContainer20__c,
                            ProductoBase__r.UnidadesContainer40__c,
                            ProductoBase__r.UnidadesHQ__c,
                            ProductoBase__r.RecordType.DeveloperName 
                       FROM Product2
                      WHERE RecordType.DeveloperName = 'ProductoDeFabrica'
                      AND ProductoBase__r.Listado_en_catalogo__c = true
                      AND isActive = true
                      AND ProductoBase__r.ProductCode IN :codigos];

        return productos;
    }

    public static Pricebook2 getListaPrecios(String name) {
        Pricebook2 pb;
        //Preferencial, Retailer
        pb = [SELECT Id,
                     Name,
                     CurrencyIsoCode,
                     IsActive,
                     Margen__c
                FROM Pricebook2
               WHERE IsActive = true
                 AND Name = :name];
        return pb;
    }

    
    public static PlanificacionComercial__c getPlanificacion(String name, Id idCuenta) {
        PlanificacionComercial__c planificacion;
        List<PlanificacionComercial__c> planificaciones;
        planificaciones = [SELECT Id, 
                                  Name,
                                  PorcentajeConvenio__c,
                                  PorcentajeAportaciones__c
                             FROM PlanificacionComercial__c
                            WHERE Name = :name
                            AND Cuenta__c = :idCuenta
                            AND Activa__c = true];

        if (planificaciones != null && planificaciones.size() > 0) {
            planificacion = planificaciones.get(0);
        }
        return planificacion;
    }
    
    
    public static OpportunityLineItem getClonedRecordOLI(String oliID) {
        Boolean res;
        OpportunityLineItem result;
        Set<String> fieldNames;
        Map<String, Schema.SObjectField> fieldMap = OpportunityLineItem.sObjectType.getDescribe().fields.getMap();
        
        fieldNames = fieldMap.keySet();
        
        res = fieldNames.remove('pricebookentryid');
        
        List<OpportunityLineItem> pro = Database.query('SELECT ' + String.join((Iterable<String>)fieldNames, ',') 
                                            + ' FROM OpportunityLineItem'
                                            + ' WHERE Id = \'' + oliID + '\'');
        if(pro != null && pro.size() > 0) {
           result = pro[0];
        }
        return result;
    }
    
    public static Map<String, OpportunityLineItem> getClonedRecordsOLI(List<String> oliIDs) {
        String inCondition = '';
        Boolean res;
        Set<String> fieldNames;
        Map<String, OpportunityLineItem> result;

        result = new Map<String, OpportunityLineItem>();
        Map<String, Schema.SObjectField> fieldMap = OpportunityLineItem.sObjectType.getDescribe().fields.getMap();
        
        for(String oliId : oliIDs) {
            inCondition = inCondition + '\'' + oliId + '\','; 
        }
        inCondition = inCondition.substring(0, inCondition.length() - 1);
        inCondition = '(' + inCondition + ')';

        fieldNames = fieldMap.keySet();
        fieldNames.remove('pricebookentryid');
        List<OpportunityLineItem> oplis = Database.query('SELECT ' + String.join((Iterable<String>)fieldNames, ',') 
                                                        + ' FROM OpportunityLineItem'
                                                       + ' WHERE Id IN ' + inCondition);
        for(OpportunityLineItem oli : oplis) {
            result.put(oli.Id, oli);
        }
        return result;
    }    
    
    public static Integer getCountOpportunitiesByCatalog(String idCatalogo) {
        Integer numOpps;
        AggregateResult[] results = null;
        
        results = [SELECT COUNT(Id) numOp
                     FROM Opportunity 
                    WHERE Catalogo__c = :idCatalogo];

        if(results != null && !results.isEmpty()) {
            numOpps = (Integer)results[0].get('numOp');
        }

        return numOpps;
    }

    public static Envio_Correos__c getCSEnvioCorreos(String flujo) {
        Envio_Correos__c result;
        List<Envio_Correos__c> ecCSList;

        ecCSList = [SELECT Id, 
                           Name, 
                           correo_electronico__c
                      FROM Envio_Correos__c
                     WHERE flujo__c = :flujo];

        if(!ecCSList.isEmpty()) {
            result = ecCSList.get(0); 
        }
        return result;
    }
    

    public static Integer getMaxInvoiceNumber(String typeInvoice) {
        String regexPatternPedidoName = '(PE[0-9]{5}){1}(\\.[0-9]{1,3})?';
        Boolean isValidPedidoName = false;
        String pedidoName;
        String[] tokens;
        
        String likeFilter = typeInvoice + '%';
        String consecutiveString = '';
        System.debug('DoBrandsDAO - typeInvoice [' + likeFilter + ']');
        List<PedidoDeCompra__c> orders;
        orders = [SELECT Name,
                         Numero_de_Factura__c 
                    FROM PedidoDeCompra__c 
                   WHERE Name LIKE :likeFilter 
                ORDER BY Name DESC LIMIT 1];

        System.debug('DoBrandsDAO - orders size [' + orders.size() + ']');
        if(orders.size() == 0) {
            return 0;
        }
        
        pedidoName = orders.get(0).Name;

        isValidPedidoName = Pattern.matches(regexPatternPedidoName, pedidoName);
        if(!isValidPedidoName) {
            throw new PedidoDeCompraException('Incorrect order name [' + pedidoName + '] . The format is PE00000.000 or PE00000');
        }

        System.debug('DoBrandsDAO - name max pedido [' + pedidoName + ']');
        tokens = pedidoName.split('\\.');
        consecutiveString = tokens[0].substring(4, tokens[0].length());
        
        //consecutiveString = orders.get(0).Name.substring(4, orders.get(0).Name.length());
        System.debug('DoBrandsDAO - consecutiveString [' + consecutiveString + ']');
                
        //System.debug('DoBrandsDAO - factura [' + orders.get(0).Numero_de_Factura__c + ']');
        //tokens = orders.get(0).Numero_de_Factura__c.split('/');
        System.debug('DoBrandsDAO - consecutiveString integer [' + Integer.valueOf(consecutiveString) + ']');
        //return Integer.valueOf(tokens[1]);
        return Integer.valueOf(consecutiveString);
    }
}