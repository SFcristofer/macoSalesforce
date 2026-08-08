public with sharing class ProductImportWizardController {

    /**
     * Devuelve los campos de Product2 que son creables o actualizables.
     * Cacheable=true porque los metadatos de schema no cambian frecuentemente.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getProductFields() {
        List<Map<String, String>> fieldsList = new List<Map<String, String>>();

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Product2.fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fd = fieldMap.get(fieldName).getDescribe();

            if (fd.isCreateable() || fd.isUpdateable()) {
                Map<String, String> fieldData = new Map<String, String>();
                fieldData.put('label',        fd.getLabel());
                fieldData.put('value',        fd.getName());
                fieldData.put('type',         String.valueOf(fd.getType()));
                fieldData.put('isExternalId', String.valueOf(fd.isExternalId()));
                fieldData.put('isIdLookup',   String.valueOf(fd.isIdLookup()));
                fieldsList.add(fieldData);
            }
        }

        return fieldsList;
    }

    /**
     * Ejecuta la operación DML (insert / update / upsert) sobre Product2.
     * El JSON ya viene con tipos nativos convertidos desde el LWC.
     * allOrNone=false permite inserción/actualización parcial.
     */
    @AuraEnabled
    public static Map<String, Object> importProducts(String jsonData, String operationType, String matchField) {
        try {
            // Deserializar directamente — el LWC ya convirtió los tipos
            List<Product2> productsToProcess =
                (List<Product2>) JSON.deserialize(jsonData, List<Product2>.class);

            if (productsToProcess == null || productsToProcess.isEmpty()) {
                throw new AuraHandledException('No se recibieron registros para procesar.');
            }

            // Guard de governor limits
            if (productsToProcess.size() > Limits.getLimitDmlRows()) {
                throw new AuraHandledException(
                    'El número de registros (' + productsToProcess.size() +
                    ') supera el límite DML permitido por Salesforce (' +
                    Limits.getLimitDmlRows() + ').'
                );
            }

            if (operationType == 'insert') {
                List<Database.SaveResult> results = Database.insert(productsToProcess, false);
                return buildSaveResultMap(results, productsToProcess);

            } else if (operationType == 'update') {
                List<Database.SaveResult> results = Database.update(productsToProcess, false);
                return buildSaveResultMap(results, productsToProcess);

            } else if (operationType == 'upsert') {
                List<Database.UpsertResult> upsertResults;

                if (String.isNotBlank(matchField) && matchField != 'Id') {
                    Schema.SObjectField extIdField =
                        Schema.SObjectType.Product2.fields.getMap().get(matchField);
                    if (extIdField == null) {
                        throw new AuraHandledException(
                            'El campo de coincidencia "' + matchField + '" no es válido para Product2.'
                        );
                    }
                    upsertResults = Database.upsert(productsToProcess, extIdField, false);
                } else {
                    // Upsert por Id (campo estándar)
                    upsertResults = Database.upsert(productsToProcess, false);
                }
                return buildUpsertResultMap(upsertResults, productsToProcess);

            } else {
                throw new AuraHandledException('Operación no reconocida: ' + operationType);
            }

        } catch (AuraHandledException ahe) {
            throw ahe; // re-lanzar sin envolver
        } catch (Exception e) {
            String cleanMsg = cleanErrorMessage(e.getMessage());
            AuraHandledException ahe = new AuraHandledException(cleanMsg);
            ahe.setMessage(cleanMsg);
            throw ahe;
        }
    }

    // ─── Helpers de resultado ─────────────────────────────────────────────

    private static String cleanErrorMessage(String rawMsg) {
        if (String.isBlank(rawMsg)) return 'Error desconocido.';
        
        String cleanMsg = rawMsg;
        
        // Excepciones de triggers
        if (cleanMsg.contains('caused by: System.IllegalArgumentException:')) {
            cleanMsg = cleanMsg.substringAfter('caused by: System.IllegalArgumentException:').trim();
        } else if (cleanMsg.contains('caused by: System.DmlException:')) {
            cleanMsg = cleanMsg.substringAfter('caused by: System.DmlException:').trim();
        } else if (cleanMsg.contains('caused by:')) {
            cleanMsg = cleanMsg.substringAfter('caused by:').trim();
        }

        // Excepciones DML nativas
        if (cleanMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION,')) {
            cleanMsg = cleanMsg.substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').trim();
        }
        if (cleanMsg.contains('DUPLICATE_VALUE,')) {
            cleanMsg = cleanMsg.substringAfter('DUPLICATE_VALUE,').trim();
        }
        if (cleanMsg.contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST,')) {
            cleanMsg = cleanMsg.substringAfter('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST,').trim();
        }
        
        // Limpiar sufijos
        if (cleanMsg.endsWith(': []')) {
            cleanMsg = cleanMsg.substringBeforeLast(': []').trim();
        }
        
        // Limpiar stacktrace
        if (cleanMsg.contains('\nClass.')) {
            cleanMsg = cleanMsg.substringBefore('\nClass.').trim();
        }
        if (cleanMsg.contains('\nTrigger.')) {
            cleanMsg = cleanMsg.substringBefore('\nTrigger.').trim();
        }

        return cleanMsg.trim();
    }

    private static Map<String, Object> buildSaveResultMap(List<Database.SaveResult> results, List<Product2> productsToProcess) {
        Integer exitosos = 0;
        Integer fallidos = 0;
        List<Map<String, Object>> successList = new List<Map<String, Object>>();
        List<Map<String, Object>> errorList = new List<Map<String, Object>>();

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                exitosos++;
                successList.add(new Map<String, Object>{
                    'rowIndex' => i + 1,
                    'recordId' => results[i].getId(),
                    'recordName' => productsToProcess[i].Name != null ? productsToProcess[i].Name : 'Producto sin nombre'
                });
            } else {
                fallidos++;
                List<String> msgs = new List<String>();
                for (Database.Error err : results[i].getErrors()) {
                    msgs.add(cleanErrorMessage(err.getMessage()));
                }
                errorList.add(new Map<String, Object>{
                    'rowIndex' => i + 1,
                    'errorMessage' => String.join(msgs, ' | ')
                });
            }
        }

        return new Map<String, Object>{
            'totalSuccess' => exitosos,
            'totalErrors' => fallidos,
            'successRecords' => successList,
            'errorRecords' => errorList
        };
    }

    private static Map<String, Object> buildUpsertResultMap(List<Database.UpsertResult> results, List<Product2> productsToProcess) {
        Integer insertados  = 0;
        Integer actualizados = 0;
        Integer fallidos    = 0;
        List<Map<String, Object>> successList = new List<Map<String, Object>>();
        List<Map<String, Object>> errorList = new List<Map<String, Object>>();

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                if (results[i].isCreated()) { insertados++; } else { actualizados++; }
                successList.add(new Map<String, Object>{
                    'rowIndex' => i + 1,
                    'recordId' => results[i].getId(),
                    'recordName' => productsToProcess[i].Name != null ? productsToProcess[i].Name : 'Producto sin nombre'
                });
            } else {
                fallidos++;
                List<String> msgs = new List<String>();
                for (Database.Error err : results[i].getErrors()) {
                    msgs.add(cleanErrorMessage(err.getMessage()));
                }
                errorList.add(new Map<String, Object>{
                    'rowIndex' => i + 1,
                    'errorMessage' => String.join(msgs, ' | ')
                });
            }
        }

        return new Map<String, Object>{
            'totalSuccess' => insertados + actualizados,
            'totalErrors' => fallidos,
            'successRecords' => successList,
            'errorRecords' => errorList
        };
    }
}