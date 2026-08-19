        Id baseRtId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
        
        Product2 baseProd = new Product2(
            Name = 'Test Base B4DEL',
            RecordTypeId = baseRtId,
            Family = 'B-!DEA Heating & Fan', 
            Subfamilia__c = '1-Fans', 
            Clase__c = '01-Stand & Tower Fans', 
            Marca__c = 'A-!DEA Garden'
        );
        insert baseProd;
        
        Escandallo__c eUnico = [SELECT Id FROM Escandallo__c LIMIT 1];
        insert new EscandalloLineItem__c(
            Escandallo__c = eUnico.Id,
            Producto__c = baseProd.Id,
            PrecioCompraFabrica__c = 1
        );
        
        Map<Id, Product2> mapOldBase = new Map<Id, Product2>{ baseProd.Id => baseProd };
        ProductTriggerHelper helperDel = new ProductTriggerHelper(mapOldBase.values(), mapOldBase, ProductTriggerHelper.B4DEL);
        ProductTriggerHelper.resetRunForTesting();
        try { helperDel.execute(); } catch(Exception e) { System.debug('ERROR IN B4DEL: ' + e.getMessage() + '\n' + e.getStackTraceString()); }
