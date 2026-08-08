@isTest
public class TestProductoPedidoCatalogo {
    
    /**
     * Test del constructor por defecto
     */
    @isTest
    static void testConstructor() {
        Test.startTest();
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        Test.stopTest();
        
        System.assertNotEquals(null, producto, 'El producto no debe ser nulo');
        System.assertEquals(null, producto.prodId, 'prodId debe ser nulo por defecto');
        System.assertEquals(null, producto.prodCode, 'prodCode debe ser nulo por defecto');
        System.assertEquals(null, producto.prodName, 'prodName debe ser nulo por defecto');
    }
    
    /**
     * Test de asignación de propiedades
     */
    @isTest
    static void testPropertyAssignment() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        producto.prodId = '001XX000001234';
        producto.prodCode = 'PROD-001';
        producto.prodName = 'Producto Test';
        producto.prodFamPrefix = 'A';
        producto.prodSfmPrefix = 'B';
        producto.prodClaPrefix = 'C1';
        producto.prodMeasures = '10x20x30';
        producto.prodImageId = '015XX000001234';
        producto.prodColor = 'Azul';
        producto.prodMaterial = 'Acero Inoxidable';
        producto.comments = 'Comentario de prueba';
        Test.stopTest();
        
        System.assertEquals('001XX000001234', producto.prodId);
        System.assertEquals('PROD-001', producto.prodCode);
        System.assertEquals('Producto Test', producto.prodName);
        System.assertEquals('A', producto.prodFamPrefix);
        System.assertEquals('B', producto.prodSfmPrefix);
        System.assertEquals('C1', producto.prodClaPrefix);
        System.assertEquals('10x20x30', producto.prodMeasures);
        System.assertEquals('015XX000001234', producto.prodImageId);
        System.assertEquals('Azul', producto.prodColor);
        System.assertEquals('Acero Inoxidable', producto.prodMaterial);
        System.assertEquals('Comentario de prueba', producto.comments);
    }
    
    /**
     * Test setDefaultPackaging con valor null - debe asignar BROWN
     */
    @isTest
    static void testSetDefaultPackagingNull() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        producto.setDefaultPackaging(null);
        Test.stopTest();
        
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.prodPackaging, 
                           'Con null debe asignar brown box');
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.selectedPackaging, 
                           'Con null debe seleccionar brown box');
    }
    
    /**
     * Test setDefaultPackaging con prefijo '1-' - debe asignar BROWN
     */
    @isTest
    static void testSetDefaultPackagingPrefix1() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        producto.setDefaultPackaging('1-Standard');
        Test.stopTest();
        
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.prodPackaging, 
                           'Con prefijo 1- debe asignar brown box');
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.selectedPackaging, 
                           'Con prefijo 1- debe seleccionar brown box');
    }
    
    /**
     * Test setDefaultPackaging con prefijo '2-' - debe asignar BROWN
     */
    @isTest
    static void testSetDefaultPackagingPrefix2() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        producto.setDefaultPackaging('2-Economy');
        Test.stopTest();
        
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.prodPackaging, 
                           'Con prefijo 2- debe asignar brown box');
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.selectedPackaging, 
                           'Con prefijo 2- debe seleccionar brown box');
    }
    
    /**
     * Test setDefaultPackaging con prefijo '3-' - debe asignar BROWN
     */
    @isTest
    static void testSetDefaultPackagingPrefix3() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        producto.setDefaultPackaging('3-Basic');
        Test.stopTest();
        
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.prodPackaging, 
                           'Con prefijo 3- debe asignar brown box');
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.selectedPackaging, 
                           'Con prefijo 3- debe seleccionar brown box');
    }
    
    /**
     * Test setDefaultPackaging con prefijo '7-' - debe asignar WHITE
     */
    @isTest
    static void testSetDefaultPackagingPrefix7() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        producto.setDefaultPackaging('7-Premium');
        Test.stopTest();
        
        System.assertEquals(ProductoPedidoCatalogo.WHITE, producto.prodPackaging, 
                           'Con prefijo 7- debe asignar white box');
        System.assertEquals(ProductoPedidoCatalogo.WHITE, producto.selectedPackaging, 
                           'Con prefijo 7- debe seleccionar white box');
    }
    
    /**
     * Test setDefaultPackaging con otro prefijo - debe asignar COLOR
     */
    @isTest
    static void testSetDefaultPackagingOtherPrefix() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        producto.setDefaultPackaging('5-Custom');
        Test.stopTest();
        
        System.assertEquals(ProductoPedidoCatalogo.COLOR, producto.prodPackaging, 
                           'Con otro prefijo debe asignar color box');
        System.assertEquals(ProductoPedidoCatalogo.COLOR, producto.selectedPackaging, 
                           'Con otro prefijo debe seleccionar color box');
    }
    
    /**
     * Test setDefaultPackaging sin prefijo - debe asignar COLOR
     */
    @isTest
    static void testSetDefaultPackagingNoPrefix() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        producto.setDefaultPackaging('CustomPackaging');
        Test.stopTest();
        
        System.assertEquals(ProductoPedidoCatalogo.COLOR, producto.prodPackaging, 
                           'Sin prefijo debe asignar color box');
        System.assertEquals(ProductoPedidoCatalogo.COLOR, producto.selectedPackaging, 
                           'Sin prefijo debe seleccionar color box');
    }
    
    /**
     * Test getSelectedBrown cuando está seleccionado BROWN
     */
    @isTest
    static void testGetSelectedBrownTrue() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        producto.selectedPackaging = ProductoPedidoCatalogo.BROWN;
        
        Test.startTest();
        Boolean result = producto.getSelectedBrown();
        Test.stopTest();
        
        System.assertEquals(true, result, 'getSelectedBrown debe retornar true cuando está seleccionado');
    }
    
    /**
     * Test getSelectedBrown cuando NO está seleccionado BROWN
     */
    @isTest
    static void testGetSelectedBrownFalse() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        producto.selectedPackaging = ProductoPedidoCatalogo.WHITE;
        
        Test.startTest();
        Boolean result = producto.getSelectedBrown();
        Test.stopTest();
        
        System.assertEquals(false, result, 'getSelectedBrown debe retornar false cuando NO está seleccionado');
    }
    
    /**
     * Test getSelectedWhite cuando está seleccionado WHITE
     */
    @isTest
    static void testGetSelectedWhiteTrue() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        producto.selectedPackaging = ProductoPedidoCatalogo.WHITE;
        
        Test.startTest();
        Boolean result = producto.getSelectedWhite();
        Test.stopTest();
        
        System.assertEquals(true, result, 'getSelectedWhite debe retornar true cuando está seleccionado');
    }
    
    /**
     * Test getSelectedWhite cuando NO está seleccionado WHITE
     */
    @isTest
    static void testGetSelectedWhiteFalse() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        producto.selectedPackaging = ProductoPedidoCatalogo.COLOR;
        
        Test.startTest();
        Boolean result = producto.getSelectedWhite();
        Test.stopTest();
        
        System.assertEquals(false, result, 'getSelectedWhite debe retornar false cuando NO está seleccionado');
    }
    
    /**
     * Test getSelectedColor cuando está seleccionado COLOR
     */
    @isTest
    static void testGetSelectedColorTrue() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        producto.selectedPackaging = ProductoPedidoCatalogo.COLOR;
        
        Test.startTest();
        Boolean result = producto.getSelectedColor();
        Test.stopTest();
        
        System.assertEquals(true, result, 'getSelectedColor debe retornar true cuando está seleccionado');
    }
    
    /**
     * Test getSelectedColor cuando NO está seleccionado COLOR
     */
    @isTest
    static void testGetSelectedColorFalse() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        producto.selectedPackaging = ProductoPedidoCatalogo.BROWN;
        
        Test.startTest();
        Boolean result = producto.getSelectedColor();
        Test.stopTest();
        
        System.assertEquals(false, result, 'getSelectedColor debe retornar false cuando NO está seleccionado');
    }
    
    /**
     * Test de constantes
     */
    @isTest
    static void testConstants() {
        Test.startTest();
        String brownValue = ProductoPedidoCatalogo.BROWN;
        String whiteValue = ProductoPedidoCatalogo.WHITE;
        String colorValue = ProductoPedidoCatalogo.COLOR;
        Test.stopTest();
        
        System.assertEquals('brown box', brownValue, 'Constante BROWN debe tener el valor correcto');
        System.assertEquals('white box', whiteValue, 'Constante WHITE debe tener el valor correcto');
        System.assertEquals('color box', colorValue, 'Constante COLOR debe tener el valor correcto');
    }
    
    /**
     * Test completo de flujo: crear producto, asignar datos, y verificar packaging
     */
    @isTest
    static void testCompleteWorkflow() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        // Asignar todas las propiedades
        producto.prodId = '001XX000009999';
        producto.prodCode = 'TEST-999';
        producto.prodName = 'Producto Completo';
        producto.prodFamPrefix = 'X';
        producto.prodSfmPrefix = 'Y';
        producto.prodClaPrefix = 'Z9';
        producto.prodMeasures = '50x100x150';
        producto.prodImageId = '015XX000009999';
        producto.prodColor = 'Rojo';
        producto.prodMaterial = 'Aluminio';
        producto.comments = 'Producto de prueba completo';
        
        // Asignar packaging con prefijo 7-
        producto.setDefaultPackaging('7-WhiteBox');
        Test.stopTest();
        
        // Verificar todos los campos
        System.assertEquals('001XX000009999', producto.prodId);
        System.assertEquals('TEST-999', producto.prodCode);
        System.assertEquals('Producto Completo', producto.prodName);
        System.assertEquals(ProductoPedidoCatalogo.WHITE, producto.prodPackaging);
        System.assertEquals(ProductoPedidoCatalogo.WHITE, producto.selectedPackaging);
        System.assertEquals(false, producto.getSelectedBrown());
        System.assertEquals(true, producto.getSelectedWhite());
        System.assertEquals(false, producto.getSelectedColor());
    }
    
    /**
     * Test con cambio manual de selectedPackaging
     */
    @isTest
    static void testManualPackagingChange() {
        ProductoPedidoCatalogo producto = new ProductoPedidoCatalogo();
        
        Test.startTest();
        // Primero asignar un packaging por defecto
        producto.setDefaultPackaging('1-BrownBox');
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.selectedPackaging);
        
        // Cambiar manualmente a COLOR
        producto.selectedPackaging = ProductoPedidoCatalogo.COLOR;
        Test.stopTest();
        
        System.assertEquals(ProductoPedidoCatalogo.BROWN, producto.prodPackaging, 
                           'prodPackaging debe mantener el valor original');
        System.assertEquals(ProductoPedidoCatalogo.COLOR, producto.selectedPackaging, 
                           'selectedPackaging debe cambiar al nuevo valor');
        System.assertEquals(false, producto.getSelectedBrown());
        System.assertEquals(true, producto.getSelectedColor());
    }
}