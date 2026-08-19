Account[] accountsToDelete = [
    SELECT Id 
    FROM Account 
    WHERE CreatedById = '005VT000007IR49YAG' 
    AND CreatedDate >= 2026-06-15T00:00:00-06:00 
    AND CreatedDate <= 2026-06-15T23:59:59-06:00
    LIMIT 2000
];
System.debug('Deleting ' + accountsToDelete.size() + ' accounts.');
delete accountsToDelete;
