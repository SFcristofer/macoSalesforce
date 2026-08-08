public with sharing class BatchPortalProductNotification implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public static final String NEW_PROV_PROD_SBJ = 'Nuevo Producto de Proveedor (Portal)';
    public static final String NEW_PROV_PROD_BOD = 'El proveedor {0}, ha subido un nuevo producto: {1}';
    //Tests for all Products created in the last 24 hours to cover any batch execution delays
    public static final Datetime LOCAL_EPOCH = DateTime.now().addDays(-1);
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String profileName = 'portal Perfil';
        if(Test.isRunningTest()) {
            profileName = 'Administrador del sistema';
        }
        return Database.getQueryLocator([SELECT Id,
                                                Name,
                                                Fabrica__r.Name,
                                                Fabrica__r.OwnerId,
                                                (SELECT Id 
                                                    FROM Tasks
                                                    WHERE Subject = :NEW_PROV_PROD_SBJ)
                                            FROM Product2
                                            WHERE RecordType.DeveloperName = 'Prospecto_de_Producto'
                                            AND CreatedBy.Profile.Name = :profileName
                                            AND CreatedDate > :LOCAL_EPOCH]);
    }

    public void execute(Database.BatchableContext BC, List<Product2> prods) {
        List<Task> reminders = new List<Task>();
        for(Product2 p : prods) {
            if(p.tasks.size() == 0) {
                reminders.add(createReminder(p.Id, p.Name, p.Fabrica__r.Name, p.Fabrica__r.OwnerId));
            }
        }
        insert reminders;
    }

    public void finish(Database.BatchableContext BC) {
        //schedule the batch again in 8 hours (480 minutes)
        BatchCatalogueNotifications bcn = new BatchCatalogueNotifications();
        String schedId = System.scheduleBatch(bcn, 'PortalProductNotifications-' + System.now(), 480);
    }

    public static Task createReminder(String targetId, String productName, String providerName, String recipientId) {
        Task task = new Task();
        task.Subject = NEW_PROV_PROD_SBJ;
        task.Description = NEW_PROV_PROD_BOD.replace('{0}', providerName).replace('{1}', productName);
        task.WhatId = targetId;
        task.OwnerId = recipientId;
        task.ActivityDate = System.today();
        task.isReminderSet = true;
        task.reminderDateTime = Datetime.now();
        return task;
    }

}