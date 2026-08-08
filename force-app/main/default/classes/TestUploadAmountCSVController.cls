@isTest
private class TestUploadAmountCSVController {
    @isTest static void testCustomer() {
       TestUtil tu = new TestUtil();
       tu.initPedidoReporteAportacion();

       String dummyCSVFile = 'FechaVencimiento,Cliente,Cliente (Descripcion),Documento,FechaFactura,Importe pendiente EUR,Importe pendiente EUR\n' +
                             '21/10/2016,12345,TIENDAS SORIANA - GENERAL,DAG72,30/03/2016,16495.20,0.00,0.00,\n' +
                             '030/04/2018,222333,KEYTRAL MARTED S.A.,F17/000299-2,30/12/2017,-3589.66,0.00,0.00,\n' +
                             '30/04/2018,00007,KEYTRAL MARTED S.A.,F17/000299-1,30/12/2017,3589.66,0.00,\n' +
                             '31/12/2018,00007,KEYTRAL MARTED S.A.,B17/000011,30/12/2017,-2991.67,0.00,0.00,\n' +
                             '31/12/2018,00007,KEYTRAL MARTED S.A.,F17/000299,30/12/2017,38888.34,0.00,0.00,\n';

       Blob testFile = Blob.valueOf(dummyCSVFile);
       UploadAmountCSVController upld = new UploadAmountCSVController();
       upld.csvFileBody = testFile;
       upld.readCSV();
       upld.saveAmounts();
    }


    @isTest static void testProvider() {
        TestUtil tu = new TestUtil();
        tu.initPedidoReporteAportacion();

        String dummyCSVFile = 'FechaVencimiento,Proveedor,Proveedor (Descripción),Documento,FechaFactura,Importe USD,Div.,Importe Divisa\n' +
                              '30/12/2018,P40171,ANJI BAINA FURNITURE FACTORY,PE18238,30/12/2018,1333.00,0.00,0.00\n' +
                              '15/03/2019,P40171,ANJI BAINA FURNITURE FACTORY,PE19053,15/03/2019,-1785.92,0.00,0.00\n' +
                              '15/03/2019,P40171,ANJI BAINA FURNITURE FACTORY,PE19054A,15/03/2019,-2849.00,0.00,0.00\n' +
                              '15/03/2019,P40171,ANJI BAINA FURNITURE FACTORY,PE19054B,15/03/2019,-3056.00,0.00,0.00\n' +
                              '30/12/2019,P40208,BAZHOU HONGJIANG FURNITURE,HJHY191109B,30/12/2019,1034.20,0.00,0.00\n';
 
        Blob testFile = Blob.valueOf(dummyCSVFile);
        UploadAmountCSVController upld = new UploadAmountCSVController();
        upld.csvFileBody = testFile;
        upld.readCSV();
        upld.saveAmounts();
     }    
 
}