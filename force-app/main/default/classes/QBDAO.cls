/**
 *
 * iestrada 2024-04-17 Class creation
 * 
 * Facade class for QuickBooks data handling
 */
public class QBDAO {
    
    public static QBRESTConfiguration__mdt fetchQBConfigMetadata(String name) {
        List<QBRESTConfiguration__mdt> qbConfigList;
        QBRESTConfiguration__mdt qbConfig;
        
        qbConfigList = [SELECT Id,
                           MasterLabel,
                           QB_Bill_Account_Ref__c,
                           QB_Bill_AP_Acc_Ref__c,
                           QB_Journal_Acc_Ref_Credit__c,
                           QB_Journal_Acc_Ref_Debit__c,
                           QB_Item_Ref__c,
                           QB_Item_Account_Ref__c,
                           QB_Company_ID__c,
                           QB_Minor_Version__c,
                           QB_URI_Context__c,                           
                           SF_Named_Credential__c,
                           SF_NC_URL_schema__c
                      FROM QBRESTConfiguration__mdt
                     WHERE MasterLabel = :name];

        if(qbConfigList.isEmpty()) {
            throw new PGException('Metadata configuration [' + name + '] is not defined. Please contact your administrator');
        } else {
            qbConfig = qbConfigList.get(0);
        }
        return qbConfig;
    }
    
    /** Get metadata config information in order to enable or disable trigger actions **/
    public static Map<String, Boolean> getTriggerConfiguration(String triggerName) {
        List<Trigger_Actions_Config__mdt> configMetadata;
        Map<String, Boolean> actionsConfig = new Map<String, Boolean>();
        configMetadata = [SELECT Trigger_Name__c, 
                                 Trigger_Action__c,
                                 Enabled__c
                            FROM Trigger_Actions_Config__mdt
                           WHERE Trigger_Name__c = :triggerName];
                    
        if(configMetadata.isEmpty()) {
            throw new PGException('Metadata trigger configuration is not defined for [' + triggerName + ']. Please contact your administrator');
        } else {
            for(Trigger_Actions_Config__mdt mdc : configMetadata) {
                actionsConfig.put(mdc.Trigger_Action__c, mdc.Enabled__c);
            }
        }

        return actionsConfig;
    }
    
    
    public static Account getAccount(String idAccount) {
        List<Account> accounts;
        Account account;
        accounts = [SELECT Id,
                           Name,
                           Estado__c,
                           RecordType.DeveloperName,
                           IdQbo__c,
                           NroIdFiscal__c,
                           Phone,
                           EmailComercial__c,
                           RazonSocial__c
                      FROM Account
                     WHERE Id = :idAccount];
                     
        if(accounts.isEmpty()) {
            throw new PGException('Account Id [' + idAccount + '] does not exist. Please contact your administrator');        
        }
        
        account = accounts.get(0);
        return account;
    }
    
    
    public static FacturaDeCliente__c getFacturaCliente(String idFactura, String estado) {
        List<FacturaDeCliente__c> facturas;
        FacturaDeCliente__c factura;
        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           FechaDeFactura__c,
                           FechaVencimiento__c,
                           Cliente__r.Parent.Name,
                           Cliente__r.Parent.IdQbo__c,
                           (SELECT Id,
                                   Name,
                                   PrecioDeVenta__c,
                                   Descripcion__c,
                                   Total__c,
                                   Cantidad__c
                              FROM ItemsDeFacturaDeCliente__r)
                      FROM FacturaDeCliente__c
                     WHERE Id = :idFactura
                       AND Estado__c = :estado];
                     
        if(facturas.isEmpty()) {
            throw new PGException('Factura Id [' + idFactura + '] does not exist. Please contact your administrator');        
        }
        
        factura = facturas.get(0);
        return factura;
    }
    
    
    public static FacturaDeProveedor__c getFacturaProveedor(String idFactura, String estado) {
        List<FacturaDeProveedor__c> facturas;
        FacturaDeProveedor__c factura;
        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           QB_SyncToken__c,
                           FechaDeFactura__c,
                           FechaVencimiento__c,
                           FechaVencimientoActualizada__c,
                           Proveedor__r.Name,
                           Proveedor__r.IdQbo__c,
                           (SELECT Id,
                                   Name,
                                   Descripcion__c,
                                   Total__c
                              FROM ItemsDeFacturaDeProveedor__r)
                      FROM FacturaDeProveedor__c
                     WHERE Id = :idFactura
                       AND Estado__c = :estado];
                     
        if(facturas.isEmpty()) {
            throw new PGException('Factura Id [' + idFactura + '] does not exist. Please contact your administrator');        
        }
        
        factura = facturas.get(0);
        return factura;
    }
    

    public static FacturaDeProveedor__c getFacturaProveedorForJournal(String idFactura, String estado) {
        List<FacturaDeProveedor__c> facturas;
        FacturaDeProveedor__c factura;
        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           IdQboJournalEntry__c,
                           JournalEntryCreadoEnQbo__c,
                           QboJournalEntryNo__c,
                           QboJournalEntryDescription__c,
                           Total__c,
                           QB_SyncToken__c,
                           FechaDeFactura__c,
                           FechaVencimiento__c,
                           FechaVencimientoActualizada__c,
                           Proveedor__r.Name,
                           Proveedor__r.IdQbo__c,
                           (SELECT Id,
                                   Name,
                                   Descripcion__c,
                                   Total__c
                              FROM ItemsDeFacturaDeProveedor__r)
                      FROM FacturaDeProveedor__c
                     WHERE Id = :idFactura
                       AND Estado__c = :estado
                       AND JournalEntryCreadoEnQbo__c = false];
                     
        if(facturas.isEmpty()) {
            throw new PGException('Factura Id [' + idFactura + '] does not exist. Please contact your administrator');        
        }
        
        factura = facturas.get(0);
        return factura;
    }

    
    public static List<FacturaDeCliente__c> getFacturaClienteByEstado(String estado) {
        List<FacturaDeCliente__c> facturas;
        FacturaDeCliente__c factura;
        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           FechaDeFactura__c,
                           FechaVencimiento__c,
                           Cliente__r.Parent.IdQbo__c
                      FROM FacturaDeCliente__c
                     WHERE Estado__c = :estado];
                     
        return facturas;
    }


    public static List<FacturaDeProveedor__c> getFacturaProveedorbyEstado(String estado) {
        List<FacturaDeProveedor__c> facturas;
        FacturaDeProveedor__c factura;
        facturas = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           QB_SyncToken__c,
                           FechaDeFactura__c,
                           FechaVencimiento__c,
                           FechaVencimientoActualizada__c,
                           Proveedor__r.IdQbo__c
                      FROM FacturaDeProveedor__c
                     WHERE Estado__c = :estado];

        return facturas;
    }

}