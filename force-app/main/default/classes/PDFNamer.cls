public class PDFNamer{
    public Proforma__c pro {get;set;}
    public String pais {get;set;}
    public String puerto {get;set;}

    public String razonSocial {get;set;}
    public String calle {get;set;}
    public String ciudad {get;set;}
    public String paisCS {get;set;}
    public String division {get;set;}
    public String telefono {get;set;}
    public String correo {get;set;}
    public String beneficiario {get;set;}
    public String numeroDeCuenta {get;set;}
    public String bancoBeneficiario {get;set;}
    public String direccionBanco {get;set;}
    public String swiftCode {get;set;}
    public String divisa {get;set;}    

    public PDFNamer(ApexPages.StandardController std){
        pro = [SELECT Name,
                            EstudioOportunidad__r.Fabrica__r.Puerto__c,
                            EstudioOportunidad__r.Fabrica__r.PaisDelPuerto__c
                            FROM Proforma__c
                            WHERE Id = :std.getId()];
        pais = pro.EstudioOportunidad__r.Fabrica__r.PaisDelPuerto__c;
        puerto = pro.EstudioOportunidad__r.Fabrica__r.Puerto__c;
        
        String fileName = pro.Name + '.pdf' ;
        Apexpages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + fileName );

        initCSInformation(pro);
    }

   public void initCSInformation(Proforma__c prof)
   {
      String sociedad;
      sociedad = getSociedadO(prof.Id);
      System.debug('PDFNamer - sociedad [' + sociedad + ']');
      getSociedadInfo(sociedad);
   }

   public void getSociedadInfo(String sociedad)
   {
      Sociedades__mdt mdt;
      mdt = [SELECT Id, 
                    MasterLabel,
                    Banco_Beneficiario__c,
                    Beneficiario__c,
                    Calle__c,
                    Calle_2__c,
                    Ciudad__c,
                    Correo_Electronico__c,
                    Direccion_Banco__c,
                    Division__c,
                    Nombre__c,
                    Numero_De_Cuenta__c,
                    Pais__c,
                    Razon_Social__c,
                    SWIFT_Code__c,
                    Divisa_de_la_Cuenta__c,
                    Telefono__c
               FROM Sociedades__mdt 
              WHERE MasterLabel = :sociedad];
      razonSocial = mdt.Razon_Social__c;
      calle = mdt.Calle__c;
      ciudad = mdt.Ciudad__c;
      paisCS = mdt.Pais__c;
      division = mdt.Division__c;
      telefono = mdt.Telefono__c;
      correo = mdt.Correo_Electronico__c;
      beneficiario = mdt.Beneficiario__c;
      numeroDeCuenta = mdt.Numero_De_Cuenta__c;
      bancoBeneficiario = mdt.Banco_Beneficiario__c;
      direccionBanco = mdt.Direccion_Banco__c;
      swiftCode = mdt.SWIFT_Code__c;
      divisa = mdt.Divisa_de_la_Cuenta__c;
   }

   public String getSociedadO(String proformaId)
   {
       String sociedad;
       Proforma__c proforma;
       proforma = [SELECT Id, 
                        Cuenta__r.Parent.Sociedad__c,
                        Cuenta__r.Parent.CurrencyISOCode, 
                        Name 
                   FROM Proforma__c
                  WHERE Id = :proformaId];
       
       sociedad = proforma.Cuenta__r.Parent.Sociedad__c + ' ' + proforma.Cuenta__r.Parent.CurrencyISOCode;
       return sociedad;
   }

}