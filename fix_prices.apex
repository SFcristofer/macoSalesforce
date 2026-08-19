List<PricebookEntry> pbes = [SELECT Id, Pricebook2.Margen__c, Product2.CostoTotal2__c, Product2.ProductoBase__c, UnitPrice 
                             FROM PricebookEntry 
                             WHERE UnitPrice = 1 AND Product2.RecordType.DeveloperName = 'ProductoDeFabrica' AND IsActive = true];

Set<Id> baseProdIds = new Set<Id>();
for (PricebookEntry pbe : pbes) {
    if (pbe.Product2.ProductoBase__c != null) {
        baseProdIds.add(pbe.Product2.ProductoBase__c);
    }
}

Map<Id, EscandalloLineItem__c> baseToEscItem = new Map<Id, EscandalloLineItem__c>();
for (EscandalloLineItem__c eli : [SELECT Id, Producto__c, Porcentaje_Oficina_GS__c FROM EscandalloLineItem__c WHERE Producto__c IN :baseProdIds]) {
    baseToEscItem.put(eli.Producto__c, eli);
}

List<PricebookEntry> pbesToUpdate = new List<PricebookEntry>();
Map<Id, Decimal> pbeIdToNewPrice = new Map<Id, Decimal>();

for (PricebookEntry pbe : pbes) {
    if (pbe.Pricebook2.Margen__c != null && pbe.Pricebook2.Margen__c > 0) {
        EscandalloLineItem__c escItem = baseToEscItem.get(pbe.Product2.ProductoBase__c);
        
        Decimal costoTotal = pbe.Product2.CostoTotal2__c != null ? pbe.Product2.CostoTotal2__c : 0;
        Decimal oficinaGS = (escItem != null && escItem.Porcentaje_Oficina_GS__c != null) ? escItem.Porcentaje_Oficina_GS__c : 0;
        Decimal margen = pbe.Pricebook2.Margen__c / 100;
        
        Decimal divisor = 1 - (margen + (oficinaGS / 100));
        if (divisor != 0) {
            Decimal nuevoPrecio = costoTotal / divisor;
            if (pbe.UnitPrice != nuevoPrecio) {
                pbe.UseStandardPrice = false;
                pbe.UnitPrice = nuevoPrecio;
                pbesToUpdate.add(pbe);
                pbeIdToNewPrice.put(pbe.Id, nuevoPrecio);
            }
        }
    }
}

if (!pbesToUpdate.isEmpty()) {
    update pbesToUpdate;
    System.debug('PricebookEntries actualizados: ' + pbesToUpdate.size());
}

// Ahora arreglar las Oportunidades que ya tienen el producto agregado con el precio de 1
List<OpportunityLineItem> olis = [SELECT Id, PricebookEntryId, UnitPrice, IncrementoPorAportaciones__c FROM OpportunityLineItem WHERE UnitPrice = 1 AND PricebookEntryId IN :pbeIdToNewPrice.keySet()];
List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();
for (OpportunityLineItem oli : olis) {
    Decimal realPrice = pbeIdToNewPrice.get(oli.PricebookEntryId);
    Decimal incremento = oli.IncrementoPorAportaciones__c != null ? oli.IncrementoPorAportaciones__c : 0;
    oli.UnitPrice = realPrice + incremento;
    olisToUpdate.add(oli);
}

if (!olisToUpdate.isEmpty()) {
    update olisToUpdate;
    System.debug('OpportunityLineItems arreglados: ' + olisToUpdate.size());
}
