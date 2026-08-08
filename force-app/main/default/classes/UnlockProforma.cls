/**
*   Controller for "Desbloquear" action on Proforma__c
*   @author lcosta@infolastic.com
*   @version 1.0
*/
public class UnlockProforma {
        private static final String OK = 'OK!'; //OK text on Alert fields in Proforma__c
        private static final String PPAL = 'Principal';
        private static final String ERR_CONDITIONS = 'La Proforma no cumple con las condiciones ' +
                                                    'mínimas y deberá ser aprobada por dirección.';
        private Proforma__c pr;

	public UnlockProforma(ApexPages.StandardController std) {
		pr = [SELECT Id,
                    Alerta_Margen__c,
                    Alerta_Importe__c,
                    Alerta_Credito__c
                    FROM Proforma__c
                    WHERE Id = :std.getId()];
	}

    /**
    *   If the Proforma__c complies with all conditions (minimum Margin, maximum Total Amount, 
    *   minimum Credit), its record type is changed to 'Principal', 
    *   otherwise an error message is shown.
    */
    public PageReference unlock(){
        if(!pr.Alerta_Margen__c.contains('OK!') ||
                !pr.Alerta_Importe__c.contains('OK!') ||
                !pr.Alerta_Credito__c.contains('OK!')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERR_CONDITIONS));
            return null;
        }
        Id idRT = [SELECT Id 
                   	FROM RecordType 
                   	WHERE sObjectType = 'Proforma__c'
                    AND developerName = :PPAL].Id;
        
        pr.RecordTypeId = idRT;
        update pr;
        return new PageReference('/lightning/r/Proforma__c/' + pr.Id + '/view' );
    }
}