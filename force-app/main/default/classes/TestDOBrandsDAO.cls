@isTest
private class TestDOBrandsDAO {
    
    @testSetup static void setup() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();
    }
    
    @isTest static void testRecordTypesAndAccount() {
        RecordType rt;
        Account clienteContacto;
        

        Account cliente = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Cliente' LIMIT 1];
        clienteContacto = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ClienteContacto' LIMIT 1];
        
        rt = DOBrandsDAO.getRecordType('Cliente', 'Account');
        DOBrandsDAO.getAccountByCodigoRapido(new List<String>{'22233'}, rt);
        DOBrandsDAO.getSociedades();
        DOBrandsDAO.getSociedades('USD');
        DOBrandsDAO.getSociedadInfo('Do América USD');
        DOBrandsDAO.getSociedadInfo('Do Core EUR');
        
        rt = DOBrandsDAO.getRecordType('ClienteContacto', 'Account');
        DOBrandsDAO.getProvider(clienteContacto.Id, rt);
        DOBrandsDAO.getProviderByToken('123', rt);
        DOBrandsDAO.getPortalCS('Desarrollo');
        DOBrandsDAO.getSelectOptions(Schema.Account.PlazoPago__c);
        DOBrandsDAO.getAccount(cliente.Id);
    }
    
    @isTest static void testPedidoAndOrder() {
        PedidoDeCompra__c pedido;
        List<String> idsPedidos = new List<String>();
        
        pedido = [SELECT Id FROM PedidoDeCompra__c WHERE Numero_de_Factura__c = 'A20/001' LIMIT 1];
        idsPedidos.add(pedido.Id);
        
        DOBrandsDAO.getOrderByNumber('PedidoSplit1');
        DOBrandsDAO.getOrderByToken('dummy');
        DOBrandsDAO.getOrdersDocuments(idsPedidos, new List<String>{'BL', 'Factura', 'Packing List'});
        DOBrandsDAO.getSociedadFromOrder(pedido.Id);
        DOBrandsDAO.getPedidoLineItemsTotales(pedido.Id);
        DOBrandsDAO.getPedidoLineItems(pedido.Id);
        DOBrandsDAO.getPackingList(idsPedidos);
        DOBrandsDAO.getPackingListByOrder(pedido.Id);
        DOBrandsDAO.getMaxInvoiceNumber('pe');
        DOBrandsDAO.getMaxInvoiceNumber('A');
    }

    @isTest static void testContentAndDocuments() {
        PedidoDeCompra__c pedido;
        List<String> idsPedidos = new List<String>();
        
        pedido = [SELECT Id FROM PedidoDeCompra__c WHERE Numero_de_Factura__c = 'A20/001' LIMIT 1];
        idsPedidos.add(pedido.Id);
        
        DOBrandsDAO.getContentDocumentLink(idsPedidos);
        DOBrandsDAO.getContentVersions(idsPedidos);
        DOBrandsDAO.getAWSMetadatos('AWSCotizacion');
        DOBrandsDAO.getCSEnvioCorreos('dummy');
        DOBrandsDAO.getCountOpportunitiesByCatalog('dummy');
    }
    
    @isTest static void testOpportunityAndProducts() {
        Opportunity opportunity;
        List<String> dummyIds = new List<String>{'dummy'};
        
       
        opportunity = [SELECT Id FROM Opportunity WHERE Name = 'Opportunity Original' LIMIT 1];
        
        DOBrandsDAO.getOpportunity(opportunity.Id);
        DOBrandsDAO.getOpportunityMP(opportunity.Id);
        DOBrandsDAO.getProformaBase(opportunity.Id);
        DOBrandsDAO.getProformaLineItems(opportunity.Id);
        DOBrandsDAO.getProductsByProductCode(dummyIds);
        DOBrandsDAO.getClonedRecordOLI(opportunity.Id);
        DOBrandsDAO.getClonedRecordsOLI(new List<String>{opportunity.Id});
    }
    @isTest static void testProformasAndProducts() {
    Opportunity opportunity;
    Proforma__c proforma;
    Account clienteContacto;
    PlanificacionComercial__c pc;
    
    opportunity = [SELECT Id, AccountId, PlanificacionComercial__c FROM Opportunity WHERE Name = 'Opportunity Original' LIMIT 1];
    proforma = [SELECT Id, Cuenta__c FROM Proforma__c LIMIT 1];
    clienteContacto = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ClienteContacto' LIMIT 1];
    pc = [SELECT Id FROM PlanificacionComercial__c LIMIT 1];
    
    DOBrandsDAO.getProformas(proforma.Id, clienteContacto.Id, pc.Id);
    
    DOBrandsDAO.getProformas(new List<String>{proforma.Id});
    
    DOBrandsDAO.getOpportunityLineItems(
        new List<String>{opportunity.Id}, 
        new List<String>{'dummy'}
    );
    
    DOBrandsDAO.getDocumentosProforma(new List<String>{proforma.Id});
    
    RecordType rt = DOBrandsDAO.getRecordType('Proveedor', 'Account');
    DOBrandsDAO.getProviderByTokenVerificacion('12345', rt);
    
    DOBrandsDAO.getCatalogoByToken('dummy');
    
    DOBrandsDAO.getProductsByFamSubFamClasses('H', '1', new List<String>{'02-Air Cooler'});
    
    List<String> prodIds = new List<String>();
    for(Product2 p : [SELECT Id FROM Product2 WHERE RecordType.DeveloperName = 'ProductoDeFabrica' LIMIT 3]) {
        prodIds.add(p.Id);
    }
    DOBrandsDAO.getMapProductsPriceBook(prodIds, 'Key Account', 'USD');
    
    DOBrandsDAO.getListaPrecios('Key Account');
    
    DOBrandsDAO.getPlanificacion(String.valueOf(Date.today().year()), clienteContacto.Id);
}
}