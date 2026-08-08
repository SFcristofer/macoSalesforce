public with sharing class ProductNamingService {
    private static final String PROD_BASE_RT_NAME = 'Producto';

    public static void assignCodesBeforeInsert(List<Product2> newList) {
        if (newList == null || newList.isEmpty()) {
            return;
        }

        Map<String, Schema.RecordTypeInfo> rtInfoByDevName =
            Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName();

        Id productoRtId = rtInfoByDevName.containsKey(PROD_BASE_RT_NAME)
            ? rtInfoByDevName.get(PROD_BASE_RT_NAME).getRecordTypeId()
            : null;

        List<Product2> targets = new List<Product2>();

        for (Product2 p : newList) {
            if (productoRtId != null && p.RecordTypeId != productoRtId) {
                continue;
            }

            if (String.isBlank(p.ProductCode)) {
                targets.add(p);
            }
        }

        if (targets.isEmpty()) {
            return;
        }

        ProductCodesGen generator = new ProductCodesGen(targets);
        generator.assignMissingCodes(targets);
    }
}