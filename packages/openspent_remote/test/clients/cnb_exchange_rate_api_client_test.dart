import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:openspent_remote/openspent_remote.dart';
import 'package:test/test.dart';

void main() {
  group('CnbExchangeRateApiClient', () {
    test('requests the expected daily endpoint and returns raw text', () async {
      final adapter = _RecordingHttpClientAdapter(
        responseBody: '02.05.2026 #84\nzemě|měna|množství|kód|kurz\n',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final client = CnbExchangeRateApiClient(dio);

      final response = await client.getDailyExchangeRateFile(
        date: '02.05.2026',
      );

      expect(response, '02.05.2026 #84\nzemě|měna|množství|kód|kurz\n');

      final request = adapter.recordedRequest;
      expect(request, isNotNull);
      expect(request!.method, 'GET');
      expect(
        request.baseUrl,
        'https://www.cnb.cz/en/financial-markets/foreign-exchange-market/central-bank-exchange-rate-fixing/central-bank-exchange-rate-fixing',
      );
      expect(request.path, '/daily.txt');
      expect(request.queryParameters, <String, dynamic>{'date': '02.05.2026'});
      expect(
        request.uri.toString(),
        'https://www.cnb.cz/en/financial-markets/foreign-exchange-market/central-bank-exchange-rate-fixing/central-bank-exchange-rate-fixing/daily.txt?date=02.05.2026',
      );
      expect(request.responseType, ResponseType.plain);
    });
  });
}

final class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter({required this.responseBody});

  final String responseBody;
  RequestOptions? recordedRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    recordedRequest = options;
    return ResponseBody.fromString(
      responseBody,
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/plain; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
