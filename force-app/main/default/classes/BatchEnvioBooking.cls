global class BatchEnvioBooking implements Database.Batchable<sObject> {
    public static String TYPE_BATCH_SETENVIO = 'Envio';
    public static String TYPE_BATCH_TASK = 'Task';

	private Integer DATE_OFFSET = 30;
    private Integer DATE_OFFSET_TASK = 35;	
    private String tipoBatch;
	private String pedidoName;
	private String TASK_SUBJECT = Label.TASK_BOOKING_MISSING_FIELDS;
	private String TASK_MANUAL_BOOKING_SUBJECT = Label.TASK_MANUAL_BOOKING_SUBJECT;
	private String TASK_MANUAL_BOOKING_BODY = Label.TASK_MANUAL_BOOKING_BODY;
	private List<String> idUsers;
	
	
	global BatchEnvioBooking(String ptipoBatch) {
        tipoBatch = ptipoBatch;
		pedidoName = '';
		System.debug('tipoBatch[' + tipoBatch + ']');
        idUsers = getIdUsersTasks();		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
	   Date auxDate;
       Id idRecordType = Schema.sObjectType.PedidoDeCompra__c.getRecordTypeInfosByDeveloperName().get('Principal').getRecordTypeId();

       System.debug('start');
	   if(tipoBatch.equals(TYPE_BATCH_SETENVIO)) {
		   auxDate = Date.today().addDays(DATE_OFFSET); 
           System.debug('aux Date env [' + auxDate + ']');
           return Database.getQueryLocator([SELECT Id, 
		                                           Name,
		                                           Cuenta_Agente_DO__c, 
				    							   Booking_Agente__c,
					    		                   Numero_de_Orden__c,
						    					   Enviar_solicitud_booking__c,
							    				   Solicitud_booking_enviada__c,
								    			   Fecha_Minima_Embarque__c,
												   RecordTypeId,
									    		   Fecha_de_Compromiso_con_el_Cliente__c
						                      FROM PedidoDeCompra__c
						                     WHERE Solicitud_booking_enviada__c = false
											   AND RecordTypeId = :idRecordType
											   AND Fecha_Minima_Embarque__c < :auxDate]);
	   }

	   if(tipoBatch.equals(TYPE_BATCH_TASK)) {
           auxDate = Date.today().addDays(DATE_OFFSET_TASK);
           System.debug('aux Date tsk [' + auxDate + ']');
           return Database.getQueryLocator([SELECT Id, 
		                                           Name,
		                                           Cuenta_Agente_DO__c, 
				    							   Booking_Agente__c,
					    		                   Numero_de_Orden__c,
						    					   Enviar_solicitud_booking__c,
							    				   Solicitud_booking_enviada__c,
								    			   Fecha_Minima_Embarque__c,
												   Fecha_Maxima_Embarque__c,
												   Puerto_de_origen__c,
												   Puerto_de_destino__c,
									    		   Fecha_de_Compromiso_con_el_Cliente__c,
												   RecordTypeId,
												   Proforma__r.Oportunidad__r.AccountId
						                      FROM PedidoDeCompra__c
						                     WHERE Enviar_solicitud_booking__c = false
						                       AND Solicitud_booking_enviada__c = false
											   AND Fecha_de_Compromiso_con_el_Cliente__c = :auxDate
											   AND RecordTypeId = :idRecordType]);
	   }
	   return null;
	}

   	global void execute(Database.BatchableContext BC, List<PedidoDeCompra__c> pedidos) {
	   Date auxDate;
       List<PedidoDeCompra__c> pedidosOrderTeam = new List<PedidoDeCompra__c>();
       List<PedidoDeCompra__c> pedidosProcess = new List<PedidoDeCompra__c>();
       List<PedidoDeCompra__c> pedidosTask = new List<PedidoDeCompra__c>();
       List<Task> tasks = new List<Task>();
       List<Task> tasksBM = new List<Task>();	   

	   System.debug('pedidos size[' + pedidos.size() + ']');

       for(PedidoDeCompra__c pedido : pedidos) {

	       if(tipoBatch.equals(TYPE_BATCH_SETENVIO)) {
		       if(pedido.Enviar_solicitud_booking__c == true) {
                   pedidosProcess.add(pedido);
			   }
		       if(pedido.Enviar_solicitud_booking__c == false) {
                   pedidosOrderTeam.add(pedido);
			   }
		   }

	       if(tipoBatch.equals(TYPE_BATCH_TASK)) {
               if(pedido.Numero_de_Orden__c == null || pedido.Fecha_Minima_Embarque__c == null || pedido.Fecha_Maxima_Embarque__c == null ||
                  pedido.Puerto_de_origen__c == null || pedido.Puerto_de_destino__c == null) {
                   pedidosTask.add(pedido);
			   }
		   }		   
       }

	   System.debug('pedidosProcess[' + pedidosProcess.size() + '] pedidosOrder[' + pedidosOrderTeam.size() + '] pedidostask[' + pedidosTask.size() + ']');

       if(tipoBatch.equals(TYPE_BATCH_SETENVIO)) {
	       AgentMail.getDataOrder(pedidosProcess);

	       for(PedidoDeCompra__c pedido : pedidosProcess) {
               pedido.Solicitud_booking_enviada__c = true;
	       }
	       upsert pedidosProcess;

		   ///
		   auxDate = Date.today().addDays(DATE_OFFSET);
		   for(PedidoDeCompra__c order : pedidosOrderTeam) {
		       for(String idUser : idUsers) {
				   System.debug('idUserTask [' + idUser + ']');
	               TASK_MANUAL_BOOKING_BODY = TASK_MANUAL_BOOKING_BODY.replace('{0}', String.valueOf(order.Fecha_Minima_Embarque__c.daysBetween(auxDate)));
				   TASK_MANUAL_BOOKING_SUBJECT = TASK_MANUAL_BOOKING_SUBJECT.replace('{0}', String.valueOf(order.Fecha_Minima_Embarque__c.daysBetween(auxDate)));
                   TASK_MANUAL_BOOKING_SUBJECT = TASK_MANUAL_BOOKING_SUBJECT.replace('{1}', order.Id);
				   System.debug('['+ order.Id +'] [' + order.Name + '] [' + TASK_MANUAL_BOOKING_BODY + ']');
                   tasksBM.add(createTask(TASK_MANUAL_BOOKING_SUBJECT, TASK_MANUAL_BOOKING_BODY, 'Abierta', 'Normal', order.Id, idUser));
			   }
			   order.Is_Manual_Booking_Sent__c = true;
		   }
		   System.debug('taskBM.size() [' + tasksBM.size() + ']');
		   insert tasksBM;
		   update pedidosOrderTeam;
       }

	   if(tipoBatch.equals(TYPE_BATCH_TASK)) {
		   for(PedidoDeCompra__c pedido : pedidosTask) {
               tasks.add(createTask(TASK_SUBJECT, '', 'Abierta', 'Normal', pedido.Id, pedido.Proforma__r.Oportunidad__r.AccountId));
		   }
		   insert tasks;
	   }

	}

	private Task createTask(String subject, String description, String status, String priority, String whatId, String ownerId) {
        Task task = new Task();
        task.Subject = subject;
        task.Status = status;
        task.Priority = priority;
        task.Description = description;
        task.WhatId = whatId;
        task.OwnerId = ownerId;
        task.ActivityDate = System.today();
		task.isReminderSet = true;
		task.reminderDateTime = Datetime.now();
        return task;
	}

    private List<String> getIdUsersTasks() {
        List<Tarea_Aportacion__mdt> mdts;
		List<String> usersMdt;
		List<User> users;
		List<String> idUsers;

		usersMdt = new List<String>();
        idUsers = new List<String>();

        mdts = [SELECT Id, Usuario__c, MasterLabel FROM Tarea_Aportacion__mdt WHERE MasterLabel = 'Booking'];
		
		for(Tarea_Aportacion__mdt mdt : mdts) {
            usersMdt.add(mdt.Usuario__c);
		}

        users = [SELECT Id, UserName FROM User WHERE Username IN :usersMdt];
        for(User u : users) {
            idUsers.add(u.Id);
		}
        return idUsers;
	}

	global void finish(Database.BatchableContext BC) 
	{
		
	}

}