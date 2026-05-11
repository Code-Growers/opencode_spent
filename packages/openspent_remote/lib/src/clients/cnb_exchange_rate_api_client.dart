import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

part 'cnb_exchange_rate_api_client.g.dart';

@RestApi(
  baseUrl:
      'https://www.cnb.cz/en/financial-markets/foreign-exchange-market/central-bank-exchange-rate-fixing/central-bank-exchange-rate-fixing',
)
abstract class CnbExchangeRateApiClient {
  factory CnbExchangeRateApiClient(Dio dio, {String? baseUrl}) =
      _CnbExchangeRateApiClient;

  @GET('/daily.txt')
  @DioResponseType(ResponseType.plain)
  Future<String> getDailyExchangeRateFile({
    @Query('date') required String date,
  });
}
