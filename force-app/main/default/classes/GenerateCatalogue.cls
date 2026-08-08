/**
 *  Controller for the page of the same name which generates an instance of Catalogo__c for a particular Account
 * 
 */
public class GenerateCatalogue {
    public static final String SYSTEM_FAM = '0-SYSTEM';

    public static final String CATALOGUE_PAGE = 'CatalogueIndex';
    public static final String CUSTOMER_PORTAL = 'portal';
    public static final String TEST_PORTAL = 'Desarrollo';
    public static final String OPP_NAME_ERROR = 'Debe proporcionar un nombre para la oportunidad';
    public static final String NO_PLAN_ERROR = 'La cuenta para la que intenta generar catalogo, no tiene planificación para el año.'
                                                + ' Por favor solicite a gerencia que la cree y vuelva a intentarlo.';
    public Id accountId {get;set;}

    public List<CategoryItem> fams {get;set;}
    public List<CategoryItem> subFams {get;set;}
    public List<CategoryItem> classes {get;set;}

    public enum Category {INI, FAM, SUB, CLA, FIN}
    public Category currentCat {get;set;}
    
    public String oppName {get;set;}
    public Integer totalProds {get;set;}
    public Boolean isGenerated {get;set;}
    public String catURL {get;set;}
    
    private Map<String, List<String>> famToSubs;
    private Map<String, List<String>> subFamToClasses;

    

    /**
     * Fetches Product Families, Subfamilies and Classes
     * Excludes "0-SYSTEM"
     */
    public GenerateCatalogue(ApexPages.StandardController std) {
        accountId = std.getId();
        
        if(DOBrandsDAO.getPlanificacion(String.valueOf(Date.today().year()), accountId) != null) {

            famToSubs = Util.getFieldDependencies('Product2', 'Family', 'Subfamilia__c');
            subFamToClasses = Util.getFieldDependencies('Product2', 'Subfamilia__c', 'Clase__c');
            fams = new List<CategoryItem>();
            for(String f : famToSubs.keySet()) {
                if(f != SYSTEM_FAM) {
                    fams.add(new CategoryItem(f, null));
                }
            }
            currentCat = Category.INI;
            subFams = new List<CategoryItem>();
            classes = new List<CategoryItem>();
        } else {
            currentCat = null;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, NO_PLAN_ERROR));
        }
    }

    /**
     * Builds the list of category items for the next step of the wizzard based on the current selection
     */
    public void forward() {
        if(currentCat == Category.INI) {
            if(oppName == null || oppName == '') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, OPP_NAME_ERROR));
            } else {
                currentCat = Category.FAM;
            }
        } else if(currentCat == Category.FAM) {
            subFams.clear();
            for(CategoryItem famItem : fams) {
                if(famItem.isSelected) {
                    for(String sub : famToSubs.get(famItem.fullName)) {
                        subFams.add(new CategoryItem(sub, famItem));
                    }
                }
            }
            currentCat = Category.SUB;
        } else if(currentCat == Category.SUB) {
            classes.clear();
            for(CategoryItem subItem : subFams) {
                if(subItem.isSelected) {
                    for(String cla : subFamToClasses.get(subItem.fullName)) {
                        classes.add(new CategoryItem(cla, subItem));
                    }
                }
            }
            currentCat = Category.CLA;
        }
    }

    /**
     * Returns to previous step of the wizzard
     */
    public void back() {
        if(currentCat == Category.FAM) {
            currentCat = Category.INI;
        } else if(currentCat == Category.SUB) {
            currentCat = Category.FAM;
        } else if(currentCat == Category.CLA) {
            currentCat = Category.SUB;
        }
    }

    /**
     * Generates a token and persists the catalog to the DB.
     * After its execution, it displays a message to the user with the link to the catalogue
     * 
     */
    public void saveCatalogue() {
        system.debug('SAVE ACTION');
        String token = Util.generateToken();
        String famStr = '';
        String claStr = '';
        List<String> classList = new List<String>();
        List<String> allSelectedClasses = new List<String>();
        Map<String, Boolean> classHasProds = new Map<String, Boolean>();

        for(CategoryItem fam : fams) {
            famStr += fam.fullCode + ',';
        }
        famStr = famStr.removeEnd(',');

        //exclude classes with no Products
        for(CategoryItem cla : classes) {
            if(cla.isSelected) {
                system.debug('Selected Clases: ' + cla.fullName);
                allSelectedClasses.add(cla.fullName);
            }
        }
        for(AggregateResult ar : [SELECT ProductoBase__r.Clase__c pc
                                    FROM Product2 
                                    WHERE isActive = true
                                    GROUP BY ProductoBase__r.Clase__c]) {
            system.debug('Adding the class to the map: ' + (String)ar.get('pc'));
            classHasProds.put((String)ar.get('pc'), true);
        }
        
        for(CategoryItem cla : classes) {
            if(cla.isSelected && classHasProds.containsKey(cla.fullName)) {
                claStr += cla.fullCode + ',';
                classList.add(cla.fullName);
            }
        }
        claStr = claStr.removeEnd(',');

        Catalogo__c catalogue = new Catalogo__c(Name = oppName,
                                                Cliente__c = accountId,
                                                Portal_Token__c = token,
                                                Familias__c = famStr,
                                                Clases__c = claStr);
        insert catalogue;
        
        //Save token for Customer Account
        Account updClient = new Account(Id = accountId,
                                        Portal_Token__c = token);
        update updClient;

        AggregateResult prods = [SELECT COUNT(Id) nmbr
                                        FROM Product2
                                        WHERE Clase__c IN :classList
                                        AND RecordType.DeveloperName = :ProductTriggerHelper.PRODUCTO_BASE_RT];
        totalProds = (Integer)prods.get('nmbr');
        isGenerated = true;
        currentCat = Category.FIN;
        String cPortal = Test.isRunningTest() ? TEST_PORTAL : CUSTOMER_PORTAL;
        catURL = DOBrandsDAO.getPortalCS(cPortal).URL_Portal__c + '/' + CATALOGUE_PAGE + '?dbrToken=' + token;

    }

    
    /**
     * Goes back to the Account detail page
     */
    public PageReference finish() {
        return new PageReference('/' + accountId);
    }

    
    public Boolean getOppNameStep() {
        return currentCat == Category.INI;
    }

    public Boolean getFamSelectionStep() {
        return currentCat == Category.FAM;
    }

    public Boolean getSubSelectionStep() {
        return currentCat == Category.SUB;
    }

    public Boolean getClaSelectionStep() {
        return currentCat == Category.CLA;
    }

    public Boolean getNoPlan() {
        return currentCat == null;
    }
    /**
     * Represents a single product family, subfamily or class and weather or not it is selected.
     * Assumption: A family, subfamily or class fullName has the form "code-name"
     */
    public class CategoryItem {
        public String name {get;set;}
        public String code {get;set;}
        private String fullName {get;set;}
        private String fullCode {get;set;}
        public Boolean isSelected {get;set;}
        public CategoryItem parent {get;set;}

        /**
         * Creates the Category Item spliting its fullName by "-" to form code and name
         * If parent is not null, concatenates parent fullCode to its own code to generate fullCode
         * isSelected is set to true
         */
        public CategoryItem(String fullName, CategoryItem parent) {
            this.fullName = fullName;
            try{
                code = fullName.split('-')[0];
                name = fullName.split('-')[1];
            }catch(Exception e){
                code = fullName.split('-')[0];
                name = fullName.split('-')[0];
            }
            fullCode = code;
            this.parent = parent;
            if(parent != null) {
                fullCode = parent.fullCode + code;
            }
            isSelected = true;
        }
    }
}