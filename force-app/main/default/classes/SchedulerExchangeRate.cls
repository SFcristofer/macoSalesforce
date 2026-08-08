/*
 * This scheduler get currency exchange rate daily
 */
global class SchedulerExchangeRate implements Schedulable {

  global void execute(SchedulableContext sc) {
      ExchangeRateClient erc = ExchangeRateClient.getInstance();
      erc.getExchangeRate('https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml', 'USD');
  }

}