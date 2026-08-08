@isTest
private class TestLibraCallouts 
{
    @isTest static void testAltaCliente() {

        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        Account cl = tu.getClienteCred();

        LibraWS__c libraWSCS = new LibraWS__c();
	    libraWSCS.Name = 'desarrolloClientes';
        libraWSCS.endpoint__c = 'http://127.0.0.1';
        libraWSCS.param_alias__c = 'SF_CLIENTE';
        libraWSCS.param_id_user__c = 'EDISA';
        libraWSCS.param_pwd__c = 'EDISA';
        
        insert libraWSCS;

        AccountBatchLibra talc = new AccountBatchLibra(cl,'400','009800','1234');

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        Test.startTest();
	    LibraAltaClienteCallout callout = new LibraAltaClienteCallout('desarrolloClientes');
	    callout.executeCallout(talc);
        Test.stopTest();
    }

    @isTest static void testAltaClienteError() {

        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        Account cl = tu.getClienteCred();

        LibraWS__c libraWSCS = new LibraWS__c();
	    libraWSCS.Name = 'desarrolloClientes';
        libraWSCS.endpoint__c = 'http://127.0.0.1';
        libraWSCS.param_alias__c = 'SF_CLIENTE';
        libraWSCS.param_id_user__c = 'EDISA';
        libraWSCS.param_pwd__c = 'EDISA';
        
        insert libraWSCS;

        AccountBatchLibra talc = new AccountBatchLibra(cl,'400','009800','1234');

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuentaError'));
        Test.startTest();
	    LibraAltaClienteCallout callout = new LibraAltaClienteCallout('desarrolloClientes');
	    callout.executeCallout(talc);
        Test.stopTest();
    }

    @isTest static void testAltaProveedor() {

        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        Account cl = tu.getClienteCred();

        LibraWS__c libraWSCS = new LibraWS__c();
	    libraWSCS.Name = 'desarrolloProveedores';
        libraWSCS.endpoint__c = 'http://127.0.0.1';
        libraWSCS.param_alias__c = 'SF_PROVEEDORES';
        libraWSCS.param_id_user__c = 'EDISA';
        libraWSCS.param_pwd__c = 'EDISA';
        
        insert libraWSCS;

        AccountBatchLibra talp = new AccountBatchLibra(cl,'400','009800','12345');

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        LibraAltaProveedorCallout callout = new LibraAltaProveedorCallout('desarrolloProveedores');
        callout.executeCallout(talp);
    }


    @isTest static void testFacturaCompra() 
    {
       String pedidoId;        
       PedidoDeCompra__c pedido;
       Account acc = new Account(Name='acc1', Sociedad__c = 'Do Core');

       TestUtil tu = new TestUtil();
       tu.initOpportunitySplit();
       pedido = tu.getPedido1();

       pedido.Fecha_Factura__c = Date.today();
       upsert pedido;

       pedidoId = pedido.Id;

       pedido = [SELECT Id, 
						Name,
	                    NumeroDeContenedor__c,
	                    N_de_Seal__c,
					    Enviado_libra__c,
						Numero_de_Factura__c, //numero_secuencia
						Numero_de_Factura_Proveedor__c,
						Fecha_Factura__c, //fecha_factura
						Fecha_Factura_Proveedor__c,
                        Proforma__r.Cuenta__r.Codigo_rapido__c,
                        Proforma__r.Cuenta__r.Parent.Sociedad__c,
                        Proforma__r.Cuenta__r.ParentId,
                        Proveedor__r.Codigo_rapido__c,
                        CostoOrigen__c, 
                        Precio_Total__c, 
						Aprobado_Envio__c, 
						CurrencyIsoCode,
                        (SELECT Id,
						        CodigoProducto__c,
						        CostoOrigen__c,
                                PrecioDeVenta__c,
                                PrecioDeVentaTot__c,
						        Unidades__c,
						        CostoOrigenTot__c,
								Producto__c,
                                Producto__r.CodigoDeProductoBase__c,
							    Producto__r.Codigo_Anterior2__c
                           FROM PedidoLineItems__r)
				   FROM PedidoDeCompra__c
				  WHERE Id = :pedidoId];

       PedidoParentAccount ppa = new PedidoParentAccount();
       ppa.pedido = pedido;
       ppa.exchangeRateProveedor = '0.885';
       ppa.parentAccount = acc;

       LibraWS__c libraWSCS = new LibraWS__c();
	   libraWSCS.Name = 'desarrolloFacturaCompra';
       libraWSCS.endpoint__c = 'http://127.0.0.1';
       libraWSCS.param_alias__c = 'SFORCE_FACTURAS_COMPRA';
       libraWSCS.param_id_user__c = 'EDISA';
       libraWSCS.param_pwd__c = 'EDISA';
        
       insert libraWSCS;

       Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('example'));
       LibraFacturaCompraCallout callout = new LibraFacturaCompraCallout('desarrolloFacturaCompra');
       callout.executeCallout(ppa);
    }


    @isTest static void testFacturaVenta() 
    {
       String pedidoId;
       PedidoDeCompra__c pedido;
       Account acc = new Account(Name='acc1', Sociedad__c = 'Do Core');

       TestUtil tu = new TestUtil();
       tu.initOpportunitySplit();
       pedido = tu.getPedido1();
       pedido.Fecha_Factura__c = Date.today();
       upsert pedido;

       pedidoId = pedido.Id;

       pedido = [SELECT Id, 
						Name,
	                    NumeroDeContenedor__c,
	                    N_de_Seal__c,
					    Enviado_libra__c,
						Numero_de_Factura__c, //numero_secuencia
						Numero_de_Factura_Proveedor__c,
						Fecha_Factura__c, //fecha_factura
						Fecha_Factura_Proveedor__c,
                        Proforma__r.Cuenta__r.Codigo_rapido__c,
                        Proforma__r.Cuenta__r.Parent.Sociedad__c,
                        Proforma__r.Cuenta__r.ParentId,
                        Proforma__r.CurrencyIsoCode,
                        CostoOrigen__c, 
                        Precio_Total__c, 
						Aprobado_Envio__c, 
						CurrencyIsoCode,
                        (SELECT Id,
						        CodigoProducto__c,
						        CostoOrigen__c,
                                PrecioDeVenta__c,
                                PrecioDeVentaTot__c,
                                CostoTotalUnitario__c,
                                Unidades__c,
                                UnidadesPorMasterbox__c,
                                NumeroDeCajas__c,
						        CostoOrigenTot__c,
								Producto__c,
                                Producto__r.CodigoDeProductoBase__c,
							    Producto__r.Codigo_Anterior2__c
                           FROM PedidoLineItems__r)
				   FROM PedidoDeCompra__c
				  WHERE Id = :pedidoId];
                        
       PedidoParentAccount ppa = new PedidoParentAccount();
       ppa.pedido = pedido;
       ppa.exchangeRateCliente = '1.25';
       ppa.parentAccount = acc;

       LibraWS__c libraWSCS = new LibraWS__c();
	   libraWSCS.Name = 'desarrolloFacturaVenta';
       libraWSCS.endpoint__c = 'http://127.0.0.1';
       libraWSCS.param_alias__c = 'SFORCE_FACTURAS_VENTA';
       libraWSCS.param_id_user__c = 'EDISA';
       libraWSCS.param_pwd__c = 'EDISA';
        
       insert libraWSCS;

       Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('example'));
       LibraFacturaVentaCallout callout = new LibraFacturaVentaCallout('desarrolloFacturaVenta');
       callout.executeCallout(ppa);
    }

    @isTest static void testCobros() 
    {
       List<PedidoDeCompra__c> pedidos;
       PedidoDeCompra__c pedido;        
       TestUtil tu = new TestUtil();
       tu.initOpportunitySplit();
       pedido = tu.getPedido1();
       pedido.Numero_de_Factura__c = 'F19/342';
       upsert pedido;

       LibraWS__c libraWSCS = new LibraWS__c();
	   libraWSCS.Name = 'desarrolloCobros';
       libraWSCS.endpoint__c = 'http://127.0.0.1';
       libraWSCS.param_alias__c = 'SFORCE_FACTURAS_VENTA';
       libraWSCS.param_id_user__c = 'EDISA';
       libraWSCS.param_pwd__c = 'EDISA';
        
       insert libraWSCS;

       pedidos = new List<PedidoDeCompra__c>();
       pedidos.add(pedido);

       Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('cobros'));
       Test.startTest();
       LibraCobrosCallout callout = new LibraCobrosCallout('desarrolloCobros', '200');
       callout.executeCallout(pedidos);
       Test.stopTest();

    }

    @isTest static void testPagos() 
    {
       List<PedidoDeCompra__c> pedidos;
       PedidoDeCompra__c pedido;
       TestUtil tu = new TestUtil();
       tu.initOpportunitySplit();
       pedido = tu.getPedido1();
       pedido.Numero_de_Factura_Proveedor__c = 'ABC0023';
       upsert pedido;

       LibraWS__c libraWSCS = new LibraWS__c();
	   libraWSCS.Name = 'desarrolloPagos';
       libraWSCS.endpoint__c = 'http://127.0.0.1';
       libraWSCS.param_alias__c = 'SFORCE_FACTURAS_VENTA';
       libraWSCS.param_id_user__c = 'EDISA';
       libraWSCS.param_pwd__c = 'EDISA';
        
       insert libraWSCS;

       pedidos = new List<PedidoDeCompra__c>();
       pedidos.add(pedido);

       Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('pagos'));
       Test.startTest();
       LibraPagosCallout callout = new LibraPagosCallout('desarrolloPagos', '200');
       callout.executeCallout(pedidos);
       Test.stopTest();

    }

    @isTest static void testProductosCallout() 
    {
       List<PedidoDeCompra__c> pedidos;
       PedidoDeCompra__c pedido;
       Product2 prod;
       TestUtil tu = new TestUtil();
       tu.initOpportunitySplit();
       pedido = tu.getPedido1();
       pedido.Numero_de_Factura_Proveedor__c = 'ABC0023';
       upsert pedido;

       prod = tu.parrilla;

       Map<String, Proforma__c> factoryProforma = new Map<String, Proforma__c>();
       List<ProductBatchLibra> prodToSendLibra = new List<ProductBatchLibra>();
       prodToSendLibra.add(new ProductBatchLibra(prod, '200', factoryProforma));

       LibraWS__c libraWSCS = new LibraWS__c();
	   libraWSCS.Name = 'desarrolloProductos';
       libraWSCS.endpoint__c = 'http://127.0.0.1';
       libraWSCS.param_alias__c = 'SFORCE_PRODUCTOS';
       libraWSCS.param_id_user__c = 'EDISA';
       libraWSCS.param_pwd__c = 'EDISA';
        
       insert libraWSCS;

       Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('pagos'));
       Test.startTest();
       LibraProductosCallout callout = new LibraProductosCallout('desarrolloProductos');
       callout.executeCallout(prodToSendLibra.get(0));
       Test.stopTest();

    }


    @isTest static void testProductosSimpleCallout() {
       List<PedidoDeCompra__c> pedidos;
       PedidoDeCompra__c pedido;
       Product2 prod;
       TestUtil tu = new TestUtil();
       tu.initOpportunitySplit();
       pedido = tu.getPedido1();
       pedido.Numero_de_Factura_Proveedor__c = 'ABC0023';
       upsert pedido;

       prod = tu.parrillaBase;

       Product2 prodtst;

       prodtst = [select id, name, RecordType.DeveloperName, Registrado_Libra__c, CodigoDeProductoBase__c from product2 where id = :prod.Id];
       System.debug(prodtst);
       if(prodtst != null) {
        System.debug('PRODTST [' + prodtst.id + '] [' + prodtst.name + '] [' + prodtst.RecordType.DeveloperName + '] [' + prodtst.Registrado_Libra__c + '] [' + prodtst.CodigoDeProductoBase__c + ']');           
       }


       LibraWS__c libraWSCS = new LibraWS__c();
	   libraWSCS.Name = 'desarrolloProductos';
       libraWSCS.endpoint__c = 'http://127.0.0.1';
       libraWSCS.param_alias__c = 'SFORCE_PRODUCTOS';
       libraWSCS.param_id_user__c = 'EDISA';
       libraWSCS.param_pwd__c = 'EDISA';
        
       insert libraWSCS;

       List<String> isp = new List<String>();
       isp.add(prod.Id);
       Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
       Test.startTest();
       LibraSimpleAltaProducto callout = new LibraSimpleAltaProducto(isp, '400');
       callout.execute();
       callout.listProductsNotValid();
       Test.stopTest();
    }

    @isTest static void testSimpleAltaCliente() {

        TestUtil tu = new TestUtil();
        tu.initCliente();
        Account cl = tu.getClienteCred();

        LibraWS__c libraWSCS = new LibraWS__c();
	    libraWSCS.Name = 'desarrolloClientes';
        libraWSCS.endpoint__c = 'http://127.0.0.1';
        libraWSCS.param_alias__c = 'SF_CLIENTE';
        libraWSCS.param_id_user__c = 'EDISA';
        libraWSCS.param_pwd__c = 'EDISA';
        
        insert libraWSCS;

        List<String> isp = new List<String>();
        isp.add(cl.Id);

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        Test.startTest();
	    LibraSimpleAltaCliente callout = new LibraSimpleAltaCliente(isp);
	    callout.execute();
        Test.stopTest();
    }

    @isTest static void testSimpleAltaProveedor() {

        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        Account pr = tu.getFabrica();

        LibraWS__c libraWSCS = new LibraWS__c();
	    libraWSCS.Name = 'desarrolloProveedores';
        libraWSCS.endpoint__c = 'http://127.0.0.1';
        libraWSCS.param_alias__c = 'SF_PROVEEDORES';
        libraWSCS.param_id_user__c = 'EDISA';
        libraWSCS.param_pwd__c = 'EDISA';
        
        insert libraWSCS;

        List<String> isp = new List<String>();
        isp.add(pr.Id);

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        LibraSimpleAltaProveedor callout = new LibraSimpleAltaProveedor(isp, '400');
        //callout.execute();
    }


    @isTest static void testSimpleAltaFactura() {
        PedidoDeCompra__c pedido;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        pedido = tu.getPedido1();
        pedido.Fecha_Factura__c = Date.today();
        upsert pedido;

        LibraWS__c libraWSCS = new LibraWS__c();
	    libraWSCS.Name = 'desarrolloProveedores';
        libraWSCS.endpoint__c = 'http://127.0.0.1';
        libraWSCS.param_alias__c = 'SF_PROVEEDORES';
        libraWSCS.param_id_user__c = 'EDISA';
        libraWSCS.param_pwd__c = 'EDISA';
        
        insert libraWSCS;

        List<String> idsOrder = new List<String>();
        idsOrder.add(pedido.Id);

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));
        LibraSimpleAltaFactura callout = new LibraSimpleAltaFactura(idsOrder, true);
        callout.execute();
    }

}