public class CurrencyUtil {

    public static final String USD = 'USD';
    
    private static Map<String, DatedConversionRate> conversionRates = new Map<String, DatedConversionRate>();
    private static Map<String, CurrencyType> currencyTypes = new Map<String, CurrencyType>();
    
    public static Decimal getRate(String isoCode){
        system.debug('ISO Code: ' + isoCode);
        if(getConversionRate(isoCode) != null){
            return getConversionRate(isoCode).ConversionRate;
        }
        return getCurrencyRate(isoCode).ConversionRate;
    }
    
    public static DatedConversionRate getConversionRate(String isoCode){
        if(!conversionRates.containsKey(isoCode)){
            List<DatedConversionRate> rate = [SELECT Id, 
                                            isoCode, 
                                            ConversionRate, 
                                            nextStartDate, 
                                            startDate 
                                            FROM DatedConversionRate 
                                            WHERE isoCode = :isoCode
                                            AND StartDate <= TODAY 
                                            AND NextStartDate > TODAY 
                                            ORDER BY NextStartDate DESC Limit 1];
            if(!rate.isEmpty()){
                conversionRates.put(isoCode, rate[0]);
            }
        }
    
        return conversionRates.get(isoCode);
    }
    
    public static CurrencyType getCurrencyRate(String isoCode){
        if(!currencyTypes.containsKey(isoCode)){
            List<CurrencyType> rate = [SELECT Id, 
                                            isoCode, 
                                            ConversionRate 
                                            FROM CurrencyType 
                                            WHERE isoCode = :isoCode
                                            AND isActive = true];
            if(!rate.isEmpty()){
                currencyTypes.put(isoCode, rate[0]);
            }
        }
    
        return currencyTypes.get(isoCode);
    }
  
}