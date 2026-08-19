Id targetUserId = '0054w00000AXeSkAAL';
try {
    System.UserManagement.deregisterVerificationMethod(targetUserId, Auth.VerificationMethod.U2F);
    System.debug('U2F_REMOVED');
} catch(Exception e) {
    System.debug('U2F_ERR: ' + e.getMessage());
}
try {
    System.UserManagement.deregisterVerificationMethod(targetUserId, Auth.VerificationMethod.TOTP);
    System.debug('TOTP_REMOVED');
} catch(Exception e) {
    System.debug('TOTP_ERR: ' + e.getMessage());
}
try {
    System.UserManagement.deregisterVerificationMethod(targetUserId, Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
    System.debug('SFAUTH_REMOVED');
} catch(Exception e) {
    System.debug('SFAUTH_ERR: ' + e.getMessage());
}
