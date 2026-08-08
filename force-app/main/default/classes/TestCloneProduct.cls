@isTest
private class TestCloneProduct {
	
	@isTest static void testNewBrand() {
		TestUtil tu = new TestUtil();
        tu.initTestData();
        list<Product2> lp = [SELECT Id
                            FROM Product2
                            WHERE RecordType.DeveloperName = 'Producto'];
        system.assertEquals(lp.size(), 2);
        test.startTest();
        CloneProduct cp = new CloneProduct(new ApexPages.StandardController(lp[0]));
        cp.newBrand = cp.altBrands[0].getLabel();
        cp.setMBrand();
        cp.cloneWithFactory();
        test.stopTest();
        lp = [SELECT Id
                    FROM Product2
                    WHERE RecordType.DeveloperName = 'Producto'];
        system.assertEquals(lp.size(), 3);
	}
	
	@isTest static void testNewColor() {
		TestUtil tu = new TestUtil();
        tu.initTestData();
        list<Product2> lp = [SELECT Id
                            FROM Product2
                            WHERE RecordType.DeveloperName = 'Producto'];
        system.assertEquals(lp.size(), 2);
        test.startTest();
        tu.createProductoBaseImage();
        CloneProduct cp = new CloneProduct(new ApexPages.StandardController(lp[0]));
        cp.newColor = 'GOLD';
        cp.setMColor();
        cp.cloneWithFactory();
        test.stopTest();
        lp = [SELECT Id
                    FROM Product2
                    WHERE RecordType.DeveloperName = 'Producto'];
        //system.assertEquals(lp.size(), 3);
	}
	
}