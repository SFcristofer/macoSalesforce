public class BatchCatalogueNotifications implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    public static final String NEW_CAT_OPP = 'Nueva_Opp_de_Catalogo';
    public static final String NEW_CAT_OPP_SBJ = 'Nueva Oportunidad de Catálogo';
    public static final String NEW_CAT_OPP_BOD = 'Se ha generado una nueva oportunidad desde el catálogo: ';
    //Tests for all Opportunities created in the last 24 hours to cover any batch execution delays
    public static final Datetime LOCAL_EPOCH = DateTime.now().addDays(-1);
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id,
                                                Name,
                                                Account.OwnerId,
                                                Productos_No_Validos__c,
                                                (SELECT Id 
                                                    FROM Tasks
                                                    WHERE Subject = :NEW_CAT_OPP_SBJ)
                                           FROM Opportunity
                                          WHERE Catalogo__c != null
                                            AND CreatedDate > :LOCAL_EPOCH]);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> opps) {
        List<Task> reminders = new List<Task>();
        for(Opportunity o : opps) {
            if(o.tasks.size() == 0) {
                reminders.add(createReminder(o.Id, o.Name, o.Productos_No_Validos__c, o.Account.OwnerId));
            }
        }
        insert reminders;
    }

    public void finish(Database.BatchableContext BC) {
        //schedule the batch again in 3 minutes
        BatchCatalogueNotifications bcn = new BatchCatalogueNotifications();
        String schedId = System.scheduleBatch(bcn, 'CatalogueNotifications-' + System.now(), 3);
    }

    public static Task createReminder(String targetId, String targetName, String notValidproducts, String recipientId) {
        Task task = new Task();
        task.Subject = NEW_CAT_OPP_SBJ;
        task.Description = NEW_CAT_OPP_BOD + targetName;
        if (notValidproducts != null && !notValidproducts.equals('')) {
            task.Subject = task.Subject + ' ' + '(ERROR: Productos no válidos)';
            task.Description = task.Description + ' ERROR Producto:' + notValidproducts;
        }
        task.WhatId = targetId;
        task.OwnerId = recipientId;
        task.ActivityDate = System.today();
		task.isReminderSet = true;
        task.reminderDateTime = Datetime.now();
        return task;
    }

}