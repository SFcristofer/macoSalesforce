trigger Product on Product2 (
    before insert,
    after insert,
    before update,
    after update,
    before delete,
    after delete
) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ProductNamingService.assignCodesBeforeInsert(Trigger.new);
    }

    String oper;
    List<Product2> prods;

    if (Trigger.isInsert) {
        prods = Trigger.new;
        oper = ProductTriggerHelper.INS;
    } else if (Trigger.isUpdate) {
        prods = Trigger.new;
        oper = Trigger.isBefore ? ProductTriggerHelper.B4UPD : ProductTriggerHelper.UPD;
    } else if (Trigger.isDelete) {
        prods = Trigger.old;
        oper = Trigger.isBefore ? ProductTriggerHelper.B4DEL : ProductTriggerHelper.DEL;
    }

    if (oper != null && prods != null) {
        ProductTriggerHelper pth = new ProductTriggerHelper(prods, Trigger.oldMap, oper);
        pth.execute();
    }
}