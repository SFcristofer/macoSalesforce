List<PricebookEntry> pbes = [SELECT Id, Pricebook2.Margen__c, Product2.CostoTotal2__c, Product2.ProductoBase__c, UnitPrice FROM PricebookEntry WHERE UnitPrice = 1 AND Product2.RecordType.DeveloperName = 'ProductoDeFabrica' AND IsActive = true];

Set<Id> baseProdIds = new Set<Id>();
for (PricebookEntry pbe : pbes) {
    if (pbe.Product2.ProductoBase__c != null) {
        baseProdIds.add(pbe.Product2.ProductoBase__c);
    }
}
System.debug('baseProdIds size: ' + baseProdIds.size());

Map<Id, EscandalloLineItem__c> baseToEscItem = new Map<Id, EscandalloLineItem__c>();
for (EscandalloLineItem__c eli : [SELECT Id, Producto__c, Porcentaje_Oficina_GS__c FROM EscandalloLineItem__c WHERE Producto__c IN :baseProdIds]) {
    baseToEscItem.put(eli.Producto__c, eli);
}
System.debug('baseToEscItem size: ' + baseToEscItem.size());

List<PricebookEntry> pbesToUpdate = new List<PricebookEntry>();
for (PricebookEntry pbe : pbes) {
    if (pbe.Pricebook2.Margen__c != null && pbe.Pricebook2.Margen__c > 0) {
        EscandalloLineItem__c escItem = baseToEscItem.get(pbe.Product2.ProductoBase__c);
        
        Decimal costoTotal = pbe.Product2.CostoTotal2__c != null ? pbe.Product2.CostoTotal2__c : 0;
        Decimal oficinaGS = (escItem != null && escItem.Porcentaje_Oficina_GS__c != null) ? escItem.Porcentaje_Oficina_GS__c : 0;
        Decimal margen = pbe.Pricebook2.Margen__c / 100;
        
        Decimal divisor = 1 - (margen + (oficinaGS / 100));
        System.debug('costoTotal: ' + costoTotal + ', oficinaGS: ' + oficinaGS + ', margen: ' + margen + ', divisor: ' + divisor);
        if (divisor != 0) {
            Decimal nuevoPrecio = costoTotal / divisor;
            System.debug('nuevoPrecio: ' + nuevoPrecio);
            if (pbe.UnitPrice != nuevoPrecio) {
                pbesToUpdate.add(pbe);
            }
        }
    }
}
System.debug('To update: ' + pbesToUpdate.size());
