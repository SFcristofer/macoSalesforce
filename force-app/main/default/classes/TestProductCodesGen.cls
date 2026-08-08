@isTest
public class TestProductCodesGen {
  
  // Helper method para obtener valores válidos de picklist
  private static Map<String, String> getValidPicklistValues() {
    Map<String, String> values = new Map<String, String>();
    
    // Buscar valores activos de Family
    Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for(Schema.PicklistEntry entry : ple) {
      if(entry.isActive()) {
        String label = entry.getLabel();
        if(label.containsIgnoreCase('HOME')) {
          values.put('familyHome', label);
        }
        if(label.containsIgnoreCase('GARDEN')) {
          values.put('familyGarden', label);
        }
        if(label.containsIgnoreCase('HEATING')) {
          values.put('familyHeating', label);
        }
      }
    }
    
    // Buscar valores activos de Marca
    fieldResult = Product2.Marca__c.getDescribe();
    ple = fieldResult.getPicklistValues();
    for(Schema.PicklistEntry entry : ple) {
      if(entry.isActive()) {
        String label = entry.getLabel();
        if(label.containsIgnoreCase('GARDEN')) {
          values.put('marcaGarden', label);
        }
        if(label.containsIgnoreCase('HOME')) {
          values.put('marcaHome', label);
        }
        if(label.containsIgnoreCase('HEATING')) {
          values.put('marcaHeating', label);
        }
      }
    }
    
    return values;
  }
  
  @isTest
  public static void TestProductCodesGen() {
    Map<String, String> picklistValues = getValidPicklistValues();
    
    Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
    
    TestUtil tu = new TestUtil();
    tu.initTestData();

    Test.startTest();
    List<Product2> lp = new List<Product2>();
    
    Product2 p1 = new Product2(
      RecordTypeId = idRT,
      Name = 'Mesa DOGarden',
      Family = picklistValues.get('familyGarden'),
      Subfamilia__c = '1-Outdoor Furniture',
      Clase__c = '01-Outdoor Dining Sets',
      Marca__c = picklistValues.get('marcaGarden'),
      UnidadesHQ__c = 1200
    );
    lp.add(p1);
    
    Product2 p2 = new Product2(
      RecordTypeId = idRT,
      Name = 'Calentador DO Home',
      Family = picklistValues.get('familyHeating'),
      Subfamilia__c = '2-Indoor Heaters',
      Clase__c = '01-Ceramic & Fans Heaters',
      Marca__c = picklistValues.get('marcaHeating'),
      UnidadesHQ__c = 200
    );
    lp.add(p2);
    
    ProductTriggerHelper.resetRunForTesting();
    System.debug('Insert Additional products');
    insert lp;
    
    for (Product2 p : tu.getAllPBUpdated()){
      System.debug('Prod DO Code: ' + p.Name + ' ' + p.ProductCode + ' ' + p.Codigo_EAN__c);
    }
    
    p1 = tu.getPBUpdated(p1.Id);
    System.debug('prod code [' + p1.ProductCode + ']');
    System.debug('Codigo_EAN__c [' + p1.Codigo_EAN__c + ']');
    if(p1.Codigo_DUN_14__c != null) {
      System.debug('Codigo_DUN_14__c [' + p1.Codigo_DUN_14__c.subString(0,13) + ']');
    } else {
      System.debug('Codigo_DUN_14__c is null');
    }
    
    System.assertNotEquals(null, p1.ProductCode, 'ProductCode no debe ser null');

    p2 = tu.getPBUpdated(p2.Id);
    System.debug('p2 ProductCode [' + p2.ProductCode + ']');
    System.debug('p2 Codigo_EAN__c [' + p2.Codigo_EAN__c + ']');
    System.debug('p2 Codigo_DUN_14__c [' + p2.Codigo_DUN_14__c + ']');
    
    System.assertNotEquals(null, p2.ProductCode, 'ProductCode no debe ser null');

    Test.stopTest();
  }

  @isTest
  public static void TestPreSetProductCode() {
    Map<String, String> picklistValues = getValidPicklistValues();
    
    Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
    
    TestUtil tu = new TestUtil();
    tu.initTestData();

    Test.startTest();
    List<Product2> lp = new List<Product2>();
    
    Product2 p1 = new Product2(
      RecordTypeId = idRT,
      Name = 'Mesa DOGarden',
      Family = picklistValues.get('familyGarden'),
      Subfamilia__c = '1-Outdoor Furniture',
      Clase__c = '01-Outdoor Dining Sets',
      Marca__c = picklistValues.get('marcaGarden'),
      ProductCode = '8MAT300A',
      Codigo_EAN__c = '1234567890123',
      UnidadesHQ__c = 1200
    );
    lp.add(p1);
    
    ProductTriggerHelper.resetRunForTesting();
    insert lp;
    
    p1 = tu.getPBUpdated(p1.Id);
    System.debug('p1 ProductCode [' + p1.ProductCode + ']');
    System.debug('p1 Codigo_EAN__c [' + p1.Codigo_EAN__c + ']');
    
    System.assertEquals('8MAT300A', p1.ProductCode, 'ProductCode debe mantenerse como fue establecido');
    
    if(p1.Codigo_EAN__c != null && p1.Codigo_EAN__c.length() >= 12) {
      System.assertEquals('123456789012', p1.Codigo_EAN__c.subString(0,12), 'EAN debe mantenerse como fue establecido');
    }
    
    Test.stopTest();
  }

  @isTest
  public static void TestDiffBrandSameCounter() {
    Map<String, String> picklistValues = getValidPicklistValues();
    
    Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
    
    TestUtil tu = new TestUtil();
    tu.initTestData();

    Test.startTest();
    List<Product2> lp = new List<Product2>();
    
    Product2 p1 = new Product2(
      RecordTypeId = idRT,
      Name = 'Mesa Comedor 1',
      Family = picklistValues.get('familyHome'),
      Subfamilia__c = '2-Kitchen & Dining Furniture',
      Clase__c = '02-Dining Tables',
      Marca__c = picklistValues.get('marcaHome'),
      UnidadesHQ__c = 200
    );
    lp.add(p1);
    
    Product2 p2 = new Product2(
      RecordTypeId = idRT,
      Name = 'Mesa Comedor 2',
      Family = picklistValues.get('familyHome'),
      Subfamilia__c = '2-Kitchen & Dining Furniture',
      Clase__c = '02-Dining Tables',
      Marca__c = picklistValues.get('marcaGarden'),
      UnidadesHQ__c = 200
    );
    lp.add(p2);
    
    ProductTriggerHelper.resetRunForTesting();
    System.debug('Insert Additional products');
    insert lp;
    
    for (Product2 p : tu.getAllPBUpdated()){
      System.debug('Prod DO Code: ' + p.Name + ' ' + p.ProductCode + ' ' + p.Codigo_EAN__c);
    }
    
    p1 = tu.getPBUpdated(p1.Id);
    System.debug('p1 ProductCode [' + p1.ProductCode + ']');
    System.debug('p1 Codigo_EAN__c [' + p1.Codigo_EAN__c + ']');
    System.debug('p1 Codigo_DUN_14__c [' + p1.Codigo_DUN_14__c + ']');
    
    System.assertNotEquals(null, p1.ProductCode, 'ProductCode no debe ser null');

    p2 = tu.getPBUpdated(p2.Id);
    System.debug('p2 ProductCode [' + p2.ProductCode + ']');
    System.debug('p2 Codigo_EAN__c [' + p2.Codigo_EAN__c + ']');
    System.debug('p2 Codigo_DUN_14__c [' + p2.Codigo_DUN_14__c + ']');
    
    System.assertNotEquals(null, p2.ProductCode, 'ProductCode no debe ser null');

    Test.stopTest();
  }
  
  @isTest
  public static void TestEdgeCases() {
      Map<String, String> picklistValues = getValidPicklistValues();
      Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();

      TestUtil tu = new TestUtil();
      tu.initTestData();

      Test.startTest();

      ProductCodesGen pcg = new ProductCodesGen();

      // 1) Producto incompleto: AHORA debe lanzar excepción, ya no generar PORT
      Product2 pIncompleto = new Product2(
          RecordTypeId = idRT,
          Name = 'Test Incompleto',
          Family = null,
          Subfamilia__c = null,
          Clase__c = null,
          Marca__c = null
      );

      try {
          pcg.genCodigoDO(pIncompleto);
          System.assert(false, 'Debe lanzar excepción cuando faltan Family, Subfamilia__c y Clase__c');
      } catch (IllegalArgumentException ex) {
          System.assert(
              ex.getMessage().contains('No se puede generar el ProductCode'),
              'Debe indicar que Family, Subfamilia__c y Clase__c son obligatorios'
          );
      }

      // 2) Marca sin guion: AHORA es válida y debe generar código
      Product2 pMarcaSinGuion = new Product2(
          RecordTypeId = idRT,
          Name = 'Test Marca Sin Guion',
          Family = picklistValues.get('familyGarden'),
          Subfamilia__c = '2-Outdoor Shades & Structures',
          Clase__c = '03-Awnings',
          Marca__c = 'SinGuion'
      );

      String codigoMarcaSinGuion = pcg.genCodigoDO(pMarcaSinGuion);
      System.assertNotEquals(null, codigoMarcaSinGuion, 'Debe generar código con marca sin guion');
      System.assert(
          codigoMarcaSinGuion.endsWith('SINGUION'.toUpperCase()),
          'El código debe terminar con el valor completo de la marca cuando no tiene guion'
      );

      // 3) Marca con guion pero vacía: debe lanzar excepción
      Product2 pMarcaVacia = new Product2(
          RecordTypeId = idRT,
          Name = 'Test Marca Vacia',
          Family = picklistValues.get('familyGarden'),
          Subfamilia__c = '1-Outdoor Furniture',
          Clase__c = '01-Outdoor Dining Sets',
          Marca__c = '-'
      );

      try {
          pcg.genCodigoDO(pMarcaVacia);
          System.assert(false, 'Debe lanzar excepción por marca vacía');
      } catch (IllegalArgumentException ex) {
          System.assert(
              ex.getMessage().contains('Marca__c no tiene un formato válido')
              || ex.getMessage().contains('Valor inválido para nomenclatura'),
              'Debe lanzar excepción por formato inválido de Marca__c'
          );
      }

      // 4) ProductCode corto: no debe afectar la generación si Family/Subfamilia/Clase/Marca son válidos
      Product2 pCodeCorto = new Product2(
          RecordTypeId = idRT,
          Name = 'Test Code Corto',
          Family = picklistValues.get('familyGarden'),
          Subfamilia__c = '2-Outdoor Shades & Structures',
          Clase__c = '03-Awnings',
          Marca__c = picklistValues.get('marcaGarden'),
          ProductCode = 'ABC'
      );

      String codigoNuevo = pcg.genCodigoDO(pCodeCorto);
      System.assertNotEquals(null, codigoNuevo, 'Debe generar código aunque el ProductCode actual sea corto');

      String familyToken = picklistValues.get('familyGarden').split('-')[0].trim().toUpperCase();
      String subfamiliaToken = '2';
      String claseToken = '03';
      String marcaToken = picklistValues.get('marcaGarden').split('-')[0].trim().toUpperCase();

      System.assert(
          codigoNuevo.startsWith(familyToken + subfamiliaToken + claseToken),
          'El código debe iniciar con el prefijo esperado'
      );
      System.assert(
          codigoNuevo.endsWith(marcaToken),
          'El código debe terminar con el token de la marca'
      );

      Test.stopTest();
  }

  @isTest
  public static void TestMultipleEANGeneration() {
    Test.startTest();
    
    ProductCodesGen pcg = new ProductCodesGen();
    
    Set<String> eans = new Set<String>();
    Set<String> duns = new Set<String>();
    
    // Generar múltiples EANs para verificar unicidad
    for(Integer i = 0; i < 10; i++) {
      String ean = pcg.genEAN13();
      eans.add(ean);
      
      String dun = pcg.genDUN14(ean);
      duns.add(dun);
    }
    
    System.assertEquals(10, eans.size(), 'Todos los EANs deben ser únicos');
    System.assertEquals(10, duns.size(), 'Todos los DUNs deben ser únicos');
    
    // Verificar que todos empiezan con el prefijo correcto
    for(String ean : eans) {
      System.assert(ean.startsWith('84355841'), 'EAN debe empezar con prefijo DO');
    }
    
    for(String dun : duns) {
      System.assert(dun.startsWith('184355841'), 'DUN debe empezar con 1 + prefijo EAN');
    }
    
    Test.stopTest();
  }
}