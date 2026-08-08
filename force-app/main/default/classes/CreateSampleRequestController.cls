/**
*   Handles the logic for CreateSampleRequest page
*   @version 1.0
*   @author lcosta@infolastic.com
*/
public class CreateSampleRequestController {
    public Solicitud_de_Muestra__c sampleRequest {get;set;}
    public list<Sample> samples {get;set;}
    public String samplesopp {get;set;}
    public String samplesClient {get;set;}
    public static final String SAMPLE_NUM = 'Esta es la {0} solicitud de muestra para esta <b> opp </b>';
    public static final String SAMPLE_CLIENT = 'Esta es la {0} solicitud de muestra para el cliente <b> {1} </b>';
    public static final String CLIENT = 'Client';
    public static final String oppTY = 'opp';
    private Opportunity opp;
    public boolean success {get;set;}
    private static final String CONFIRM_MSG = 'Se ha enviado la solicitud con exito';
    private static final String TYPE_ERR = 'Debe especificar el tipo de Muestra';

    //seguimiento muestra
    public List<MuestraNoProducto> muestrasNP {get; set;}    
	public static final String SAMPLE_FOLDER = 'samples';
    public String messageHeaderMuestra {get;set;}

    //public transient Blob mitestblob {get;set;}
    
    public CreateSampleRequestController(ApexPages.StandardController std) {
        opp = (Opportunity)std.getRecord();
        opp = [SELECT Id,
                      Name,
                      AccountId,
                      Account.Name
                 FROM Opportunity
                WHERE Id = :opp.Id];
        sampleRequest = new Solicitud_de_Muestra__c(Oportunidad__c = opp.Id);
        samples = createSamplesForOLI(opp.Id);
        samplesopp = genMessage(SAMPLE_NUM, oppTY);
        samplesClient = genMessage(SAMPLE_CLIENT, CLIENT);
        messageHeaderMuestra = 'Muestras sin producto';

        createsMuestrasNoproducto();

        success = false;
    }
    
    /**
    *   Creates the initial list of Samples including one for each Opportunity Line Item (none selected)
    */
    public list<Sample> createSamplesForOLI(ID oppId){
        list<Sample> samples = new list<Sample>();
        for(OpportunityLineItem oli : [SELECT Product2Id,
                                            Product2.ProductoBase__r.IDImagen1__c,
                                            Product2.CodigoDeProductoBase__c,
                                            Product2.Descripcion_Larga__c
                                            FROM OpportunityLineItem
                                            WHERE OpportunityId = :oppId]){
            samples.add(new Sample(oli.Product2.ProductoBase__r.IDImagen1__c, oli.Product2.CodigoDeProductoBase__c,
                                            oli.Product2Id, sampleRequest.Id, oli.Product2.Descripcion_Larga__c));
        }
        return samples;
    }
    
    public void createsMuestrasNoproducto() {
        MuestraNoProducto base;
        muestrasNP = new List<MuestraNoProducto>();
        base = new MuestraNoProducto();
        muestrasNP.add(base);
    }
    
    public PageReference insertSampleRequest(){
        Savepoint sp = Database.setSavepoint();
        try{
            insert sampleRequest;
            insertSelectedSamples();
            insertSelectedMuestrasNP();
        }catch(DMLException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDMLMessage(0)));
            sampleRequest.Id = null;
            Database.rollback(sp);
            return null;
        }catch(SampleTypeException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, TYPE_ERR));
            sampleRequest.Id = null;
            Database.rollback(sp);
            return null;
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, CONFIRM_MSG));
        success = true;
        return null;
    }


    public void addMuestraNP() {
        MuestraNoProducto newMuestra;
        newMuestra = new MuestraNoProducto();
        muestrasNP.add(newMuestra);
    }


    public void insertSelectedSamples(){
        list<Muestra__c> newSamples = new list<Muestra__c>();
        boolean hasError = false;
        for (Sample s : samples){
            if(s.selected){
                if(s.selectedType == 'N/A'){
                    hasError = true;
                    s.errorMessage = TYPE_ERR;
                    s.classSelectedType = 'error';
                }else{
                    s.sample.Tipo__c = s.selectedType;
                    s.sample.Solicitud_de_Muestra__c = sampleRequest.Id;
                    s.errorMessage = null;
                    s.classSelectedType = '';
                    newSamples.add(s.sample);
                }
            }
        }
        if(hasError){
            throw new SampleTypeException('Tipo de muestra');    
        }
        insert newSamples;
    }
    

    public void insertSelectedMuestrasNP() {
        List<Muestra__c> muestrasNPToInsert = new List<Muestra__c>();
        List<MuestraNoProducto> validMuestrasNP = new List<MuestraNoProducto>();
        List<Document> docsToInsert = new List<Document>();
        transient Document auxDoc;        
        Muestra__c auxMuestra;
        boolean hasError = false;
        String docName;
        Id sampleFolderId = [SELECT Id
                                FROM Folder
                                WHERE DeveloperName = :SAMPLE_FOLDER].Id;
        for (MuestraNoProducto mnp : muestrasNP){
            if(mnp.selected) {
                if(mnp.tipoMuestra == 'N/A') {
                    hasError = true;
                } else {

                     docName = 'Sample-' + opp.Name;
                     docName = docName.replace(' ', '');
                     auxdoc = new Document(name = docName,
                                           body = mnp.fileBody,
					                       folderId = sampleFolderId);
                     mnp.doc = auxdoc;
                     docsToInsert.add(mnp.doc);

                     auxMuestra = new Muestra__c(Descripcion__c = mnp.descripcionMuestra, 
                                                 Cantidad__c = mnp.cantidadMuestra,
                                                 Tipo__c = mnp.tipoMuestra,
                                                 Solicitud_de_Muestra__c = sampleRequest.Id);
                     mnp.muestraNP = auxMuestra;
                     validMuestrasNP.add(mnp);                     
                }
            }
        }
        if(hasError) {
            throw new SampleTypeException('Tipo de muestra');    
        }
        insert docsToInsert;

        for(MuestraNoProducto vmnp : validMuestrasNP) {
            vmnp.muestraNP.Imagen_Muestra__c = vmnp.doc.Id;
            muestrasNPToInsert.add(vmnp.muestraNP);
        }
        insert muestrasNPToInsert;
    }


    /**
    *   Generates a message based on a template and a parameter indicating wether it is a Client or an Opportunity
    */
    public String genMessage(String template, String what){
        list<AggregateResult> ar; 
        
        if(what == oppTY){
            ar = [SELECT COUNT(Id) num
                    FROM Solicitud_de_Muestra__c
                    WHERE Oportunidad__c = :opp.Id];
        }else{
            ar = [SELECT COUNT(Id) num
                    FROM Solicitud_de_Muestra__c
                    WHERE Oportunidad__r.AccountId = :opp.AccountId];
        }
        Integer total = 0;
        String position = 'primera';
        if(!ar.isEmpty()){
            total = (Integer)ar[0].get('num');
            if(total == 0){
                position = 'primera';
            }if(total == 1){
                position = 'segunda';
            }else if(total == 2){
                position = 'tercera';
            }else{
                position = total + 1 + 'a';
            }
        }   
        return template.replace('{0}', '<b>' + position + '</b>').replace('{1}', opp.Account.Name);
    }
    
    public class Sample{
        public boolean selected {get;set;}
        public Muestra__c sample {get;set;}
        public String descProd {get;set;}
        public list<SelectOption> sampleType {get;set;}
        public String selectedType {get;set;}
        public String classSelectedType {get;set;}
        public String errorMessage {get;set;}
        public String imageId {get;set;}
        public String pCode {get;set;}

        public Sample(String imgId, String basePCode, ID productId, ID requestId, String dProd){
            sample = new Muestra__c(producto__c = productId,
                                    Solicitud_de_Muestra__c = requestId);
            sampleType = new list<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Muestra__c.Tipo__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            sampleType.add(new SelectOption('N/A', '--Elegir--'));
            for( Schema.PicklistEntry pickListVal : ple){
                sampleType.add(new SelectOption(pickListVal.getLabel(), pickListVal.getLabel()));
            }
            descProd = dProd;
            imageId = imgId;
            pCode = basePCode;
        }
    }

    public class MuestraNoProducto {
        public transient Document doc {get;set;}
        public Boolean selected {get;set;}
        public String tipoMuestra {get;set;}
        public String cantidadMuestra {get;set;}
        public String descripcionMuestra {get;set;}
        public transient Blob fileBody {get;set;}
        public String fileName {get;set;}
        public Muestra__c muestraNP {get;set;}
        public List<SelectOption> tiposOptions {get;set;}
        public List<SelectOption> cantidadesOptions {get;set;}        

        public MuestraNoProducto() {
            tiposOptions = DOBrandsDAO.getSelectOptions(Schema.Muestra__c.Tipo__c);
            tiposOptions.add(0, new SelectOption('N/A', '--Elegir--'));

            cantidadesOptions  = DOBrandsDAO.getSelectOptions(Schema.Muestra__c.Cantidad__c);
            selected = false;
        }
    }

    public class SampleTypeException extends Exception{}

}