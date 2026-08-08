/**
*   This class defines methods to be consumed by Apex Test Classes
*
*
**/
@isTest
public class TestUtil{

    public Pricebook2 customPB;
    public list<Product2> productosBase, prodDeFabrica;
    public Account cliente, fabrica, agente, parent;
    public Account clienteContacto;    
    public PlanificacionComercial__c pc;
    public Aportacion__c aportacion;    
    public Opportunity opp;
    public PedidoDeCompra__c pedidoCompra;
    public Contact contact;

    public List<Product2> prodBaseSplit;
    public List<Product2> prodDeFabricaSplit;
    public Product2 parrilla {set; get;}
    public Product2 parrillaBase {set; get;}
    public Product2 silla;
    public Product2 banco;
    public PedidoDeCompra__c pedido1 {set; get;}
    public PedidoDeCompra__c pedido2;
    public PedidoDeCompra__c pedido3;
    public PedidoDeCompra__c pedido4;
    public PedidoDeCompra__c pedido5;
    public Proforma__c proforma;
    public Document documentImage;
    public Product2 productWithImage;
    public String marcaProductoGarden;
    public String marcaProductoOutdoorSoriana;
    public String familyProductoGarden;

    public void initSoloBase() {
        System.debug('INIT SOLO BS 1');
        setupMarcaValues();
        setupProductFamilyValues();
        initEscandallo();
        System.debug('INIT SOLO BS 2');
        setupPriceBooks();
        System.debug('INIT SOLO BS 3');        
        createProductosBase(2);
        System.debug('INIT SOLO BS 4');        
    }
    
    
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


    public void initTestData(){
        System.debug('INIT TST DATA 1');
        initSoloBase();
        System.debug('INIT TST DATA 2');
        createFabrica();
        System.debug('INIT TST DATA 3');
        ProductTriggerHelper.resetRunForTesting(); //Necesito insertar los Productos de Fabrica en un contexto nuevo
        System.debug('INIT TST DATA 4');
        createProductosDeFabrica(productosBase);
        System.debug('INIT TST DATA 5');       
    }

    public void initOpportunityTest(){
        System.debug('INIT OPP TST 1');
        initTestData();
        System.debug('INIT OPP TST 2');
        agente = createAgent('Agente Test 1');
        System.debug('INIT OPP TST 3');
        createCliente();
        System.debug('INIT OPP TST 4');        
        cliente = createClienteContacto(cliente.Id);
        System.debug('INIT OPP TST 5');        
        createContactCliente();
        System.debug('INIT OPP TST 6');           
        createPlanificacionComercial(clienteContacto);
        System.debug('INIT OPP TST 7');
        createOpportunity(clienteContacto, pc);
        System.debug('INIT OPP TST 8');        
        createOpportunityLineItems(opp, customPB);
        System.debug('INIT OPP TST 9');        
    }

    public void initProformaTest(){
        createCustomSettings();
        initOpportunityTest();
        createProforma(true);
    }

    public void initProformaTest(String proformaName){
        createCustomSettings();
        initOpportunityTest();
        createProforma(true, proformaName);
    }

    public void initAprobacionCrediticia()
    {
       EstudioOportunidad__c eo;
       createCustomSettings();
       initEscandallo();
       setupPriceBooks();
       createProductosBaseSplit();
       createFabrica();
       agente = createAgent('Agente Test 1');       
       createCliente();
       cliente = createClienteContacto(cliente.Id);       
       createProductosFabricaSplit();
       createPlanificacionComercial(cliente);
       createOpportunityOriginal(cliente, pc);
       eo = createEstudioOportunidadSplit(fabrica, opp);
       createProformasSplit(cliente, eo, opp);
       //get proforma pedido
       createPedidoLineItemsSplit();
    }

    public void initOpportunitySplit()
    {
       EstudioOportunidad__c eo;
       createCustomSettings();
       setupMarcaValues();
       setupProductFamilyValues();
       initEscandallo();
       setupPriceBooks();
       createProductosBaseSplit();
       createFabrica();
       agente = createAgent('Agente Test 1');
       createCliente();
       cliente = createClienteContacto(cliente.Id);
       createProductosFabricaSplit();
       createPlanificacionComercial(cliente);
       createOpportunityOriginal(cliente, pc);
       eo = createEstudioOportunidadSplit(fabrica, opp);
       createProformasSplit(cliente, eo, opp);
       createPedidoLineItemsSplit();
       createOpportunityLineItemsSplit(opp, customPB, eo);
    }


    public void initOpportunitySplitTr() {
       System.debug('Init Opp Split TR');
       EstudioOportunidad__c eo;
       createCustomSettings();
       setupMarcaValues();
       setupProductFamilyValues();
       initEscandallo();
       setupPriceBooks();
       createProductosBaseSplit();
       createFabrica();
       agente = createAgent('Agente Test 1');
       createCliente();
       cliente = createClienteContacto(cliente.Id);
       createProductosFabricaSplit();
       createPlanificacionComercial(cliente);
       createOpportunityOriginalFlagFalse(cliente, pc);
       eo = createEstudioOportunidadSplit(fabrica, opp);
       createProformasSplitTR(cliente, eo, opp);
       createPedidoLineItemsSplit();
       createOpportunityLineItemsSplit(opp, customPB, eo);
       
       List<OpportunityLineItem> listOLI;
        
       listOLI = [SELECT Id, 
                         Name,
                         OpportunityId,
                         Product2Id,
                         Quantity 
                    FROM OpportunityLineItem 
                   WHERE OpportunityId = :opp.Id];


       for(OpportunityLineItem olil : listOLI) {
           System.debug('TestUtil - initOpportunitySplitTr - prod[' + olil.Product2Id + ']');
       }
       
    }


    public void initOpportunityPedido() {
        initOpportunityPedido(Date.today().year());
    }

    public void initOpportunityPedido(Integer year) {
       EstudioOportunidad__c eo;
       createCustomSettings();
       setupMarcaValues();
       setupProductFamilyValues();
       initEscandallo();
       setupPriceBooks();
       createProductosBaseSplit();
       createFabrica();
       agente = createAgent('Agente Test 1');
       createCliente();
       cliente = createClienteContacto(cliente.Id);       
       createProductosFabricaSplit();
       createPlanificacionComercial(cliente, year);
       createOpportunityOriginal(cliente, pc, year);
       eo = createEstudioOportunidadSplit(fabrica, opp);
       createProformasSplit(cliente, eo, opp);
       createPedidoLineItemsSplit();
       createOpportunityLineItemsPedido(opp, customPB, eo);
    }
    
    public void initSoloBaseCustom(){
        System.debug('Init SOLO BASE - 1');
        initEscandallo();
        setupMarcaValues();
        setupProductFamilyValues();
        System.debug('Init SOLO BASE - 2');
        setupPriceBooks();
        System.debug('Init SOLO BASE - 3');
        createProductosBaseCustom(10);
        System.debug('Init SOLO BASE - 4');
    }

    public void initOpportunityPurchaseInvoiceTest(){
        initTestData();
        createCliente();
        createPlanificacionComercial(cliente);
        createOpportunity(cliente, pc);
    }

    public void initOpportunityTestTotalPrice(){
        initTestData();
        createCliente();
        createPlanificacionComercial(cliente);
        createOpportunity(cliente, pc);
        createOpportunityLineItemsTotalPrice(opp, customPB);
    }

    public void initPedidoAgente() {
        createCustomSettings();
        pedidoCompra = createPedidoDeCompraAgente('Pedido Fábrica', 'Confirmación Proveedor', 'PDF');
    }

    public void initPedidoAgenteTask() {
        createCustomSettings();
        pedidoCompra = createPedidoDeCompraAgente('Pedido Fábrica', 'Confirmación Proveedor', 'Task');
    }

    public void initPedidoFacturas() 
    {
        createCustomSettings();
        pedidoCompra = createPedidoDeCompraAgente(' Producción', 'Informe Carga de Contenedor', 'PDF');
    }

    public void initPedidoReporte()
    {
        Account cliente;
        initTestData();
        agente = createAgent('Agente Test 1');
        createCliente();
        cliente = createClienteContacto();
        createContact();
        createPlanificacionComercial(cliente);
        createOpportunity(cliente, pc);
    }

    public void initCliente() {
        initTestData();
        createCustomSettings();        
        agente = createAgent('Agente Test 1');
        cliente = createCliente();
    }

    public void initPedidoPurchaseInvoice() {
        Account cliente;
        agente = createAgent('Agente Test 1');
        createCliente();        
        clienteContacto = createClienteContacto();
        createContact();
        pedidoCompra = createPedidoDeCompraPurchase('v');
    }

    public void initPedidoReporteAportacion()
    {
        Account cliente;
        createCustomSettings();    
        initTestData();
        agente = createAgent('Agente Test 1');
        createCliente();
        cliente = createClienteContacto();
        createContact();
        createPlanificacionComercial(cliente);
        createOpportunity(cliente, pc);
        createAportacion();
    }

    public void createCustomSettings()
    {
        Account agentePrederminado;
        agentePrederminado = createAgent('GO SHIPPING');

        Incremento_CS__c increaseCS = new Incremento_CS__c();
        increaseCS.Name = 'proforma';
        increaseCS.prefix__c = 'PR';
        increaseCS.year__c = 2018;
        increaseCS.consecutive__c = 1;
        
        insert increaseCS;
        
        increaseCS = new Incremento_CS__c();
        increaseCS.Name = 'pedido';
        increaseCS.prefix__c = 'PD';
        increaseCS.year__c = 2018;
        increaseCS.consecutive__c = 1;
        
        insert increaseCS;

        increaseCS = new Incremento_CS__c();
        increaseCS.Name = 'aportacion';
        increaseCS.prefix__c = 'A';
        increaseCS.year__c = 19;
        increaseCS.consecutive__c = 1;
        
        insert increaseCS;

        increaseCS = new Incremento_CS__c();
        increaseCS.Name = 'clienteLibra';
        increaseCS.prefix__c = 'A';
        increaseCS.year__c = 19;
        increaseCS.consecutive__c = 1;
        
        insert increaseCS;

        increaseCS = new Incremento_CS__c();
        increaseCS.Name = 'proveedorLibra';
        increaseCS.prefix__c = 'A';
        increaseCS.year__c = 19;
        increaseCS.consecutive__c = 1;
        
        insert increaseCS;

        increaseCS = new Incremento_CS__c();
        increaseCS.Name = 'facturaDoAmerica';
        increaseCS.prefix__c = 'A';
        increaseCS.year__c = 19;
        increaseCS.consecutive__c = 1;
        
        insert increaseCS;

        increaseCS = new Incremento_CS__c();
        increaseCS.Name = 'facturaDoCore';
        increaseCS.prefix__c = 'A';
        increaseCS.year__c = 19;
        increaseCS.consecutive__c = 1;
        
        insert increaseCS;

        increaseCS = new Incremento_CS__c();
        increaseCS.Name = 'facturaDoAmericaCancel';
        increaseCS.prefix__c = 'A';
        increaseCS.year__c = 19;
        increaseCS.consecutive__c = 1;
        
        insert increaseCS;

        increaseCS = new Incremento_CS__c();
        increaseCS.Name = 'facturaDoCoreCancel';
        increaseCS.prefix__c = 'A';
        increaseCS.year__c = 19;
        increaseCS.consecutive__c = 1;
        
        insert increaseCS;


        Solicitud_Transferencia_Intervalo__c sti = new Solicitud_Transferencia_Intervalo__c();
        sti.Name = 'intervalo';
        sti.activo__c = true;
        sti.meses_atras__c = 7;
        
        insert sti;

        Envio_Correos__c ecCS = new Envio_Correos__c();
        ecCS.Name = 'ordenes';
        ecCS.flujo__c = 'pedidosConfirmados';        
        ecCS.correo_electronico__c = 'isragut@gmail.com';
        insert ecCS;

        ecCS = new Envio_Correos__c();
        ecCS.Name = 'documentosFaltantes';
        ecCS.flujo__c = 'pedidosConfirmados';        
        ecCS.correo_electronico__c = 'isragut@gmail.com';
        insert ecCS;


        ecCS = new Envio_Correos__c();
        ecCS.Name = 'aportacion';
        ecCS.flujo__c = 'aportacion';
        ecCS.correo_electronico__c = 'isragut@gmail.com';
        insert ecCS;

        ecCS = new Envio_Correos__c();
        ecCS.Name = 'aprobacionfactuno';
        ecCS.flujo__c = 'aprobacionFacturas';
        ecCS.correo_electronico__c = 'isragut@gmail.com';
        insert ecCS;

        Libra_Cobros_Pagos__c libraCPcobros = new Libra_Cobros_Pagos__c();
        libraCPcobros.Name = 'CobrosDoCore';
        libraCPcobros.Sociedad__c = '200';
        libraCPcobros.Fecha_Callout_Exitosa__c = Datetime.now();
        insert libraCPcobros;

        Libra_Cobros_Pagos__c libraCPcobrosDA = new Libra_Cobros_Pagos__c();
        libraCPcobrosDA.Name = 'CobrosDoAmerica';
        libraCPcobrosDA.Sociedad__c = '400';
        libraCPcobrosDA.Fecha_Callout_Exitosa__c = Datetime.now();
        insert libraCPcobrosDA;

        Libra_Cobros_Pagos__c libraCPpagos = new Libra_Cobros_Pagos__c();
        libraCPpagos.Name = 'PagosDoCore';
        libraCPpagos.Sociedad__c = '200';
        libraCPpagos.Fecha_Callout_Exitosa__c = Datetime.now();
        insert libraCPpagos;

        Libra_Cobros_Pagos__c libraCPpagosDA = new Libra_Cobros_Pagos__c();
        libraCPpagosDA.Name = 'PagosDoAmerica';
        libraCPpagosDA.Sociedad__c = '400';
        libraCPpagosDA.Fecha_Callout_Exitosa__c = Datetime.now();
        insert libraCPpagosDA;

        Agentes__c agenteCS = new Agentes__c();
        agenteCS.Name = 'TstAgente';
        agenteCS.ID_Agente__c = agentePrederminado.Id;
        agenteCS.Predeterminado__c = true;
        insert agenteCS;

       LibraWS__c libraWSCobros = new LibraWS__c();
       libraWSCobros.Name = 'produccionCobros';
       libraWSCobros.endpoint__c = 'http://127.0.0.1';
       libraWSCobros.param_alias__c = 'SFORCE_FACTURAS_VENTA';
       libraWSCobros.param_id_user__c = 'EDISA';
       libraWSCobros.param_pwd__c = 'EDISA';
        
       insert libraWSCobros;

       LibraWS__c libraWSPagos = new LibraWS__c();
       libraWSPagos.Name = 'produccionPagos';
       libraWSPagos.endpoint__c = 'http://127.0.0.1';
       libraWSPagos.param_alias__c = 'SFORCE_FACTURAS_VENTA';
       libraWSPagos.param_id_user__c = 'EDISA';
       libraWSPagos.param_pwd__c = 'EDISA';
        
       insert libraWSPagos;

        LibraWS__c libraWSCS = new LibraWS__c();
        libraWSCS.Name = 'produccionClientes';
        libraWSCS.endpoint__c = 'http://127.0.0.1';
        libraWSCS.param_alias__c = 'SF_CLIENTE';
        libraWSCS.param_id_user__c = 'EDISA';
        libraWSCS.param_pwd__c = 'EDISA';
        
        insert libraWSCS;

        LibraWS__c libraWSAP = new LibraWS__c();
        libraWSAP.Name = 'produccionProveedores';
        libraWSAP.endpoint__c = 'http://127.0.0.1';
        libraWSAP.param_alias__c = 'SF_CLIENTE';
        libraWSAP.param_id_user__c = 'EDISA';
        libraWSAP.param_pwd__c = 'EDISA';
        
        insert libraWSAP;


        LibraWS__c libraWSCFC = new LibraWS__c();
        libraWSCFC.Name = 'produccionFacturaCompra';
        libraWSCFC.endpoint__c = 'http://127.0.0.1';
        libraWSCFC.param_alias__c = 'SF_CLIENTE';
        libraWSCFC.param_id_user__c = 'EDISA';
        libraWSCFC.param_pwd__c = 'EDISA';
        
        insert libraWSCFC; 

        LibraWS__c libraWSCFV = new LibraWS__c();
        libraWSCFV.Name = 'produccionFacturaVenta';
        libraWSCFV.endpoint__c = 'http://127.0.0.1';
        libraWSCFV.param_alias__c = 'SF_CLIENTE';
        libraWSCFV.param_id_user__c = 'EDISA';
        libraWSCFV.param_pwd__c = 'EDISA';
        
        insert libraWSCFV; 

        LibraWS__c libraWSAPR = new LibraWS__c();
        libraWSAPR.Name = 'produccionProductos';
        libraWSAPR.endpoint__c = 'http://127.0.0.1';
        libraWSAPR.param_alias__c = 'SF_CLIENTE';
        libraWSAPR.param_id_user__c = 'EDISA';
        libraWSAPR.param_pwd__c = 'EDISA';
        
        insert libraWSAPR; 

        Portal_DO_Brands__c portalDBCS = new Portal_DO_Brands__c();
        portalDBCS.Name = 'Desarrollo';
        portalDBCS.URL_Portal__c = 'test.com';

        insert portalDBCS;

    }

    public User createUser(String profileName) {
        //Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName];
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Administrador del sistema' OR Name = 'System administrator'];

        String uniqueUserName = 'mytestUser' + DateTime.now().getTime() + '@testorg.com';

        User newUser = new User (Alias = 'standt', 
                           Email='mytestuser@testorg.com',
                           EmailEncodingKey='UTF-8', 
                           LastName='Testing', 
                           LanguageLocaleKey='en_US',
                           LocaleSidKey='en_US', 
                           ProfileId = profile.Id,
                           TimeZoneSidKey='America/Los_Angeles',
                           UserName = uniqueUserName);
        insert newUser;
        return newUser;
    }
    
    
    public Account createFabrica(){
        return createFabrica('Chino', 'A');
    }

    private Account createFabrica(String name, String cat){
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Proveedor').getRecordTypeId();

        fabrica = new Account(RecordTypeId = idRT,
                                Name = name,
                                Type = 'Fábrica',
                                Estado__c = 'Activo',
                                Codigo_pais2__c = 'ESP',
                                RazonSocial__c = '9987987Y',
                                NroIdFiscal__c = 'ABC1234',
                                Rating = cat,
                                PaisDelPuerto__c = 'China',
                                EmailComercial__c = 'delivery@infolastic.com',
                                Portal_Token__c = '12345',
                                Portal_Token_Verificacion__c = '12345',                                
                                Puerto__c = 'QINGDAO, CHINA',
                                PlazoPago__c = '30',
                                PorcentajeDeposito__c = '10',
                                Registrar_Libra__c = true,
                                Codigo_rapido__c = '12345',
                                IdQbo__c = '12',
                                Plazo_Precios_Proveedor__c = '15',
                                TiempoServicioMedio__c = '15');
        insert fabrica;
        return fabrica;
    }


    public PackingList__c createPackingList(String idOrder) {
        PackingList__c PL = new PackingList__c(Name = 'testPL', 
                                               Estado__c = 'Aprobado',
                                               Pedido__c = idOrder);
        insert PL;
        return PL;
    }

    public Account createCliente(){
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Cliente').getRecordTypeId();                                    

        cliente = new Account(RecordTypeId = idRT,
                                Name = 'Cliente - cliente',
                                BillingCountry = 'USA',
                                BillingStreet = 'street one street one street one street one street one',
                                Estado__c = 'Activo',
                                Codigo_rapido__c = '22233',
                                Codigo_pais2__c = 'ESP',
                                Balance_Cuenta__c = 2,                                
                                Credito_autorizado__c = 5000,
                                RazonSocial__c = 'razonsocial',
                                IdQbo__c = '123',
                                NroIdFiscal__c = '12345',
                                PorcentajeAportaciones__c = 25,
                                PorcentajeConvenio__c = 30,
                                PlazoPago__c = '30',
                                FormaPago__c = 'Transferencia',
                                Sociedad__c = 'Do América',
                                CurrencyIsoCode = 'USD',
                                Alta_Libra__c = false,
                                Registrar_Libra__c = true,
                                EmailComercial__c = 'comercial@mail.com',
                                Agente_Cliente__c = agente.Id);
        insert cliente;


        return cliente;
    }


    private Account createClienteContacto(){
        return createClienteContacto(null);
    }


    public Account createClienteContacto(Id parentId) {
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('ClienteContacto').getRecordTypeId();

        clienteContacto = new Account(RecordTypeId = idRT,
                                Name = 'ClienteContactoUno - cliente',
                                Estado__c = 'Activo',
                                CurrencyIsoCode = 'USD',
                                PorcentajeAportaciones__c = 25,
                                EmailComercial__c = 'test@test.com',
                                PorcentajeConvenio__c = 30,
                                PlazoPago__c = '30',
                                BillingCountry = 'China',
                                Portal_Token__c = '123',
                                Portal_Token_Verificacion__c = '123',                                
                                Id_Externo__c = 'CE-01',
                                Codigo_rapido__c = '00007',
                                Codigo_pais2__c = 'ESP',
                                RazonSocial__c = 'ABCD',
                                NroIdFiscal__c = '1234567',
                                Alta_Libra__c = false,
                                Registrar_Libra__c = true,
                                IdQbo__c = '123',
                                Sociedad__c = 'Do América',
                                PaisDelPuerto__c = 'Mexico',
                                Puerto__c = 'GUADALAJARA, MEXICO');
        if(parentId != null){
            clienteContacto.ParentId = parentId;
        } else {
            clienteContacto.ParentId = cliente.Id;
        }

        insert clienteContacto;
        return clienteContacto;
    }

    private void createContact()
    {
        contact = new Contact(FirstName = 'contactOne',
                              LastName = 'last',
                              AccountId = clienteContacto.Id);
        insert contact;
    }

  
    private void createContactCliente()
    {
        contact = new Contact(FirstName = 'contactOne',
                              LastName = 'last',
                              Email = 'test@test.com',
                              AccountId = cliente.Id);
        insert contact;
    }    

    private Account createAgent(String agenteName) 
    {
        Account accAgent;
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agente').getRecordTypeId();

        //Agente Test 1 - agente
        accAgent = new Account(RecordTypeId = idRT,
                                Name = agenteName,
                                Estado__c = 'Activo',
                                EmailBanco__c = 'isragut@gmail.com',
                                IdQbo__c = '123',
                                EmailComercial__c = 'isragut@gmail.com',
                                Email_financiero__c = 'isragut@gmail.com');
             
        insert accAgent;
        return accAgent;
    }

    public void createPlanificacionComercial(Account cliente){
        createPlanificacionComercial(cliente, Date.today().year());
    }

    public void createPlanificacionComercial(Account cliente, Integer year) {
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
    }

    private void createAportacion()
    {
        aportacion = new Aportacion__c(PlanificacionComercial__c = pc.Id,
                                       Fecha__c = Date.today(),
                                       Importe__c = 0,
                                       Descripcion__c = 'Desc');
        insert aportacion;

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        Blob b=Blob.valueOf('This is version data');
        cv.VersionData = b;
        cv.Title = 'text.txt';
        cv.PathOnClient = 'test.txt';
        insert cv;

        
        ContentVersion cvi = [SELECT id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id limit 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cvi.ContentDocumentId;
        cdl.LinkedEntityId = aportacion.Id;
        cdl.ShareType = 'I';
        insert cdl;


    }

    public void createOpportunity(Account cliente, PlanificacionComercial__c pc) {
        User owner;
    
        owner = createUser('Administrador del sistema');
        System.debug('TEST UTIL createOpportunity [' + owner.Id + '] [' + owner.UserName + '] [' + owner.Email + ']');
    
        opp = new Opportunity(Name = 'Test Opportunity',
                              OwnerId = owner.Id,
                                AccountId = cliente.Id,
                                Is_Brand_Selected__c = true,
                                PlanificacionComercial__c = pc.Id,
                                CloseDate = Date.today(),
                                StageName = 'Toma de Contacto',
                                Campana__c = 'Back to School',
                                Fecha_de_Compromiso__c = Date.today());
        insert opp;
    }

    public void createOpportunityLineItems(Opportunity opp, Pricebook2 pb){
        list<OpportunityLineItem> loli = new list<OpportunityLineItem>();
        for(PricebookEntry pbe : [SELECT Id,
                                        UnitPrice
                                        FROM PricebookEntry
                                        WHERE Pricebook2Id = :pb.Id]){

            loli.add(new OpportunityLineItem(OpportunityId = opp.Id,
                                            PricebookEntryId = pbe.Id,
                                            //UnitPrice = pbe.UnitPrice,
                                            UnitPrice = 100,
                                            Porcentaje_Item__c = 5,
                                            Quantity = 1));
        }
        insert loli;

    }

    private void createOpportunityLineItemsTotalPrice(Opportunity opp, Pricebook2 pb){
        list<OpportunityLineItem> loli = new list<OpportunityLineItem>();
        for(PricebookEntry pbe : [SELECT Id,
                                        UnitPrice
                                        FROM PricebookEntry
                                        WHERE Pricebook2Id = :pb.Id]){

            loli.add(new OpportunityLineItem(OpportunityId = opp.Id,
                                            PricebookEntryId = pbe.Id,
                                            TotalPrice = 3,
                                            Porcentaje_Item__c = 5,
                                            Quantity = 1));
        }
        insert loli;

    }


    public void CreateDocumentImage() {
        documentImage = new Document();
        documentImage.Body = Blob.valueOf('Some Text');
        documentImage.ContentType = 'image/jpg';
        documentImage.DeveloperName = 'test';
        documentImage.IsPublic = true;
        documentImage.Name = 'TestImg';
        documentImage.FolderId = [SELECT Id FROM Folder WHERE Name = 'Imagenes de Productos'].Id;
        insert documentImage;
        
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


    public void createProductoBaseImage() { 
        Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
        CreateDocumentImage();
        Document docImage = getDocumentImage();

        productWithImage = new Product2(Name = 'imgProdBase',
                                        RecordTypeId = idRT,
                                        image_uploaded_s3__c = False,
                                        ProductCode = 'A11111111',
                                        M3Unidad__c = 0.5,
                                        UnidadesPorMasterBox__c = 2,
                                        UnidadesHQ__c = 1000,
                                        UnidadesContainer20__c = 400,
                                        isActive = false,
                                        MasterboxAltoCm__c = '10',
                                        MasterboxAnchoCm__c = '10',
                                        MasterboxLargoCm__c = '10',
                                        MasterboxM3__c = 1,
                                        Family = familyProductoGarden,
                                        Subfamilia__c = '2-Outdoor Shades & Structures',
										Clase__c = '03-Awnings',
                                        Marca__c = marcaProductoGarden,
                                        IDImagen1__c = docImage.Id,
                                        Packaging__c = '1-BROWN BOX',
                                        Listado_en_Catalogo__c = false);
        insert productWithImage;
    }



    private void createProductosBase(Integer nmb){ 
        Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();

        productosBase = new list<Product2>();

        for(Integer i = 0; i < nmb; i++){
            productosBase.add(new Product2(Name = i == 0 ? 'Large' : 'Test Producto ' + String.valueOf(i),
                                        RecordTypeId = idRT,
                                        M3Unidad__c = 0.5,
                                        UnidadesPorMasterBox__c = 2,
                                        UnidadesHQ__c = 1000,
                                        UnidadesContainer20__c = 400,
                                        isActive = false,
                                        MasterboxAltoCm__c = i == 0 ? '100' : '10',
                                        MasterboxAnchoCm__c = i == 0 ? '100' : '10',
                                        MasterboxLargoCm__c = i == 0 ? '100' : '10',
                                        MasterboxM3__c = i == 0 ? 1 : 0.001,
                                        Family = familyProductoGarden,
                                        Subfamilia__c = '2-Outdoor Shades & Structures',
										Clase__c = '03-Awnings',
                                        Marca__c = marcaProductoGarden,
                                        Packaging__c = i == 0 ? '1-BROWN BOX' : '9-COLOR BOX',
                                        Listado_en_Catalogo__c = false));
        }
        insert productosBase;
    }
    
    private void createProductosDeFabrica(list<Product2> bases){
        Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('ProductoDeFabrica').getRecordTypeId();

        prodDeFabrica = new list<Product2>();
        for(Product2 p : bases){
            prodDeFabrica.add(new Product2(Name = p.Name,
                                        RecordTypeId = idRT, 
                                        ProductoBase__c = p.Id, 
                                        Packaging__c = '1-BROWN BOX',
                                        Fabrica__c = fabrica.Id,
                                        PlazoDeFabricacion__c = '45-60 días',
                                        MOQ__c = 1000,
                                        PrecioDeFabrica__c = 20,
                                        CostoPackaging__c = 4,
                                        isActive = true));
        }
        insert prodDeFabrica;
    }

    /**
    *   Creates an alternative Factory and Products for the base Products.
    *   If matchAll is set to false, it creates all but 1 alternative products.
    */
    public void createAltProdDeFabrica(boolean matchAll){
        
        Account alt = createFabrica('Alternative', 'B');
        Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('ProductoDeFabrica').getRecordTypeId();

        prodDeFabrica = new list<Product2>();
        for(Product2 p : productosBase){
            prodDeFabrica.add(new Product2(Name = p.Name,
                                        RecordTypeId = idRT, 
                                        ProductoBase__c = p.Id, 
                                        Packaging__c = '1-BROWN BOX',
                                        Fabrica__c = alt.Id,
                                        PlazoDeFabricacion__c = '45-60 días',
                                        MOQ__c = 1000,
                                        PrecioDeFabrica__c = 20,
                                        CostoPackaging__c = 4,
                                        isActive = true));
        }
        if(!matchAll){
            prodDeFabrica.remove(0);
        }
        insert prodDeFabrica;
    }

    /**
    *   Fija el margen para la lista de precios estandar en 20%. Crea la lista de precios preferencial y fija el margen en 10%.
    */
    private void setupPriceBooks(){
            Pricebook2 stdPricebook = new Pricebook2(ID = Test.getStandardPricebookId(),
                                                isActive=true, 
                                                Margen__c = 20);
            update stdPricebook;
            // Crea la pricebook Preferencial
            customPB = new Pricebook2(Name='Key Account', 
                                                isActive=true, 
                                                Margen__c = 10);
            insert customPB;
            
            List<Pricebook2> pbooks2 = [SELECT Id, Name, Margen__c, IsActive, IsStandard FROM Pricebook2];
            System.debug('Configured pricebooks');
            for(Pricebook2 pb : pbooks2) {
                System.debug('Test Util - setupPricebook - [' + pb.Id + '] [' + pb.Name + '] [' + pb.Margen__c + '] [' + pb.IsActive + '] [' + pb.IsStandard + ']');
            }
    }

    public PedidoDeCompra__c createPedidoDeCompra(String vol) {
        Documento__c documentoBL;
        Documento__c documentoF;
        Documento__c documentoPL;
        String idD;
        
        Account proveedor = createFabrica('tstFab', 'cat');
        
        PedidoDeCompra__c c = new PedidoDeCompra__c(Proforma__c = proforma.Id, 
                                                    Email_Facturacion_Cliente__c = 'test@test.com',
                                                    Proveedor__c = proveedor.Id);
        c.Estado2__c = 'PACKAGING';
        insert c;

        documentoBL = new Documento__c();
        documentoBL.Proceso__c = 'Pedido Fábrica';
        documentoBL.Tipo_de_Documento__c = 'BL';
        documentoBL.PedidoDeCompra__c = c.id;
        insert documentoBL;

        idD = documentoBL.Id;
        
        ContentVersion cv1 = new ContentVersion();
        cv1.ContentLocation = 'S';
        Blob b1 = Blob.valueOf('This is version data');
        cv1.VersionData = b1;
        cv1.Title = 'test1.txt';
        cv1.PathOnClient = 'test1.txt';
        insert cv1;

        List<ContentDocument> lcd3 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdl1 = new ContentDocumentLink();
        cdl1.ContentDocumentId = lcd3.get(0).Id;
        cdl1.LinkedEntityId = documentoBL.Id;
        cdl1.ShareType = 'I';
        insert cdl1;


        documentoBL.Archivo_Principal__c = lcd3.get(0).Id;
        update documentoBL;

        return c;
    }

    public PedidoDeCompra__c createPedidoDeCompraStatus(String statusPedido) {

        Account proveedor = createFabrica('tstFab', 'cat');
        
        PedidoDeCompra__c pedido = new PedidoDeCompra__c(Proforma__c = proforma.Id, Email_Facturacion_Cliente__c = 'test@test.com', Proveedor__c = proveedor.Id);
        pedido.Estado2__c = statusPedido;
        insert pedido;

        return pedido;
    }

    public void createDocumentPedido(String orderId, String tipoDocumento, String proceso) {
        Documento__c documentoBL;
        Documento__c documentoF;
        Documento__c documentoPL;

        documentoBL = new Documento__c();
        documentoBL.Proceso__c = proceso;
        documentoBL.Tipo_de_Documento__c = tipoDocumento;
        documentoBL.PedidoDeCompra__c = orderId;
        insert documentoBL;

        ContentVersion cv1 = new ContentVersion();
        cv1.ContentLocation = 'S';
        Blob b1 = Blob.valueOf('This is version data');
        cv1.VersionData = b1;
        cv1.Title = 'test1.txt';
        cv1.PathOnClient = 'test1.txt';
        insert cv1;

        List<ContentDocument> lcd3 = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink cdl1 = new ContentDocumentLink();
        cdl1.ContentDocumentId = lcd3.get(0).Id;
        cdl1.LinkedEntityId = documentoBL.Id;
        cdl1.ShareType = 'I';
        insert cdl1;

        documentoBL.Archivo_Principal__c = lcd3.get(0).Id;
        update documentoBL;
    }


    public PedidoDeCompra__c createPedidoDeCompraPurchase(String vol)
    {
        Proforma__c  prof = getProforma();

        prof.Cuenta__c = clienteContacto.Id;

        update prof;

        Account proveedor = createFabrica('tstFab', 'cat');

        PedidoDeCompra__c c = new PedidoDeCompra__c(Proforma__c = prof.Id, Proveedor__c = proveedor.Id);
        insert c;
        return c;
    }

    public PedidoDeCompra__c createPedidoDeCompraAgente(String docProceso, String docTipoDoc, String typeBatch) 
    {
        Documento__c documento;
        Account proveedor;
        Proforma__c pf = createAndFetchProforma();
        PedidoDeCompra__c c;

        proveedor = createFabrica('DingDong', 'A');
        
        System.debug(' ******************* createPedidoDeCompraAgente *****************************');
        System.debug(' ******************* pf cuenta[' + pf.Cuenta__c + ']');
        System.debug(' ******************* pf cuenta ETD[' + pf.ETD__c + ']');        
        System.debug(' ******************* pf cuenta-parent[' + pf.Cuenta__r.Parent + ']');        
        System.debug(' ******************* pf [' + pf.Cuenta__r.Parent.Agente_Cliente__c + ']');

        if(typeBatch.equals('PDF')) {
            c = new PedidoDeCompra__c(Proforma__c = pf.Id,
                                      Booking_Agente__c = agente.Id,
                                      N_de_Seal__c = 'ABC012',
                                      NumeroDeContenedor__c = 'NC001',
                                      Cuenta_Agente_DO__c = agente.Id,
                                      Enviado_libra__c = false,
                                      Aprobado_Envio__c = false,
                                      Proveedor__c = proveedor.Id,
                                      Numero_de_Orden__c = 'POT',
                                      Puerto_de_destino__c = 'LIMA, PERU',
                                      Puerto_de_origen__c = 'DALIAN, CHINA',
                                      //ImporteVentaNeto__c = 10,
                                      //CostoTotal__c = 20,
                                      //Precio_Total__c = 25,
                                      Enviar_solicitud_booking__c = true,
                                      Solicitud_booking_enviada__c = false,
                                      Aprobada_Transferencia_Deposito__c = true,
                                      Aprobada_Transferencia_Balance__c = false,
                                      Correo_pago_balance__c = false,
                                      Correo_Pago_Deposito__c = true,
                                      ETD__c = Date.today(),
                                      Fecha_Minima_Embarque__c = Date.today(),
                                      Fecha_Maxima_Embarque__c = Date.today(),
                                      FechaConfirmacionCliente__c = Date.today(),
                                      Fecha_fin_de_Produccion__c = Date.today());
        }

        if(typeBatch.equals('Task')) {
            c = new PedidoDeCompra__c(Proforma__c = pf.Id,
                                      Booking_Agente__c = agente.Id,
                                      N_de_Seal__c = 'ABC012',
                                      NumeroDeContenedor__c = 'NC001',
                                      Numero_de_Orden__c = 'POT',                                      
                                      Cuenta_Agente_DO__c = agente.Id,
                                      Enviado_libra__c = false,
                                      Aprobado_Envio__c = false,
                                      Proveedor__c = proveedor.Id,
                                      //ImporteVentaNeto__c = 10,
                                      //CostoTotal__c = 20,
                                      //Precio_Total__c = 25,
                                      Enviar_solicitud_booking__c = false,
                                      Solicitud_booking_enviada__c = false,
                                      Aprobada_Transferencia_Deposito__c = true,
                                      Aprobada_Transferencia_Balance__c = true,
                                      Correo_pago_balance__c = false,
                                      Correo_Pago_Deposito__c = true,
                                      Fecha_Minima_Embarque__c = Date.today(),
                                      Fecha_Maxima_Embarque__c = Date.today(),
                                      FechaConfirmacionCliente__c = Date.today(),
                                      Fecha_fin_de_Produccion__c = Date.today());

        }

        try {

        insert c;

        System.debug('PEDIDOCOMPRA prfid[' + c.Proforma__c + '] [' + c.Proforma__r.ETD__c + '] [' + c.Fecha_de_Compromiso_con_el_Cliente__c + ']');

        documento = new Documento__c();
        //documento.Proceso__c = 'Pedido Fábrica';
        documento.Proceso__c = docProceso;
        //documento.Tipo_de_Documento__c = 'Confirmación Proveedor';
        documento.Tipo_de_Documento__c = docTipoDoc;
        documento.PedidoDeCompra__c = c.id;

        insert documento;


        }
        catch(DmlException e)
        {
           System.debug('An unexpected error has occurred: ' + e.getMessage());
        }

        PedidoDeCompra__c pedidoc = [SELECT Id, N_de_Seal__c, Booking_Agente__c, Estado2__c, FechaConfirmacionCliente__c, 
                                           Proforma__r.Cuenta__r.PorcentajeAportaciones__c, 
                                           Fecha_de_Compromiso_con_el_Cliente__c,
                                           Proforma__r.Cuenta__r.ParentId FROM PedidoDeCompra__c WHERE N_de_Seal__c = 'ABC012'];
        

        Documento__c d = [SELECT Id, Name, Proceso__c, Tipo_de_Documento__c, PedidoDeCompra__c FROM Documento__c WHERE PedidoDeCompra__c = :pedidoc.Id];
        
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        Blob b=Blob.valueOf('This is version data');
        cv.VersionData = b;
        cv.Title = 'text.txt';
        cv.PathOnClient = 'test.txt';
        insert cv;

        ContentVersion cvi = [SELECT id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id limit 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cvi.ContentDocumentId;
        cdl.LinkedEntityId = d.Id;
        cdl.ShareType = 'I';
        insert cdl;

        createPedidoLineItems(pedidoc);
 
        pedidoCompra = [SELECT Id, N_de_Seal__c, Booking_Agente__c, Estado2__c, Fecha_de_Compromiso_con_el_Cliente__c, FechaConfirmacionCliente__c, Proforma__c, Proforma__r.ETD__c, Proforma__r.Cuenta__r.PorcentajeAportaciones__c, Precio_Total__c, ImporteVentaNeto__c, Proforma__r.Cuenta__r.ParentId FROM PedidoDeCompra__c WHERE N_de_Seal__c = 'ABC012'];
        System.debug('fechacompormisocliente [' + pedidoCompra.Proforma__c + '] [' + pedidoCompra.Proforma__r.ETD__c + '] [' + pedidoCompra.Fecha_de_Compromiso_con_el_Cliente__c + ']');
        
        return pedidoCompra;
    }

    public void createPedidoLineItems(PedidoDeCompra__c pedido)
    {
        PedidoLineItem__c pedidoLine = new PedidoLineItem__c(PedidoDeCompra__c = pedido.id,
                                                             PrecioDeVenta__c = 67,
                                                             UnidadesPorMasterbox__c = 5, 
                                                             NumeroDeCajas__c = 4,
                                                             Requisitos_Especiales__c = 'REqEspPL');

        insert pedidoLine;

        PedidoLineItem__c pedidoLineInserted = [SELECT Id, PedidoDeCompra__c, Requisitos_Especiales__c, Name, Unidades__c FROM PedidoLineItem__c WHERE Requisitos_Especiales__c = 'REqEspPL'];
    }

/********************** Getters *****************************/

    public Opportunity getOpportunity(){
        return opp;
    }

    /* Retorna el OLI correspondiente al producto p para la oportunidad opp */
    public OpportunityLineItem getOLI4Prod(Product2 p){
        return [SELECT Id, 
                    Quantity
                    FROM OpportunityLineItem
                    WHERE Product2Id = :p.Id
                    AND OpportunityId = :opp.Id];
    }

    public Proforma__c getProforma(){
        list<Proforma__c> pro = [SELECT Id,
                                    Name,
                                    TipoDeContenedor__c,
                                    EstudioOportunidad__c,
                                    Cuenta__c
                                    FROM Proforma__c];
        if (pro.isEmpty())
        {
            return createProforma(false);
        }
        
        return pro[0];
    }

    public Proforma__c createAndFetchProforma()
    {
       Proforma__c prof = createProforma(false, 'Proforma agente prueba');
       return prof;
    }


    public EstudioOportunidad__c createEstudioOportunidadSplit(Account fabrica, Opportunity oppOrig) {
       EstudioOportunidad__c eoins;

       EstudioOportunidad__c newEstudio = new EstudioOportunidad__c(Oportunidad__c = oppOrig.Id,
                                                                    Fabrica__c = fabrica.Id);
       insert newEstudio;

       eoins = [SELECT Id, Fabrica__c, Oportunidad__c, Oportunidad__r.AccountId, Oportunidad__r.Name FROM EstudioOportunidad__c WHERE Id = :newEstudio.Id];
       return eoins;
    }


   /**
    *   Creates a EstudioOportunidad and a Proforma with (or without items) based on the withItmes parameter
    */
    public Proforma__c createProforma(Boolean withItems)
    {
        return createProforma(withItems, 'Proforma Prueba');
    }    


    /**
    *   Creates a EstudioOportunidad and a Proforma with (or without items) based on the withItmes parameter
    */
    public Proforma__c createProforma(Boolean withItems, String proformaName){
        
        CreateSyncEstudioOportunidad cc = new CreateSyncEstudioOportunidad(new ApexPages.StandardController(opp));
        cc.execute();
        System.debug('OOOPPP ID [' + opp.Id + ']');
        List<EstudioOportunidad__c> estudios = [SELECT Id, Name, Oportunidad__c
                                                  FROM EstudioOportunidad__c];

        System.debug('EO SIZE [' + estudios.size() + ']');
        for(EstudioOportunidad__c eo : estudios) {
            System.debug('EO ID [' + eo.Id + '] OP ID [' + eo.Oportunidad__c + ']');
        }
        
        //fetch the EstudioOportunidad, create a Proforma and link it
        EstudioOportunidad__c eo = [SELECT Id
                                        FROM EstudioOportunidad__c
                                        WHERE Oportunidad__c = :opp.Id
                                        limit 1];
                                        
        Opportunity tstOpp = [SELECT Id, Name, OwnerId, Owner.UserName, Owner.Email FROM Opportunity WHERE Id = :opp.Id];
        System.debug('TEST UTIL OPP[' + tstOpp.Id + '] [' + tstOpp.Name + '] [' + tstOpp.OwnerId + '] [' + tstOpp.Owner.UserName + '] [' + tstOpp.Owner.Email + ']');        
                                        
        System.debug('TEST UTIL EO ID (2)[' + eo.Id + ']');
        proforma = new Proforma__c(Name = proformaName,
                                        TipoDeContenedor__c = '20 pies',
                                        Oportunidad__c = tstOpp.Id,
                                        EstudioOportunidad__c = eo.Id,
                                        Aprobado_Direccion__c = false,
                                        Final_Shipping_Window__c = Date.today(),
                                        Initial_Shipping_Window__c = Date.today(),
                                        ETD__c = Date.today().addDays(-35),
                                        Cuenta__c = cliente.Id);
        insert proforma;
        System.debug('TEST UTIL CREATE PROF [' + proforma.Id + ']');
        
        if(withItems){
            list<ProformaLineItem__c> lpli = new list<ProformaLineItem__c>();

            for(OpportunityLineItem oli : [SELECT Product2Id,
                                                    Quantity,
                                                    UnitPrice,
                                                    Product2.PrecioDeFabrica__c,
                                                    Product2.CostoPackaging__c,
                                                    Product2.CostoImportacionUnidad__c,
                                                    Product2.Unidades_por_Masterbox2__c,
                                                    Product2.MasterboxM3_2__c
                                                    FROM OpportunityLineItem
                                                    WHERE EstudioOportunidad__c = :eo.Id 
                                                    ]){
                lpli.add(new ProformaLineItem__c(NumeroDeCajas__c = oli.Quantity,
                                                    Proforma__c = proforma.id,
                                                    Producto__c = oli.Product2Id,
                                                    PrecioUnitario__c = oli.UnitPrice,
                                                    CostoFabrica__c = oli.Product2.PrecioDeFabrica__c + oli.Product2.CostoPackaging__c,
                                                    CostoExtraUnitario__c = oli.Product2.CostoImportacionUnidad__c,
                                                    UnidadesPorMasterbox__c = oli.Product2.Unidades_por_Masterbox2__c,
                                                    CBMMasterBox__c = oli.Product2.MasterboxM3_2__c));
            }
            insert lpli;
        }
        return proforma;
    }

    public Pricebook2 getCustomPricebook(){
        return customPB;
    }

    /**
    *   Retorna el primer producto de fabrica tal cual se inserto
    */
    public Product2 getFirstPDF(){
        return prodDeFabrica[0];
    }


    /**
    *   Retorna el primer producto de fabrica actualizado con sus pricebookEntries
    */
    public Product2 getFirstPDFUpdated(){
        System.debug('GET FIRST PDF UPDATED [' + prodDeFabrica[0].Name + '] [' + prodDeFabrica[0].Id + ']');
        return [SELECT Id,
                    Name,
                    PrecioDeFabrica__c,
                    CostoImportacionUnidad__c,
                    CostoPackaging__c,
                    (SELECT Id,
                        Name,
                        Pricebook2.Margen__c,
                        UnitPrice
                        FROM PricebookEntries),
                    ProductoBase__c
                    FROM Product2
                    WHERE Id = :prodDeFabrica[0].Id
                    AND RecordType.DeveloperName = 'ProductoDeFabrica'];
    }

    /**
    *   Retorna todos los productos de fabrica actualizados con sus pricebookEntries
    */
    public list<Product2> getAllPDFUpdated(){
        System.debug('GET ALL PDF UPDATED');
        List<Product2> prodsUpdts;
        prodsUpdts = [SELECT Id,
                    Name,
                    PrecioDeFabrica__c,
                    CostoImportacionUnidad__c,
                    CostoPackaging__c,
                    (SELECT Id,
                        Name,
                        Pricebook2.Margen__c,
                        UnitPrice
                        FROM PricebookEntries),
                    ProductoBase__c
                    FROM Product2
                    WHERE RecordType.DeveloperName = 'ProductoDeFabrica'];
                    
        System.debug('GET ALL PDF UPDATED [' + prodsUpdts.size() + ']');      
        return prodsUpdts;
    }

    /**
    *   Retorna todos los productos de fabrica para el Producto Base pBase
    */
    public list<Product2> getPDFForBase(Id pBase){
        return [SELECT Id,
                    Name,
                    PrecioDeFabrica__c,
                    CostoImportacionUnidad__c,
                    CostoPackaging__c,
                    (SELECT Id,
                        Pricebook2.Margen__c,
                        UnitPrice
                        FROM PricebookEntries),
                    ProductoBase__c
                    FROM Product2
                    WHERE RecordType.DeveloperName = 'ProductoDeFabrica'
                    AND ProductoBase__c = :pBase];
    }


    /**
    *   Retorna los productos base actualizados con su itemDeEscandallo
    */
    public list<Product2> getAllPBUpdated(){
        return [SELECT Id,
                    Name,
                    UnidadesHQ__c,
                    CostoImportacionUnidad__c,
                    ProductCode,
                    Codigo_EAN__c,
                    Codigo_DUN_14__c,
                    IdImagen1__c,
                    (SELECT UnidadesHQ2__c,
                        PrecioCompraFabrica__c,
                        CostoImportacionUnidad__c
                        FROM ItemsEscandallo__r)
                    FROM Product2
                    WHERE RecordType.DeveloperName = 'Producto'];
    }

    /**
    *   Retorna el producto de Id pId con los campos seleccionados
    */
    public Product2 getPBUpdated(Id pId){
        return [SELECT Id,
                    Name,
                    UnidadesHQ__c,
                    CostoImportacionUnidad__c,
                    ProductCode,
                    Codigo_EAN__c,
                    Codigo_DUN_14__c,
                    (SELECT UnidadesHQ2__c,
                        PrecioCompraFabrica__c,
                        CostoImportacionUnidad__c
                        FROM ItemsEscandallo__r)
                    FROM Product2
                    WHERE Id = :pId
                    limit 1];
    }

    /**
    *   Retorna todos los Items de Escandallo
    */
    public list<EscandalloLineItem__c> getAllItemsEscandallo(){
        return [SELECT Id,
                    UnidadesHQ2__c,
                    PrecioCompraFabrica__c,
                    CostoImportacionUnidad__c
                    FROM EscandalloLineItem__c];
    }

    /**
    *   Retorna el Item de Escandallo para el Producto Base pBase 
    *   (Sera siempre a lo sumo un Item o ninguno)
    */
    public list<EscandalloLineItem__c> getItemsEscandalloForBase(Id pBase){
        return [SELECT Id,
                    UnidadesHQ2__c,
                    PrecioCompraFabrica__c,
                    CostoImportacionUnidad__c
                    FROM EscandalloLineItem__c
                    WHERE Producto__c = :pBase];
    }

    public list<Solicitud_de_Muestra__c> getSolicitudesDeMuestra(){
        return [SELECT Id
                  FROM Solicitud_de_Muestra__c];
    }

    public list<Muestra__c> getMuestras(Solicitud_de_Muestra__c s){
        return [SELECT Id
                  FROM Muestra__c
                 WHERE Solicitud_de_Muestra__c = :s.Id];
    }
    
    public list<PedidoDeCompra__c> getPedidos(){
        return [SELECT Id, 
                        Booking_Agente__c,
                        Name,
                        CostoOrigen__c,
                        PorcentajeDepositoAFabrica__c,
                        Aprobada_Transferencia_Deposito__c,
                        Fecha_Aprobacion_Pago_Deposito__c,
                        Monto_deposito__c,
                        Aprobada_Transferencia_Balance__c,
                        Fecha_Aprobacion_Pago_Balance__c
                  FROM PedidoDeCompra__c];
    }

    public list<PedidoDeCompra__c> getPedidosAgente() {
        return [SELECT Id, 
                       Booking_Agente__c,
                       Numero_de_Orden__c,
                       Proveedor__c,
                       Cuenta_Agente_DO__c,
                       Cuenta_Agente_DO__r.Name,
                       Fecha_Maxima_Embarque__c,
                       Enviar_solicitud_booking__c,
                       Solicitud_booking_enviada__c,
                       Fecha_Minima_Embarque__c
                FROM PedidoDeCompra__c WHERE N_de_Seal__c = 'ABC012'];
    }

    public void createProductosBaseCustom(Integer nmb) {
        Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();

        productosBase = new list<Product2>();

        for(Integer i = 0; i < nmb; i++)
        {
          productosBase.add(new Product2(Name = 'ProdTestTC' + String.valueOf(i),
                                         RecordTypeId = idRT, 
                                         M3Unidad__c = 0.5,
                                         UnidadesContainer20__c = 1000,
                                         UnidadesPorMasterBox__c = 2,
                                         UnidadesHQ__c = 1000,
                                         isActive = false,
                                         MasterboxAltoCm__c = '3',
                                         MasterboxAnchoCm__c = '3',
                                         MasterboxLargoCm__c = '3',
                                         MasterboxM3__c = 27,
                                         CajaAltoCm__c = '3',
                                         CajaAnchoCm__c = '3',
                                         CajaLargoCm__c = '3',
                                         CajaM3__c = 27,
                                         ProductoAltoCm__c = '3',
                                         ProductoAnchoCm__c = '3',
                                         ProductoLargoCm__c = '3',
                                         ProductoM3__c = 27,
                                         Family = familyProductoGarden,
                                         Subfamilia__c = '2-Kitchen & Dining Furniture',
										Clase__c = '03-Dining Sets',
                                         Marca__c = i == 0 ? marcaProductoGarden : marcaProductoOutdoorSoriana));
        }                                

        //Products with no values
        for(Integer i = 0; i < nmb; i++)
        {
          productosBase.add(new Product2(Name = 'ProdTestTCNV' + String.valueOf(i),
                                         RecordTypeId = idRT, 
                                         M3Unidad__c = 0.5,
                                         UnidadesPorMasterBox__c = 2, 
                                         UnidadesHQ__c = 1000,
                                         isActive = false,
                                         Family = familyProductoGarden,
                                         Subfamilia__c = '2-Kitchen & Dining Furniture',
										  Clase__c = '03-Dining Sets',
                                         Marca__c = marcaProductoGarden));
        }                                

        insert productosBase;    
    }

    public PedidoDeCompra__c getPedidoCompra() 
    {
        return pedidoCompra;
    }

    public Account getAgent() 
    {
        return agente;
    }

    public Account getParentAgent() 
    {
        return parent;
    }


    //----------------------------- split

    private void createProductosBaseSplit() {
    Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
    Product2 productoBase;

    prodBaseSplit = new List<Product2>();

    productoBase = new Product2(Name = 'Parrilla',
                                RecordTypeId = idRT, 
                                M3Unidad__c = 0.5,
                                UnidadesPorMasterBox__c = 2, 
                                UnidadesHQ__c = 1000,
                                UnidadesContainer20__c = 400,
                                isActive = false,
                                MasterboxAltoCm__c = '10',
                                MasterboxAnchoCm__c = '10',
                                MasterboxLargoCm__c = '10',
                                MasterboxM3__c = 1000,
                                ProductCode = '12345678',
                                Family = familyProductoGarden,
                                Subfamilia__c = '1-Outdoor Furniture',  // CAMBIADO
                                Clase__c = '07-Outdoor Benches',         // CAMBIADO
                                Registrado_Libra__c = false,
                                Marca__c = marcaProductoGarden);
    prodBaseSplit.add(productoBase);
    parrillaBase = productoBase;

    productoBase = new Product2(Name = 'Banco',
                                RecordTypeId = idRT, 
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
                                Subfamilia__c = '1-Outdoor Furniture',  // CAMBIADO
                                Clase__c = '07-Outdoor Benches',         // CAMBIADO
                                Marca__c = marcaProductoGarden);
    prodBaseSplit.add(productoBase);

    productoBase = new Product2(Name = 'Silla',
                                RecordTypeId = idRT, 
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
                                Subfamilia__c = '1-Outdoor Furniture',  // CAMBIADO
                                Clase__c = '07-Outdoor Benches',         // CAMBIADO
                                Marca__c = marcaProductoGarden);
    prodBaseSplit.add(productoBase);

    insert prodBaseSplit;        
}
    

    private void createProductosFabricaSplit() {
        Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('ProductoDeFabrica').getRecordTypeId();

        Date fechaValida = Date.today();
        Date fechaNoValida = Date.today();
        fechaNoValida = fechaNovalida.addDays(-20);
        //-------------------------------------------------------------------------

        prodDeFabricaSplit = new List<Product2>();
        for(Product2 p : prodBaseSplit)
        {
           if(p.Name.equals('Parrilla'))
           {
              parrilla = new Product2(Name = p.Name,
                                             RecordTypeId = idRT, 
                                             ProductoBase__c = p.Id, 
                                             Packaging__c = '1-BROWN BOX',
                                             Fabrica__c = fabrica.Id,
                                             PlazoDeFabricacion__c = '45-60 días',
                                             MOQ__c = 1000,
                                             Fecha_revision_costo__c = fechaNoValida,
                                             PrecioDeFabrica__c = 20,
                                             CostoPackaging__c = 4,
                                             isActive = true);
              prodDeFabricaSplit.add(parrilla);
           }
           if(p.Name.equals('Silla'))
           {
              silla = new Product2(Name = p.Name,
                                          RecordTypeId = idRT, 
                                          ProductoBase__c = p.Id, 
                                          Packaging__c = '1-BROWN BOX',
                                          Fabrica__c = fabrica.Id,
                                          PlazoDeFabricacion__c = '45-60 días',
                                          MOQ__c = 1000,
                                          Fecha_revision_costo__c = fechaValida,
                                          PrecioDeFabrica__c = 20,
                                          CostoPackaging__c = 4,
                                          isActive = true);
              prodDeFabricaSplit.add(silla);
           }
           if(p.Name.equals('Banco'))
           {
              banco = new Product2(Name = p.Name,
                                          RecordTypeId = idRT, 
                                          ProductoBase__c = p.Id, 
                                          Packaging__c = '1-BROWN BOX',
                                          Fabrica__c = fabrica.Id,
                                          PlazoDeFabricacion__c = '45-60 días',
                                          MOQ__c = 1000,
                                          Fecha_revision_costo__c = fechaValida,
                                          PrecioDeFabrica__c = 20,
                                          CostoPackaging__c = 4,
                                          isActive = true);
              prodDeFabricaSplit.add(banco);
           }
        }

        insert prodDeFabricaSplit;
    }


    private void createOpportunityOriginal(Account cliente, PlanificacionComercial__c pc){
        createOpportunityOriginal(cliente, pc, Date.today().year());
    }

    private void createOpportunityOriginalFlagFalse(Account cliente, PlanificacionComercial__c pc){
        createOpportunityOriginalFlagFalse(cliente, pc, Date.today().year());
    }


    private void createOpportunityOriginal(Account cliente, PlanificacionComercial__c pc, Integer year) {
        Date opDate = Date.newInstance(year, Date.today().month() , Date.today().day());
        opp = new Opportunity(Name = 'Opportunity Original',
                              AccountId = cliente.Id,
                              PlanificacionComercial__c = pc.Id,
                              CloseDate = opDate,
                              StageName = 'Toma de Contacto',
                              Campana__c = 'Back to School',
                              Fecha_de_Compromiso__c = opDate);
        insert opp;
    }

    //Added
    private void createOpportunityOriginalFlagFalse(Account cliente, PlanificacionComercial__c pc, Integer year) {
        Date opDate = Date.newInstance(year, Date.today().month() , Date.today().day());
        opp = new Opportunity(Name = 'Opportunity OriginalTR',
                              AccountId = cliente.Id,
                              PlanificacionComercial__c = pc.Id,
                              Is_Split_Flag__c = false,
                              CloseDate = opDate,
                              StageName = 'Toma de Contacto',
                              Campana__c = 'Back to School',
                              Fecha_de_Compromiso__c = opDate);
        insert opp;
        System.debug('TestUtil - createOpportunityOriginalFlagFalse - oppId [' + opp.Id + ']');
    }

    public List<Proforma__c> createProformasSplit(Account pcliente, EstudioOportunidad__c eo, Opportunity oppOriginal)
    {
        List<PedidoDeCompra__c>  pedidosCompra = new List<PedidoDeCompra__c>();        
        List<Proforma__c> proformasSplit = new List<Proforma__c>();
        List<Cobro__c> cobrosLibra = new List<Cobro__c>();
        Cobro__c cobroLibra;
        Proforma__c p;
        Proforma__c pp;
        PedidoDeCompra__c pedidoCompra;

        System.debug(' ******************* createProformasSplit *****************************');
        System.debug(' ******************* acc cuenta[' + pcliente.Id + ']');
        System.debug(' ******************* acc cuenta-parent[' + pcliente.ParentId + ']');
        System.debug(' ******************* acc [' + pcliente.Parent.Agente_Cliente__c + ']');

        Account proveedor = createFabrica('tstFab', 'cat');

        System.debug('TestUtil.createProformasSplit oppid [' + oppOriginal.Id + '] [' + oppOriginal.AccountId + '] eop[' + eo.Id + '] [' + eo.Oportunidad__c + '] [' + eo.Oportunidad__r.AccountId + ']');
        p = new Proforma__c(Name = 'Vacia1',
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

        insert proformasSplit;
        

        System.debug('PROFORM APP [' + pp.Id + '] [' + pp.Cuenta__c + ']');

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
                                        Proveedor__c = proveedor.Id,
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
                                        Proveedor__c = proveedor.Id,
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
                                        Proveedor__c = proveedor.Id,
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
                                        Proveedor__c = proveedor.Id,
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
                                        Proveedor__c = proveedor.Id,
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

        insert pedidosCompra;

        cobroLibra = new Cobro__c(Codigo_Empresa__c = '400',
                                  Ejercicio__c = Date.today().year(),
                                  Fecha_Cobro__c = date.today(),
                                  Importe_cobrado__c = 2000,
                                  Name = 'cob1',
                                  Numero_Factura__c = '0001',
                                  Pedido__c = pedidosCompra.get(0).Id);

        cobrosLibra.add(cobroLibra);

        return proformasSplit;
    }



    public List<Proforma__c> createProformasSplitTR(Account pcliente, EstudioOportunidad__c eo, Opportunity oppOriginal)
    {
        List<PedidoDeCompra__c>  pedidosCompra = new List<PedidoDeCompra__c>();        
        List<Proforma__c> proformasSplit = new List<Proforma__c>();
        List<Cobro__c> cobrosLibra = new List<Cobro__c>();
        Cobro__c cobroLibra;
        Proforma__c p;
        Proforma__c pp;        
        PedidoDeCompra__c pedidoCompra;
        ProformaLineItem__c pli;        

        System.debug(' ******************* createProformasSplit *****************************');
        System.debug(' ******************* acc cuenta[' + pcliente.Id + ']');
        System.debug(' ******************* acc cuenta-parent[' + pcliente.ParentId + ']');
        System.debug(' ******************* acc [' + pcliente.Parent.Agente_Cliente__c + ']');

        Account proveedor = createFabrica('tstFab', 'cat');

        System.debug('TestUtil.createProformasSplit oppid [' + oppOriginal.Id + '] [' + oppOriginal.AccountId + '] eop[' + eo.Id + '] [' + eo.Oportunidad__c + '] [' + eo.Oportunidad__r.AccountId + ']');
        p = new Proforma__c(Name = 'Vacia1',
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

        insert proformasSplit;

        System.debug('PROFORM APP [' + pp.Id + '] [' + pp.Cuenta__c + ']');
        
        //List<Product2> prods = [SELECT Id, Name FROM Product2 WHERE Name = 'Silla'];
        
        pli = new ProformaLineItem__c (Proforma__c = p.Id,
                                       Producto__c = silla.Id,
                                       PrecioUnitario__c = 10,
                                       UnidadesPorMasterBox__c = 2,
                                       NumeroDeCajas__c = 2);
                                       
        insert pli;
        
        List<ProformaLineItem__c> plis = [SELECT Id, Name, Proforma__c, Producto__c, Proforma__r.Oportunidad__c FROM ProformaLineItem__c];
        for(ProformaLineItem__c plil : plis) {
            System.debug('TestUtil - createProformasSplitTR - prof[' + plil.Proforma__c + '] prod[' + plil.Producto__c + '] opp[' + plil.Proforma__r.Oportunidad__c + ']');
        }
        
        
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
                                        Proveedor__c = proveedor.Id,
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
                                        Proveedor__c = proveedor.Id,
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
                                        Proveedor__c = proveedor.Id,
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
                                        Proveedor__c = proveedor.Id,
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
                                        Proveedor__c = proveedor.Id,
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

        insert pedidosCompra;

        cobroLibra = new Cobro__c(Codigo_Empresa__c = '400',
                                  Ejercicio__c = Date.today().year(),
                                  Fecha_Cobro__c = date.today(),
                                  Importe_cobrado__c = 2000,
                                  Name = 'cob1',
                                  Numero_Factura__c = '0001',
                                  Pedido__c = pedidosCompra.get(0).Id);

        cobrosLibra.add(cobroLibra);

        return proformasSplit;
    }



    public void createPedidoLineItemsSplit()
    {
        PedidoLineItem__c pedidoLine;
        List<PedidoLineItem__c> pedidoLineItems = new List<PedidoLineItem__c>();
        pedidoLine = new PedidoLineItem__c(PedidoDeCompra__c = pedido1.id,
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

        insert pedidoLineItems;
    }

    public void createOpportunityLineItemsSplit(Opportunity opp, Pricebook2 pb, EstudioOportunidad__c eo)
    {
       OpportunityLineItem oli;
       List<OpportunityLineItem> listOLI = new List<OpportunityLineItem>();
       
       System.debug('TestUtil - createOpportunityLineItemsSplit - oppid[' + opp.Id + ']');

       Pricebook2 stdPricebook = new Pricebook2(ID = Test.getStandardPricebookId(),
                                                isActive=true, 
                                                Margen__c = 20);
       update stdPricebook;


       PricebookEntry pbeparr = new PricebookEntry(Pricebook2Id = stdPricebook.Id,
                                               UnitPrice = 10,
                                               Product2Id = parrilla.Id,
                                               isActive = true);
       insert pbeparr;

       PricebookEntry pbebanc = new PricebookEntry(Pricebook2Id = stdPricebook.Id,
                                               UnitPrice = 10,
                                               Product2Id = banco.Id,
                                               isActive = true);
       insert pbebanc;

       PricebookEntry pbesill = new PricebookEntry(Pricebook2Id = stdPricebook.Id,
                                               UnitPrice = 10,
                                               Product2Id = silla.Id,
                                               isActive = true);
       insert pbesill;

       oli = new OpportunityLineItem(OpportunityId = opp.Id,
                                     PricebookEntryId = pbeparr.Id,
                                     UnitPrice = 3,
                                     EstudioOportunidad__c = eo.Id,
                                     Porcentaje_Item__c = 5,
                                     Product2Id = parrilla.Id,
                                     Quantity = 200);
       listOLI.add(oli);

       oli = new OpportunityLineItem(OpportunityId = opp.Id,
                                     PricebookEntryId = pbebanc.Id,
                                     UnitPrice = 3,
                                     EstudioOportunidad__c = eo.Id,                                     
                                     Porcentaje_Item__c = 5,
                                     Product2Id = banco.Id,
                                     Quantity = 600);
       listOLI.add(oli);

       oli = new OpportunityLineItem(OpportunityId = opp.Id,
                                     PricebookEntryId = pbesill.Id,
                                     UnitPrice = 3,
                                     EstudioOportunidad__c = eo.Id,                                     
                                     Porcentaje_Item__c = 5,
                                     Product2Id = silla.Id,
                                     Quantity = 500);
       listOLI.add(oli);

       insert listOLI;
    }

    public void createOpportunityLineItemsPedido(Opportunity opp, Pricebook2 pb, EstudioOportunidad__c eo)
    {
       OpportunityLineItem oli;
       List<OpportunityLineItem> listOLI = new List<OpportunityLineItem>();

       Pricebook2 stdPricebook = new Pricebook2(ID = Test.getStandardPricebookId(),
                                                isActive=true, 
                                                Margen__c = 20);
       update stdPricebook;


       PricebookEntry pbeparr = new PricebookEntry(Pricebook2Id = stdPricebook.Id,
                                               UnitPrice = 10,
                                               Product2Id = parrilla.Id,
                                               isActive = true);
       insert pbeparr;

       PricebookEntry pbebanc = new PricebookEntry(Pricebook2Id = stdPricebook.Id,
                                               UnitPrice = 10,
                                               Product2Id = banco.Id,
                                               isActive = true);
       insert pbebanc;

       PricebookEntry pbesill = new PricebookEntry(Pricebook2Id = stdPricebook.Id,
                                               UnitPrice = 10,
                                               Product2Id = silla.Id,
                                               isActive = true);
       insert pbesill;

       oli = new OpportunityLineItem(OpportunityId = opp.Id,
                                     PricebookEntryId = pbeparr.Id,
                                     TotalPrice = 3,
                                     EstudioOportunidad__c = eo.Id,
                                     Porcentaje_Item__c = 5,
                                     Product2Id = parrilla.Id,
                                     Quantity = 200,
                                     Aportaciones_2__c = 10,
                                     Convenio_2__c = 3
                                     );
       listOLI.add(oli);

       oli = new OpportunityLineItem(OpportunityId = opp.Id,
                                     PricebookEntryId = pbebanc.Id,
                                     TotalPrice = 3,
                                     EstudioOportunidad__c = eo.Id,                                     
                                     Porcentaje_Item__c = 5,
                                     Product2Id = banco.Id,
                                     Quantity = 600,
                                     Aportaciones_2__c = 10,
                                     Convenio_2__c = 3
                                     );
       listOLI.add(oli);

       insert listOLI;
    }

    public Catalogo__c genCatalogo(String token) {
        Catalogo__c c = new Catalogo__c(Name = 'Test Catalogo',
                                        Cliente__c = cliente.Id,
                                        Familias__c = 'H,G,B',
                                        Clases__c = 'H101,H102,H103,H104,H105,H106,H201,H202,H203,H204,H205,H206,H207,H208,H209,H210,H301,H302,H303,H304,H305,H306,H307,H308,H309,H310,H401,H402,H403,H404,H405,G101,G102,G103,G104,G105,G106,G107,B101,B102,B201',
                                        Portal_Token__c = token);
        insert c;
        return c;
    }

    public Proforma__c getProformaCred()
    {
        return proforma;
    }

    public Account getClienteCred()
    {
        return cliente;
    }

    public PedidoDeCompra__c getPedido1() {  
        PedidoDeCompra__c pedido;
        pedido = [SELECT Id, 
                         Name,
                         NumeroDeContenedor__c,
                         N_de_Seal__c,
                         Enviado_libra__c,
                         Numero_de_Factura__c, 
                         Fecha_Factura__c, 
                         Proforma__r.Cuenta__r.Codigo_rapido__c,
                         Proforma__r.Cuenta__r.Parent.Sociedad__c,
                         Proforma__r.Cuenta__r.ParentId,
                         CurrencyIsoCode,
                         (SELECT Id,
                                 CodigoProducto__c,
                                 CostoOrigen__c,
                                 PrecioDeVenta__c,
                                 Unidades__c,
                                 CostoOrigenTot__c,
                                 Producto__c,
                                 Producto__r.Codigo_Anterior2__c
                            FROM PedidoLineItems__r)
                    FROM PedidoDeCompra__c 
                   WHERE Numero_de_Factura__c = 'A20/001'];
        return pedido;
    }

    public Account getFabrica() {
        return fabrica;
    }

    public PlanificacionComercial__c getPlanificacionComercial() {
        return this.pc;
    }

    public Document getDocumentImage() { 
        return documentImage;
    }

    public Product2 getProductImage() {
        return productWithImage;
    }
}