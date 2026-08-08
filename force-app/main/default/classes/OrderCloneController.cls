public class OrderCloneController
{

   private PedidoDeCompra__c orderRecord;
   private String orderId;
   private String orderIdCloned;
 
   public OrderCloneController(ApexPages.StandardController controller)
   {
   
        orderRecord = (PedidoDeCompra__c)controller.getRecord();
        System.debug('Order ID[' + orderRecord.Id + ']' );
        orderId = orderRecord.id;
   }
   
   
   public void cloneOrder()
   {
       PedidoDeCompra__c  clonedOrder;
       OrderPrototype builder = new OrderPrototype(orderRecord.Id);
       clonedOrder = builder.cloneOrder();
       orderIdCloned = clonedOrder.id;
       System.debug('Opp ID cloned [' + orderIdCloned+ ']' );
   }
   
   
   public String getIdOrder()
   {
       return orderId;
   }
   
   public String getIdOrderCloned()
   {
       return orderIdCloned;
   }
   
}