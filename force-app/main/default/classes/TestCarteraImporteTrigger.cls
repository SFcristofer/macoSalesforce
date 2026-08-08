@isTest
public class TestCarteraImporteTrigger {

    @isTest static void testCarteraImporte() {
        Account parent;
        TestUtil tu = new TestUtil();
        tu.initPedidoReporteAportacion();
 
        String dummyCSVFile = 'Fecha Vencimiento,Cliente,Cliente (Descripcion),Documento,FechaFactura,Importe pendiente EUR,Importe pendiente USD\r\n' +
                              '21/10/2016,12345,TIENDAS SORIANA - GENERAL,DAG72,30/03/2016,16495.20,500.00\r\n' +
                              '30/04/2018,22233,KEYTRAL MARTED S.A.,F17/000299-2,30/12/2017,-3589.66,500.00\r\n' +
                              '30/04/2018,00007,KEYTRAL MARTED S.A.,F17/000299-1,30/12/2017,3589.66,0.00\r\n' +
                              '31/12/2018,00007,KEYTRAL MARTED S.A.,B17/000011,30/12/2017,-2991.67,0.00\r\n' +
                              '31/12/2018,00007,KEYTRAL MARTED S.A.,F17/000299,30/12/2017,38888.34,0.00\r\n';
 
        Blob testFile = Blob.valueOf(dummyCSVFile);
        UploadAmountCSVController upld = new UploadAmountCSVController();
        upld.csvFileBody = testFile;
        upld.readCSV();
        upld.saveAmounts();


        parent = [SELECT Name, Credito_autorizado__c, Balance_Cuenta__c FROM Account WHERE Codigo_rapido__c = '22233'];
        //System.assert(parent.Balance_Cuenta__c == 4500);
	}

}