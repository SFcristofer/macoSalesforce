public class OrderDocuments {

    private static String DOC_BL = 'BL';
    private static String DOC_FACTURA = 'Factura';
    private static String DOC_PACKING_LIST = 'Packing List';

    public PedidoDeCompra__c order {set; get;}
    public Documento__c documentBL {set; get;}
    public Documento__c documentFactura {set; get;}
    public Documento__c documentPackingList {set; get;}

    public Blob documentBLFile {set; get;}
    public Blob documentFacturaFile {set; get;}
    public Blob documentPackingListFile {set; get;}

    public Boolean validBLCondition {set; get;}
    public Boolean validFacturaCondition {set; get;}
    public Boolean validPackingListCondition {set; get;}

    public Boolean previousConditions {set; get;}

    public PackingList__c packingList {set; get;}

    public OrderDocuments(PedidoDeCompra__c porder) {
        order = porder;
        validBLCondition = false;
        validFacturaCondition = false;
        validPackingListCondition = false;
        previousConditions = true;
    }

    public void addBlob(String idCV, ContentVersion cv) {
        if(documentBL != null && documentBL.Archivo_Principal__c.equals(idCV)) {
            documentBLFile = cv.VersionData;
        }
        if(documentFactura != null && documentFactura.Archivo_Principal__c.equals(idCV)) {
            documentFacturaFile = cv.VersionData;
        }
        if(documentPackingList != null && documentPackingList.Archivo_Principal__c.equals(idCV)) {
            documentPackingListFile = cv.VersionData;
        }
    }

    public void validateOrder() {
        if(documentBLFile != null) {
            validBLCondition = true;
        }
        if(documentFacturaFile != null) {
            validFacturaCondition = true;
        }
        if(documentPackingListFile != null) {
            validPackingListCondition = true;
        }
    }

    public Boolean isReadyToSend() {
        return previousConditions && validBLCondition && validFacturaCondition && validPackingListCondition;
    }

    public Boolean isPackingListApproved() {
        if(packingList == null) {
            return false;
        } else {
            if(packingList.Estado__c.equals('Aprobado')) {
                return true;
            }
            return false;
        }
    }

    public void addDocument(Documento__c doc) {
        if(doc.Tipo_de_Documento__c.equals(DOC_BL)) {
            this.documentBL = doc;
        }
        if(doc.Tipo_de_Documento__c.equals(DOC_FACTURA)) {
            this.documentFactura = doc;
        }
        if(doc.Tipo_de_Documento__c.equals(DOC_PACKING_LIST)) {
            this.documentPackingList = doc;
        }
    }

}