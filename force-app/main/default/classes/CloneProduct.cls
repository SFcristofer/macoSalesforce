/**
*   Controller for CloneProduct page
*   @version    1.0
*   @author lcosta@infolastic.com
 */
public class CloneProduct {
  
    private Product2 originalProduct; 
    private set<String> fieldNames;
    public List<SelectOption> altBrands {get;set;}
    public String newBrand {get;set;}
    public String newColor {get;set;}

    public Boolean modifyBrand{get;set;}
    public Boolean modifyColor{get;set;}

    public static final String COLOR_EMPTY = 'Debe especificar un color';
    public static final String SAME_COLOR = 'Debe especificar un color diferente al original';

    public Boolean newBrandEnabled {get;set;}
    public Boolean newColorEnabled {get;set;}

    public CloneProduct(ApexPages.StandardController std) {
        modifyBrand = false;
        modifyColor = false;
        Map<String, Schema.SObjectField> fieldMap = Product2.sObjectType.getDescribe().fields.getMap();
        fieldNames = fieldMap.keySet();
        List<Product2> pro = Database.query('SELECT ' + String.join((Iterable<String>)fieldNames, ',') 
                                            + ' FROM Product2'
                                            + ' WHERE Id = \'' + std.getId() + '\'');
        originalProduct = pro[0];

        //Setup alternative brand options
        altBrands = new List<SelectOption>();
    Schema.DescribeFieldResult fieldResult = Product2.Marca__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for( Schema.PicklistEntry pickListVal : ple){
      if(pickListVal.getLabel() != originalProduct.Marca__c){
                altBrands.add(new SelectOption(pickListVal.getLabel(), pickListVal.getLabel()));
            }
    }
    
    Clone_Products__c cp = Clone_Products__c.getInstance(); //Configuracion personalizada
    newBrandEnabled = cp.Clone_Brand__c;
    newColorEnabled = cp.Clone_Color__c;
  }

    public PageReference cloneWithFactory() {
        String[] tokens;
        Product2 newClone = originalProduct.clone();
        try{    
            if(modifyBrand){
                newClone.Marca__c = newBrand;
                
                System.debug('new brand [' + newClone.Marca__c + ']');

                System.debug('new pcode orig[' + newClone.ProductCode + ']');
                
                String[] tokensCadena = newClone.ProductCode.split('[0-9]+');
                
                System.debug('size [' + tokensCadena.size() + '] tokensCadena: ' + tokensCadena);
                
                String tokenFinal = tokensCadena[1];
                Integer sizeTokenFinal = tokenFinal.length();
                
                System.debug('sizeTokenFinal [' + sizeTokenFinal + ']');
                
                //newClone.ProductCode = newClone.ProductCode.subString(0, newClone.ProductCode.length() - 1);
                newClone.ProductCode = newClone.ProductCode.subString(0, newClone.ProductCode.length() - sizeTokenFinal);
                
                System.debug('new pcode [' + newClone.ProductCode + ']');
                
                tokens = newBrand.split('-');
                newClone.ProductCode += tokens[0];
                
                System.debug('new pcode new brand [' + newClone.ProductCode + ']');
            }else if(modifyColor){
                if(newColor == null){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, COLOR_EMPTY));
                    return null;
                }else if(newColor == originalProduct.Color__c){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, SAME_COLOR));
                    return null;
                }
                newClone.Color__c = newColor;
                newClone.ProductCode = null;
            }
            
            System.debug('new clone code [' + newClone.ProductCode + ']');
            
            newClone.Codigo_EAN__c = null;
            newClone.Codigo_DUN_14__c = null;
            newClone.Listado_en_Catalogo__c = false;
            insert newClone;

            list<Product2> mainFactory = Database.query('SELECT ' + String.join((Iterable<String>)fieldNames, ',') 
                                                + ' FROM Product2'
                                                + ' WHERE ProductoBase__c = \'' + originalProduct.Id + '\''
                                                + ' AND Estatus__c = \'Principal\''
                                                + ' LIMIT 1');
            if(!mainFactory.isEmpty()){
                Product2 clonedFactory = mainFactory[0].clone();
                clonedFactory.ProductoBase__c = newClone.Id;
                ProductTriggerHelper.resetRunForTesting();
                insert clonedFactory; 
            }
        }catch(DMLException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDMLMessage(0)));
            return null;
        }
        return new PageReference('/lightning/r/Product2/' + newClone.Id + '/view');
    }

    public void setMBrand(){
        modifyBrand = true;
    }
    public void setMColor(){
        modifyColor = true;
    }

}