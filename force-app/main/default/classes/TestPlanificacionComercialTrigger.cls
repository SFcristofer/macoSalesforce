@isTest
public class TestPlanificacionComercialTrigger 
{
    @isTest static void testReporte() {
       TestUtil tu = new TestUtil();
       tu.initPedidoReporteAportacion();
       PlanificacionComercial__c pc = tu.getPlanificacionComercial();
       pc.Objetivo_de_Margen__c = 40;
       
       update pc;
    }
}