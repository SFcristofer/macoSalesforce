@isTest
private class TestDocumentoDOTrigger {
    
    /*@TestSetup
    static void makeData(){
        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        proForma = tu.getProforma();
        proForma.ConfirmacionCliente__c = true;
        
        update proForma;
    }*/

    @isTest static void testDifferentInsert() {

        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        test.startTest();        
        proForma = tu.getProforma();
        proForma.ConfirmacionCliente__c = true;
        
        update proForma;
        
        PedidoDeCompra__c p = [SELECT Id
                                FROM PedidoDeCompra__c
                                limit 1];



        Documento__c d1 = new Documento__c(Proceso__c = 'Pedido Fábrica',
                                            Tipo_de_Documento__c = 'Confirmación Proveedor',
                                            PedidoDeCompra__c = p.id);
        insert d1;

        Documento__c d2 = new Documento__c(Proceso__c = 'Pedido Fábrica',
                                            Tipo_de_Documento__c = 'Factura',
                                            PedidoDeCompra__c = p.id);
        insert d2;
        test.stopTest();
    }
    
    @isTest static void testDuplicateInsert() {

        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        test.startTest();
        proForma = tu.getProforma();
        proForma.ConfirmacionCliente__c = true;
        
        update proForma;

        PedidoDeCompra__c p = [SELECT Id
                                FROM PedidoDeCompra__c
                                limit 1];

        Documento__c d1 = new Documento__c(Proceso__c = 'Pedido Fábrica',
                                            Tipo_de_Documento__c = 'Confirmación Proveedor',
                                            PedidoDeCompra__c = p.id);

        insert d1;

        Documento__c d2 = new Documento__c(Proceso__c = 'Pedido Fábrica',
                                            Tipo_de_Documento__c = 'Confirmación Proveedor',
                                            PedidoDeCompra__c = p.id);
        try{
            insert d2;
        }catch(DmlException dml){
            system.assertEquals('Ya se ha subido Confirmación Proveedor para el pedido. Modifique el doc existente de ser necesario', dml.getDmlMessage(0));
        }
        test.stopTest();
    }

    @isTest static void testDuplicateInsertProforma() {

        Proforma__c proForma;
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        test.startTest();        
        proForma = tu.getProforma();
        proForma.ConfirmacionCliente__c = true;
        
        update proForma;

        /*Proforma__c p = [SELECT Id
                                FROM Proforma__c
                                limit 1];*/

        /*RecordType rt = [SELECT Id
                                FROM RecordType
                                WHERE sObjectType = 'Documento__c'
                                AND RecordType.Name = 'Documentación Proforma'
                                limit 1];*/


        Documento__c d1 = new Documento__c(Proceso__c = 'Confirmación',
                                            Tipo_de_Documento__c = 'Proforma Confirmación Cliente',
                                            Proforma__c = proForma.id,
                                            RecordTypeId = '0124w000001BXMh');

        insert d1;

        Documento__c d2 = new Documento__c(Proceso__c = 'Confirmación',
                                            Tipo_de_Documento__c = 'Proforma Confirmación Cliente',
                                            Proforma__c = proForma.id,
                                            RecordTypeId = '0124w000001BXMh');

        try{
            insert d2;
            test.stopTest();
        }catch(DmlException dml){
            system.assertEquals('Ya se ha subido Proforma Confirmación Cliente para la proforma. Modifique el doc existente de ser necesario', dml.getDmlMessage(0));
        }

    }
    
}