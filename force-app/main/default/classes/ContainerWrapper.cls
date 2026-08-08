public class ContainerWrapper {
    public List<Container_Pedido_Line_Item__c> cItems {set; get;}

    public String idContainer {set; get;}
    public String idVw {set; get;}
    
    public String idPedido {get; set;}    
    public String containerNumber {get; set;}    
    public String containerType {get; set;}
    public String containerSEAL {get; set;}

    public List<SelectOption> containerTypeOptions {get; set;}
    public String containerTypeNew {get; set;}
    public Decimal totalProducts {get; set;}
    public Decimal totalCajas {get; set;}
    public Decimal totalNetW {get; set;}
    public Decimal totalGrossW {get; set;}
    public Decimal totalCBM {get; set;}
    
    public Boolean hasLoadCntrDoc {get; set;}
    public String loadCntrDocInfo {get; set;}    
    public String imageNameInfo {get; set;}
    public String imageInfoTooltip {get; set;}    
    
    public ContainerWrapper(Container__c container) {
        cItems = container.Container_Pedido_Line_Items1__r;
        idContainer = container.Id;
        idPedido = container.Pedido__c;
        containerNumber = container.Name;
        containerType = container.Type__c;
        containerSEAL = container.SEAL__c;
        totalProducts = container.Total_Productos__c;
        totalCajas = container.Cajas__c;
        totalNetW = container.Total_Net_W__c;
        totalGrossW = container.Total_Gross_W__c;
        totalCBM = container.Total_CBM__c;
        
        hasLoadCntrDoc = false;
        loadCntrDocInfo = '-';
        imageNameInfo = 'cross-small-red.png';
        imageInfoTooltip = 'Missing Report';
    }
    
}