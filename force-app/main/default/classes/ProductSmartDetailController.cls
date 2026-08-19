public with sharing class ProductSmartDetailController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getProductFieldSets() {
        Map<String, List<String>> fsMap = new Map<String, List<String>>();
        try {
            Schema.DescribeSObjectResult describeResult = Product2.sObjectType.getDescribe();
            Map<String, Schema.FieldSet> fieldSetMap = describeResult.fieldSets.getMap();
            
            for (String fsName : fieldSetMap.keySet()) {
                // Solo leemos los Field Sets que inicien con "SmartDetail_"
                if (fsName.startsWithIgnoreCase('SmartDetail_')) {
                    List<String> fields = new List<String>();
                    for (Schema.FieldSetMember fsm : fieldSetMap.get(fsName).getFields()) {
                        fields.add(fsm.getFieldPath());
                    }
                    fsMap.put(fsName.toLowerCase(), fields);
                }
            }
        } catch(Exception e) {
            System.debug('Error ProductSmartDetailController: ' + e.getMessage());
        }
        return fsMap;
    }
}