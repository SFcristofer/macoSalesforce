@isTest
private class TestUtilMethods {
    
    @isTest static void testUtilMethods() 
    {
        TestUtil tu = new TestUtil();       
        tu.createCustomSettings(); 

        Util.getIncrement('pedido');
        Util.getIncrement('pedido','2024');
        Util.getIncrement('proforma','2024');        
        System.debug('test increment aportacion');
        Util.getIncrement('aportacion');
        Util.getCSTransferenciaIntervalo();
        Util.getCSCorreosTransferencia();
        system.assertEquals(Util.getMonth(4), 'Abril'); 
        Util.getCSLibraFechaCobrosPagos('CobrosDoCore');

        try 
        {
           Util.convertDateStrToSF(null);
        } 
        catch (Exception e) 
        {
            System.debug('e: ' + e.getMessage());
        }

        try 
        {
           Util.convertDateStrToSF('aaaa');
        } 
        catch (Exception e) 
        {
            System.debug('e: ' + e.getMessage());
        }

        //date format dd/mm/yyyy
        Util.convertDateStrToSF('01/01/2019 00:00:00');

        Util.dobleToWord ('5.4');
        Util.dobleToWord (null);        
        Util.numberToWord(4);
        Util.numberToWord(325678);
        Util.numberToWord(null);
        Util.numberToWord(-1);
        Util.numberToWord(1234567);     
        Map<String, String> testMap = new Map<String, String>();
        testMap.put('test','one');
        String testTable = Util.buildHTMLtable(testMap);
        Util.buildHTMLBody('salute', 'text', true, testTable, 'note', 'goodbyeText');
        Util.getFieldDependencies('Account', 'PaisDelPuerto__c', 'Puerto__c');
        Util.generateToken();
        Util.getCSCorreosTransferencia('test');
    }
    
}