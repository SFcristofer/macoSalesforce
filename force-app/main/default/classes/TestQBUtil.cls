public class TestQBUtil {

    public String marcaProductoGarden;
    public String marcaProductoOutdoorSoriana;
    public String familyProductoGarden;

    public void setupMarcaValues() {
        String marcaValue;
        String marcaValueUpper;
        Schema.DescribeFieldResult fieldResult = Product2.Marca__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple) {
            marcaValue = pickListVal.getLabel();
            marcaValueUpper = marcaValue.toUpperCase();
            if(marcaValueUpper.contains('GARDEN')) {
                marcaProductoGarden = marcaValue;
            }
            if(marcaValueUpper.contains('OUTDOOR') && marcaValueUpper.contains('SORIANA')) {
                marcaProductoOutdoorSoriana = marcaValue;
            }
        }
    }
    
    public void setupProductFamilyValues() {
        String familyValue;
        String familyValueUpper;        
        Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple) {
            familyValue = pickListVal.getLabel();
            familyValueUpper = familyValue.toUpperCase();
            if(familyValueUpper.contains('GARDEN')) {
                familyProductoGarden = familyValue;
            }
        }
        System.debug('TestUtil - family [' + familyProductoGarden + ']');
    }

    private void initEscandallo(){
        Id escandalloRecordTypeId = Schema.SObjectType.Escandallo__c.getRecordTypeInfosByName().get('Escandallo').getRecordTypeId();
        Escandallo__c escandallo = new Escandallo__c(Name = 'Único', 
                                                    RecordTypeId = escandalloRecordTypeId,
                                                    CambioDocumentsXHQ__c = 500,
                                                    CertificadoOrigen__c = 500,
                                                    InspeccionXEntrega__c = 500,
                                                    NroInspecciones__c = 1,
                                                    Muestras__c = 120,
                                                    ComisionAdministrativa__c = 0.02);
        insert escandallo;
    } 

    public Account createCliente() {
        Account cliente;
        Account fabrica;        
        PlanificacionComercial__c pc;
        
        EstudioOportunidad__c eo;
        Opportunity opp;
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId();                                    

        cliente = new Account(RecordTypeId = idRT,
                              Name = 'Cliente - cliente',
                              Estado__c = 'Activo',
                              Codigo_rapido__c = '22233',
                              Codigo_pais2__c = 'ESP',
                              Balance_Cuenta__c = 2,                                
                              Credito_autorizado__c = 5000,
                              RazonSocial__c = 'razonsocial',
                              NroIdFiscal__c = '12345',
                              PorcentajeAportaciones__c = 25,
                              IdQbo__c = '123',
                              PorcentajeConvenio__c = 30,
                              PlazoPago__c = '30',
                              FormaPago__c = 'Transferencia',
                              Sociedad__c = 'Do América',
                              CurrencyIsoCode = 'USD',
                              EmailComercial__c = 'comercial@mail.com');
        insert cliente;
        
        setupMarcaValues(); 
        setupProductFamilyValues();        
               
        pc = createPlanificacionComercial(cliente);
        opp = createOpportunityOriginal(cliente, pc);
        fabrica = createFabrica('China1');
        eo = createEstudioOportunidad(fabrica, opp);
        
        createProformasPedidos(cliente, eo, opp, fabrica);        

        return cliente;
    }

    
    public FacturaDeCliente__c createFacturaCliente() {
        Account cliente;
        FacturaDeCliente__c facturaCliente;
        cliente = createCliente();
        
        facturaCliente = new FacturaDeCliente__c(Cliente__c = cliente.Id);
        facturaCliente.Estado__c = 'Borrador';
        
        insert facturaCliente;
        
        createItemsFacturaCliente(facturaCliente.Id);
        
        
        
        return facturaCliente;
    }
    
    public void createItemsFacturaCliente(String idFactura) {
        ItemDeFacturaDeCliente__c item;
        List<ItemDeFacturaDeCliente__c> items;
        
        items = new List<ItemDeFacturaDeCliente__c>();
        
        item = new ItemDeFacturaDeCliente__c(Factura__c = idFactura, Cantidad__c = 50);
        items.add(item);

        item = new ItemDeFacturaDeCliente__c(Factura__c = idFactura, Cantidad__c = 60);
        items.add(item);

        insert items;
    }
    
    
    public PlanificacionComercial__c createPlanificacionComercial(Account cliente) {
        PlanificacionComercial__c pc;
        Integer year = Date.today().year();
        pc = new PlanificacionComercial__c(Name = String.valueOf(year), 
                                           Cuenta__c = cliente.Id,
                                           Activa__c = true,
                                           Inicio__c = Date.newInstance(year, 1, 1),
                                           Fin__c = Date.newInstance(year, 12, 31),
                                           PorcentajeAportaciones__c = 10,
                                           PorcentajeConvenio__c = 3,
                                           Objetivo_de_Margen__c = 50,
                                           ObjetivoDeVentas__c = 1000000);
        insert pc;
        return pc;
    }
    
    
    public Opportunity createOpportunityOriginal(Account cliente, PlanificacionComercial__c pc) {
        Opportunity opp;
        Integer year = Date.today().year();
        Date opDate = Date.newInstance(year, Date.today().month() , Date.today().day());
        opp = new Opportunity(Name = 'Opportunity Original',
                              AccountId = cliente.Id,
                              PlanificacionComercial__c = pc.Id,
                              CloseDate = opDate,
                              StageName = 'Toma de Contacto',
                              Campana__c = 'Back to School',
                              Fecha_de_Compromiso__c = opDate);
        insert opp;
        
        return opp;
    }
    
    
    private Account createFabrica(String name) {
        Account fabrica;
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Proveedor').getRecordTypeId();

        fabrica = new Account(RecordTypeId = idRT,
                                Name = name,
                                Type = 'Fábrica',
                                IdQbo__c = '123',
                                Estado__c = 'Activo',
                                Codigo_pais2__c = 'ESP',
                                RazonSocial__c = '9987987Y',
                                NroIdFiscal__c = 'ABC1234',
                                PaisDelPuerto__c = 'China',
                                EmailComercial__c = 'delivery@infolastic.com',
                                Portal_Token__c = '12345',
                                Portal_Token_Verificacion__c = '12345',                                
                                Puerto__c = 'QINGDAO, CHINA',
                                PlazoPago__c = '30',
                                PorcentajeDeposito__c = '10',
                                Codigo_rapido__c = '12345',
                                Plazo_Precios_Proveedor__c = '15',
                                TiempoServicioMedio__c = '15');
        insert fabrica;
        return fabrica;
    }
    
    
    public EstudioOportunidad__c createEstudioOportunidad(Account fabrica, Opportunity oppOrig) {
       EstudioOportunidad__c eoins;

       EstudioOportunidad__c newEstudio = new EstudioOportunidad__c(Oportunidad__c = oppOrig.Id,
                                                                    Fabrica__c = fabrica.Id);
       insert newEstudio;

       eoins = [SELECT Id, Fabrica__c, Oportunidad__c, Oportunidad__r.AccountId, Oportunidad__r.Name FROM EstudioOportunidad__c WHERE Id = :newEstudio.Id];
       return eoins;
    }

    
    public List<Proforma__c> createProformasPedidos(Account pcliente, EstudioOportunidad__c eo, Opportunity oppOriginal, Account fabrica) {
        List<PedidoDeCompra__c>  pedidosCompra = new List<PedidoDeCompra__c>();        
        List<Proforma__c> proformasSplit = new List<Proforma__c>();
        Proforma__c p;
        Proforma__c proforma;        
        Proforma__c pp;
        PedidoDeCompra__c pedidoCompra;
        
        PedidoDeCompra__c pedido1;
        PedidoDeCompra__c pedido2;
        PedidoDeCompra__c pedido3;
        PedidoDeCompra__c pedido4;
        PedidoDeCompra__c pedido5;
        
        PedidoLineItem__c pedidoLine;
        List<PedidoLineItem__c> pedidoLineItems = new List<PedidoLineItem__c>();
        
        Id idRTProd = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
        Product2 productoBase;
        Product2 parrillaBase;
        Product2 parrilla;
        Product2 bancoBase;
        Product2 banco;
        
        System.debug(' ******************* createProformasSplit *****************************');
        System.debug(' ******************* acc cuenta[' + pcliente.Id + ']');
        System.debug(' ******************* acc cuenta-parent[' + pcliente.ParentId + ']');
        System.debug(' ******************* acc [' + pcliente.Parent.Agente_Cliente__c + ']');


/*        productoBase = new Product2(Name = 'Parrilla',
                                    RecordTypeId = idRTProd, 
                                    M3Unidad__c = 0.5,
                                    UnidadesPorMasterBox__c = 2, 
                                    UnidadesHQ__c = 1000,
                                    UnidadesContainer20__c = 400,
                                    isActive = false,
                                    MasterboxAltoCm__c = '10',
                                    MasterboxAnchoCm__c = '10',
                                    MasterboxLargoCm__c = '10',
                                    MasterboxM3__c = 1000,
                                    ProductCode = '12345',
                                    Family = familyProductoGarden,
                                    Subfamilia__c = '1-Muebles de Jardín',
                                    Clase__c = '01-Resina y Plástico',
                                    Registrado_Libra__c = false,
                                    Marca__c = marcaProductoGarden);

        parrillaBase = productoBase;
        insert parrillaBase;
        
        productoBase = new Product2(Name = 'Banco',
                                    RecordTypeId = idRTProd, 
                                    M3Unidad__c = 0.5,
                                    UnidadesPorMasterBox__c = 2,
                                    UnidadesHQ__c = 1000,
                                    UnidadesContainer20__c = 400,
                                    isActive = false,
                                    MasterboxAltoCm__c = '10',
                                    MasterboxAnchoCm__c = '10',
                                    MasterboxLargoCm__c = '10',
                                    MasterboxM3__c = 1000,
                                    Family = familyProductoGarden,
                                    Subfamilia__c = '1-Muebles de Jardín',
                                    Clase__c = '01-Resina y Plástico',
                                    Marca__c = marcaProductoGarden);
        bancoBase = productoBase;
        insert bancoBase;*/
        
/*        Id idRTProdFab = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('ProductoDeFabrica').getRecordTypeId();

        Date fechaValida = Date.today();
        Date fechaNoValida = Date.today();
        fechaNoValida = fechaNovalida.addDays(-20);

        List<Product2>prodDeFabricaSplit = new List<Product2>();

        parrilla = new Product2(Name = parrillaBase.Name,
                                       RecordTypeId = idRTProdFab, 
                                       ProductoBase__c = parrillaBase.Id, 
                                       Packaging__c = '1-CAJA MARRON',
                                       Fabrica__c = fabrica.Id,
                                       PlazoDeFabricacion__c = '45-60 días',
                                       MOQ__c = 1000,
                                       Fecha_revision_costo__c = fechaNoValida,
                                       PrecioDeFabrica__c = 20,
                                       CostoPackaging__c = 4,
                                       isActive = true);
        prodDeFabricaSplit.add(parrilla);

        
        banco = new Product2(Name = bancoBase.Name,
                                    RecordTypeId = idRTProdFab, 
                                    ProductoBase__c = bancoBase.Id, 
                                    Packaging__c = '1-CAJA MARRON',
                                    Fabrica__c = fabrica.Id,
                                    PlazoDeFabricacion__c = '45-60 días',
                                    MOQ__c = 1000,
                                    Fecha_revision_costo__c = fechaValida,
                                    PrecioDeFabrica__c = 20,
                                    CostoPackaging__c = 4,
                                    isActive = true);
        prodDeFabricaSplit.add(banco);
        
        insert prodDeFabricaSplit;*/

        System.debug('TestUtil.createProformasSplit oppid [' + oppOriginal.Id + '] [' + oppOriginal.AccountId + '] eop[' + eo.Id + '] [' + eo.Oportunidad__c + '] [' + eo.Oportunidad__r.AccountId + ']');
/*        p = new Proforma__c(Name = 'Vacia1',
                            TipoDeContenedor__c = '20 pies',
                            EstudioOportunidad__c = eo.Id,
                            Oportunidad__c = oppOriginal.Id,
                            ConfirmacionCliente__c = true,
                            Cuenta__c = pcliente.Id);

        proformasSplit.add(p);

        p = new Proforma__c(Name = 'Vacia2',
                            TipoDeContenedor__c = '20 pies',
                            EstudioOportunidad__c = eo.Id,
                            Oportunidad__c = oppOriginal.Id,
                            ConfirmacionCliente__c = true,                            
                            Cuenta__c = pcliente.Id);

        proforma = p;
        proformasSplit.add(p);

        pp = new Proforma__c(Name = 'PFPedidos1',
                            TipoDeContenedor__c = '20 pies',
                            EstudioOportunidad__c = eo.Id,
                            Oportunidad__c = oppOriginal.Id,
                            ConfirmacionCliente__c = true,                            
                            Cuenta__c = pcliente.Id);

        proformasSplit.add(pp);

        insert proformasSplit;*/
        

/*        System.debug('PROFORM APP [' + pp.Id + '] [' + pp.Cuenta__c + ']');

        Id idRT; 
        List<Schema.RecordTypeInfo> listrt = Schema.sObjectType.PedidoDeCompra__c.getRecordTypeInfos();
        for(Schema.RecordTypeInfo srti : listrt) {
            if(srti.getDeveloperName().equals('Principal') && srti.isDefaultRecordTypeMapping() && !srti.isMaster()) {
                idRT = srti.getRecordTypeId();
                break;
            }
        }        

        pedido1 = new PedidoDeCompra__c(Name = 'PedidoSplit1',
                                        Proforma__c = pp.Id,
                                        NumeroDeContenedor__c = '222',
                                        N_de_Seal__c = '123',
                                        PorcentajeDepositoAFabrica__c = 5,
                                        Numero_de_Factura__c = 'A20/001',
                                        Portal_Token__c = '12345',
                                        Email_Fabrica__c = 'test@test.com',
                                        Numero_de_Factura_Proveedor__c = 'p0001',
                                        RecordTypeId = idRT,
                                        Fecha_Factura__c = Date.today(),
                                        Enviado_libra__c = false,
                                        Aprobado_Envio__c = true,
                                        Fecha_Factura_Proveedor__c = Date.today());
        pedidosCompra.add(pedido1);

        pedido2 = new PedidoDeCompra__c(Name = 'PedidoSplit2',
                                        Proforma__c = pp.Id,
                                        NumeroDeContenedor__c = '222',
                                        N_de_Seal__c = '123',
                                        Numero_de_Factura__c = 'A20/002',
                                        Numero_de_Factura_Proveedor__c = 'p0002',
                                        PorcentajeDepositoAFabrica__c = 5,
                                        RecordTypeId = idRT,
                                        Fecha_Factura__c = Date.today(),
                                        Enviado_libra__c = false,
                                        Aprobado_Envio__c = true,
                                        Fecha_Factura_Proveedor__c = Date.today());
        pedidosCompra.add(pedido2);

        pedido3 = new PedidoDeCompra__c(Name = 'PedidoSplit3',
                                        Proforma__c = pp.Id,
                                        NumeroDeContenedor__c = '222',
                                        N_de_Seal__c = '123',
                                        Numero_de_Factura__c = 'A20/003',
                                        PorcentajeDepositoAFabrica__c = 5,
                                        Numero_de_Factura_Proveedor__c = 'p0003',
                                        RecordTypeId = idRT,
                                        Fecha_Factura__c = Date.today(),
                                        Enviado_libra__c = false,
                                        Aprobado_Envio__c = true,
                                        Fecha_Factura_Proveedor__c = Date.today());
        pedidosCompra.add(pedido3);

        pedido4 = new PedidoDeCompra__c(Name = 'PedidoSplit4',
                                        Proforma__c = pp.Id,
                                        NumeroDeContenedor__c = '222',
                                        N_de_Seal__c = '123',
                                        Numero_de_Factura__c = 'A20/004',
                                        PorcentajeDepositoAFabrica__c = 5,
                                        Numero_de_Factura_Proveedor__c = 'p0004',
                                        RecordTypeId = idRT,
                                        Fecha_Factura__c = Date.today(),
                                        Enviado_libra__c = false,
                                        Aprobado_Envio__c = true,
                                        Fecha_Factura_Proveedor__c = Date.today());
        pedidosCompra.add(pedido4);

        pedido5 = new PedidoDeCompra__c(Name = 'PedidoSplit5',
                                        Proforma__c = pp.Id,
                                        NumeroDeContenedor__c = '222',
                                        N_de_Seal__c = '123',
                                        Numero_de_Factura__c = 'A20/005',
                                        PorcentajeDepositoAFabrica__c = 5,
                                        Numero_de_Factura_Proveedor__c = 'p0005',
                                        RecordTypeId = idRT,
                                        Fecha_Factura__c = Date.today(),
                                        Enviado_libra__c = false,
                                        Aprobado_Envio__c = true,
                                        Fecha_Factura_Proveedor__c = Date.today());
        pedidosCompra.add(pedido5);

        insert pedidosCompra;*/
        
/*        pedidoLine = new PedidoLineItem__c(PedidoDeCompra__c = pedido1.id,
                                           PrecioDeVenta__c = 67,
                                           UnidadesPorMasterbox__c = 100, 
                                           NumeroDeCajas__c = 1,
                                           Producto__c = parrilla.Id,
                                           CostoOrigen__c = 5,
                                           Aportaciones_2__c = 7,
                                           CBMMasterbox__c = 2,
                                           Requisitos_Especiales__c = 'REqEspPL');
        pedidoLineItems.add(pedidoLine);

        pedidoLine = new PedidoLineItem__c(PedidoDeCompra__c = pedido2.id,
                                           PrecioDeVenta__c = 67,
                                           UnidadesPorMasterbox__c = 100, 
                                           NumeroDeCajas__c = 3,
                                           Producto__c = parrilla.Id,
                                           CostoOrigen__c = 5,
                                           CBMMasterbox__c = 2,
                                           Requisitos_Especiales__c = 'REqEspPL');
        pedidoLineItems.add(pedidoLine);

        pedidoLine = new PedidoLineItem__c(PedidoDeCompra__c = pedido3.id,
                                           PrecioDeVenta__c = 67,
                                           UnidadesPorMasterbox__c = 100, 
                                           NumeroDeCajas__c = 3,
                                           Producto__c = banco.Id,
                                           CostoOrigen__c = 5,
                                           CBMMasterbox__c = 2,
                                           Requisitos_Especiales__c = 'REqEspPL');
        pedidoLineItems.add(pedidoLine);
        insert pedidoLineItems; */
        
        
        FacturaDeCliente__c facturaCliente;   
        facturaCliente = new FacturaDeCliente__c(Cliente__c = pcliente.Id);
        facturaCliente.Estado__c = 'Borrador';
        
        insert facturaCliente;
                    
        ItemDeFacturaDeCliente__c item;
        List<ItemDeFacturaDeCliente__c> items;
        
        items = new List<ItemDeFacturaDeCliente__c>();
        
        item = new ItemDeFacturaDeCliente__c(Factura__c = facturaCliente.Id, Cantidad__c = 50, PrecioDeVenta__c = 5);
        items.add(item);

        item = new ItemDeFacturaDeCliente__c(Factura__c = facturaCliente.Id, Cantidad__c = 60, PrecioDeVenta__c = 10);
        items.add(item);

        insert items;



        return proformasSplit;
    }



    public Account createClienteFP() {
        Account cliente;
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId();

        cliente = new Account(RecordTypeId = idRT,
                              Name = 'Cliente - cliente',
                              Estado__c = 'Activo',
                              Codigo_rapido__c = '22233',
                              Codigo_pais2__c = 'ESP',
                              Balance_Cuenta__c = 2,                                
                              Credito_autorizado__c = 5000,
                              RazonSocial__c = 'razonsocial',
                              NroIdFiscal__c = '12345',
                              PorcentajeAportaciones__c = 25,
                              IdQbo__c = '123',
                              PorcentajeConvenio__c = 30,
                              PlazoPago__c = '30',
                              FormaPago__c = 'Transferencia',
                              CurrencyIsoCode = 'USD',
                              EmailComercial__c = 'comercial@mail.com');
        insert cliente;
        return cliente;
    }



    public Account createClienteContacto() {
        Account clienteContacto;
        Account cliente;
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId();
        Id idRTCCont = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('ClienteContacto').getRecordTypeId();

        cliente = new Account(RecordTypeId = idRT,
                              Name = 'Cliente - cliente',
                              Estado__c = 'Activo',
                              Codigo_rapido__c = '22233',
                              Codigo_pais2__c = 'ESP',
                              Balance_Cuenta__c = 2,                                
                              Credito_autorizado__c = 5000,
                              RazonSocial__c = 'razonsocial',
                              NroIdFiscal__c = '12345',
                              PorcentajeAportaciones__c = 25,
                              PorcentajeConvenio__c = 30,
                              PlazoPago__c = '30',
                              IdQbo__c = '123',
                              FormaPago__c = 'Transferencia',
                              CurrencyIsoCode = 'USD',
                              EmailComercial__c = 'comercial@mail.com');
        insert cliente;
        
        clienteContacto = new Account(RecordTypeId = idRTCCont,
                                      Name = 'ClienteContacto - cliente',
                                      ParentId = cliente.Id,
                                      Estado__c = 'Activo',
                                      Codigo_rapido__c = '12233',
                                      Codigo_pais2__c = 'ESP',
                                      Balance_Cuenta__c = 2,                                
                                      Credito_autorizado__c = 5000,
                                      RazonSocial__c = 'razonsocialCC',
                                      NroIdFiscal__c = '1234555',
                                      PorcentajeAportaciones__c = 25,
                                      PorcentajeConvenio__c = 30,
                                      PlazoPago__c = '30',
                                      FormaPago__c = 'Transferencia',
                                      CurrencyIsoCode = 'USD',
                                      EmailComercial__c = 'comercialcc@mail.com');
        insert clienteContacto;
        
        return clienteContacto;
    }


    public FacturaDeCliente__c createFacturaCliente(Account clienteContacto, String estado) {
//        FacturaDeCliente__c facturaCliente = new FacturaDeCliente__c(Estado__c = 'Enviada',
        FacturaDeCliente__c facturaCliente = new FacturaDeCliente__c(Estado__c = estado,
                                                                     FechaDeFactura__c = Date.today(),
                                                                     FechaVencimiento__c = Date.today(),
                                                                     Cliente__c = clienteContacto.Id);
                                                                     
        if(estado.equals('Contabilizada')) {
            facturaCliente.IdQbo__c = '34';
        }
                                                                     
        insert facturaCliente;
        return facturaCliente;
    }
    
    
    public void attachFacturaClienteLineItem(FacturaDeCliente__c facturaCliente) {
        ItemDeFacturaDeCliente__c itemFacturaCliente = new ItemDeFacturaDeCliente__c(Cantidad__c = 1,
                                                                                     Descripcion__c = 'itemfc1',
                                                                                     PrecioDeVenta__c = 1,
                                                                                     Total__c = 1,
                                                                                     Factura__c = facturaCliente.Id);
        insert itemFacturaCliente;
    }

    
    public FacturaDeCliente__c initFacturaCliente(String estado) {
        Account clienteContacto = createClienteContacto();
        //FacturaDeCliente__c facturaCliente = createFacturaCliente(clienteContacto, 'Enviada');
        FacturaDeCliente__c facturaCliente = createFacturaCliente(clienteContacto, estado);
        attachFacturaClienteLineItem(facturaCliente);
        return facturaCliente;
    }
    
    
    
    public Account createProveedor() {
        Account proveedor;
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Proveedor').getRecordTypeId();

        proveedor = new Account(RecordTypeId = idRT,
                                Name = 'Proveedor-1',
                                Estado__c = 'Activo',
                                Codigo_rapido__c = '22233',
                                Codigo_pais2__c = 'ESP',
                                Balance_Cuenta__c = 2,                                
                                Credito_autorizado__c = 5000,
                                RazonSocial__c = 'razonsocialP',
                                NroIdFiscal__c = '1234522',
                                PorcentajeAportaciones__c = 25,
                                PorcentajeConvenio__c = 30,
                                PlazoPago__c = '30',
                                IdQbo__c = '123',
                                FormaPago__c = 'Transferencia',
                                CurrencyIsoCode = 'USD',
                                EmailComercial__c = 'comercialp@mail.com');
        insert proveedor;
        return proveedor;
    }
    

    public FacturaDeProveedor__c createFacturaProveedor(Account proveedor, PedidoDeCompra__c pedido, String estado, String qbsynctoken) {
//        FacturaDeProveedor__c facturaProveedor = new FacturaDeProveedor__c(Estado__c = 'Recibida',
        FacturaDeProveedor__c facturaProveedor = new FacturaDeProveedor__c(Estado__c = estado,
                                                                           Pedido__c = pedido.Id,
                                                                           FechaVencimiento__c = Date.today(),
                                                                           FechaVencimientoActualizada__c = true,
                                                                           QB_SyncToken__c = qbsynctoken,
                                                                           Proveedor__c = proveedor.Id);

        if(estado.equals('Contabilizada')) {
            facturaProveedor.IdQbo__c = '34';
        }

        insert facturaProveedor;
        return facturaProveedor;
    }


    public void attachFacturaProveedorLineItem(FacturaDeProveedor__c facturaProveedor) {
        ItemDeFacturaDeProveedor__c itemFacturaProveedor = new ItemDeFacturaDeProveedor__c(Descripcion__c = 'itemfc1',
                                                                                           Total__c = 1,
                                                                                           Factura__c = facturaProveedor.Id);
        insert itemFacturaProveedor;
    }

    
    public Proforma__c crearProforma(EstudioOportunidad__c eop, Opportunity opp, Account cliente) {
        Proforma__c proforma = new Proforma__c(Name = 'PFPedidos1',
                                               TipoDeContenedor__c = '20 pies',
                                               EstudioOportunidad__c = eop.Id,
                                               Oportunidad__c = opp.Id,
                                               ConfirmacionCliente__c = true,
                                               Cuenta__c = cliente.Id);
        insert proforma;
        return proforma;
    }


    public PedidoDeCompra__c crearPedido(Proforma__c proforma, Account proveedor) {
        PedidoDeCompra__c pedido;

        //Id idRT = Schema.sObjectType.PedidoDeCompra__c.getRecordTypeInfosByDeveloperName().get('Principal').getRecordTypeId();
        
        Id idRT; 
        List<Schema.RecordTypeInfo> listrt = Schema.sObjectType.PedidoDeCompra__c.getRecordTypeInfos();
        for(Schema.RecordTypeInfo srti : listrt) {
            if(srti.getDeveloperName().equals('Principal') && srti.isDefaultRecordTypeMapping() && !srti.isMaster()) {
                idRT = srti.getRecordTypeId();
                break;
            }
        }         

        pedido = new PedidoDeCompra__c(Name = 'PedidoFP',
                                       Proforma__c = proforma.Id,
                                       NumeroDeContenedor__c = '222',
                                       proveedor__c = proveedor.Id,
                                       N_de_Seal__c = '123',
                                       PorcentajeDepositoAFabrica__c = 5,
                                       Numero_de_Factura__c = 'A20/001',
                                       Portal_Token__c = '12345',
                                       Email_Fabrica__c = 'test@test.com',
                                       Numero_de_Factura_Proveedor__c = 'p0001',
                                       RecordTypeId = idRT,
                                       Fecha_Factura__c = Date.today(),
                                       Enviado_libra__c = false,
                                       Aprobado_Envio__c = true,
                                       Fecha_Factura_Proveedor__c = Date.today());
        insert pedido;
        return pedido;
    }


    public FacturaDeProveedor__c initFacturaProveedor(String estado) {
        return initFacturaProveedor(estado, null);
    }
    
    public FacturaDeProveedor__c initFacturaProveedor(String estado, String qbsynctoken) {
        FacturaDeProveedor__c facturaProveedor;
        initEscandallo();
        createAgent('GO SHIPPING');
        Account cliente = createClienteContacto();
        PlanificacionComercial__c planComer = createPlanificacionComercial(cliente);
        Opportunity opp = createOpportunityOriginal(cliente, planComer);
        Account proveedor = createProveedor();
        
        EstudioOportunidad__c eop = createEstudioOportunidad(proveedor, opp);
        Proforma__c proforma = crearProforma(eop, opp, cliente);
        PedidoDeCompra__c pedido = crearPedido(proforma, proveedor);
        
        //facturaProveedor = createFacturaProveedor(proveedor, pedido, 'Recibida');
        facturaProveedor = createFacturaProveedor(proveedor, pedido, estado, qbsynctoken);
        attachFacturaProveedorLineItem(facturaProveedor);
        return facturaProveedor;
    }
    
    
    private void createAgent(String agenteName) {
        Account accAgent;
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agente').getRecordTypeId();

        //Agente Test 1 - agente
        //GO SHIPPING
        accAgent = new Account(RecordTypeId = idRT,
                               Name = agenteName,
                               Estado__c = 'Activo',
                               EmailBanco__c = 'isragut@gmail.com',
                               EmailComercial__c = 'isragut@gmail.com',
                               Email_financiero__c = 'isragut@gmail.com');
             
        insert accAgent;
        
        Agentes__c agenteCS = new Agentes__c();
        agenteCS.Name = 'TstAgente';
        agenteCS.ID_Agente__c = accAgent.Id;
        agenteCS.Predeterminado__c = true;
        insert agenteCS;        
    }
  
    //------------------------------------------------- Test syncup pedido trigger - qb
  
    public Account createClienteContactoNULLIDQBO() {
        Account clienteContacto;
        Account cliente;
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId();
        Id idRTCCont = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('ClienteContacto').getRecordTypeId();

        cliente = new Account(RecordTypeId = idRT,
                              Name = 'Cliente - cliente',
                              Estado__c = 'Activo',
                              Codigo_rapido__c = '22233',
                              Codigo_pais2__c = 'ESP',
                              Balance_Cuenta__c = 2,                                
                              Credito_autorizado__c = 5000,
                              RazonSocial__c = 'razonsocial',
                              NroIdFiscal__c = '12345',
                              PorcentajeAportaciones__c = 25,
                              PorcentajeConvenio__c = 30,
                              PlazoPago__c = '30',
                              FormaPago__c = 'Transferencia',
                              CurrencyIsoCode = 'USD',
                              EmailComercial__c = 'comercial@mail.com');
        insert cliente;
        
        clienteContacto = new Account(RecordTypeId = idRTCCont,
                                      Name = 'ClienteContacto - cliente',
                                      ParentId = cliente.Id,
                                      Estado__c = 'Activo',
                                      Codigo_rapido__c = '12233',
                                      Codigo_pais2__c = 'ESP',
                                      Balance_Cuenta__c = 2,                                
                                      Credito_autorizado__c = 5000,
                                      RazonSocial__c = 'razonsocialCC',
                                      NroIdFiscal__c = '1234555',
                                      PorcentajeAportaciones__c = 25,
                                      PorcentajeConvenio__c = 30,
                                      PlazoPago__c = '30',
                                      FormaPago__c = 'Transferencia',
                                      CurrencyIsoCode = 'USD',
                                      EmailComercial__c = 'comercialcc@mail.com');
        insert clienteContacto;
        
        return clienteContacto;
    }
    
   
    public Account createProveedorNULLIDQBO() {
        Account proveedor;
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Proveedor').getRecordTypeId();

        proveedor = new Account(RecordTypeId = idRT,
                                Name = 'Proveedor-1',
                                Estado__c = 'Activo',
                                Codigo_rapido__c = '22233',
                                Codigo_pais2__c = 'ESP',
                                Balance_Cuenta__c = 2,                                
                                Credito_autorizado__c = 5000,
                                RazonSocial__c = 'razonsocialP',
                                NroIdFiscal__c = '1234522',
                                PorcentajeAportaciones__c = 25,
                                PorcentajeConvenio__c = 30,
                                PlazoPago__c = '30',
                                FormaPago__c = 'Transferencia',
                                CurrencyIsoCode = 'USD',
                                EmailComercial__c = 'comercialp@mail.com');
        insert proveedor;
        return proveedor;
    }
   
   
    public PedidoDeCompra__c initPedidoCallQB() {
        initEscandallo();
        createAgent('GO SHIPPING');
        Account cliente = createClienteContactoNULLIDQBO();
        PlanificacionComercial__c planComer = createPlanificacionComercial(cliente);
        Opportunity opp = createOpportunityOriginal(cliente, planComer);
        Account proveedor = createProveedorNULLIDQBO();
        
        EstudioOportunidad__c eop = createEstudioOportunidad(proveedor, opp);
        Proforma__c proforma = crearProforma(eop, opp, cliente);
        PedidoDeCompra__c pedido = crearPedido(proforma, proveedor);
        
        return pedido;
    }
    
}