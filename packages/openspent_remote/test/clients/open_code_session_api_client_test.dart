import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:openspent_remote/openspent_remote.dart';
import 'package:test/test.dart';

void main() {
  group('OpenCodeSessionApiClient', () {
    test('requests the session list endpoint', () async {
      final adapter = _RecordingHttpClientAdapter(
        responseBody: '[{"id":"session-1","time":{"created":1715000000000}}]',
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:4096'))
        ..httpClientAdapter = adapter;
      final client = OpenCodeSessionApiClient(dio);

      final sessions = await client.getSessions();

      expect(sessions, hasLength(1));
      expect(adapter.recordedRequests, hasLength(1));
      final request = adapter.recordedRequests.single;
      expect(request.method, 'GET');
      expect(request.path, '/session');
      expect(request.uri.toString(), 'http://localhost:4096/session');
      expect(request.responseType, ResponseType.json);
    });

    test('requests the session messages endpoint', () async {
      final adapter = _RecordingHttpClientAdapter(
        responseBody:
            '[{"info":{"role":"assistant","time":{"created":1715000001000},"modelID":"gpt-5","cost":0.4,"tokens":{"input":10,"output":20}},"parts":[{"type":"text","text":"ignored"}]}]',
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:4096'))
        ..httpClientAdapter = adapter;
      final client = OpenCodeSessionApiClient(dio);

      final messages = await client.getSessionMessages(sessionId: 'session-1');

      expect(messages, hasLength(1));
      expect(adapter.recordedRequests, hasLength(1));
      final request = adapter.recordedRequests.single;
      expect(request.method, 'GET');
      expect(request.path, '/session/session-1/message');
      expect(
        request.uri.toString(),
        'http://localhost:4096/session/session-1/message',
      );
      expect(request.responseType, ResponseType.json);
    });

    test('includes authorization header when configured', () async {
      final adapter = _RecordingHttpClientAdapter(responseBody: '[]');
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:4096'))
        ..httpClientAdapter = adapter;
      final client = OpenCodeSessionApiClient(
        dio,
        authorizationHeader: 'Basic abc123',
      );

      await client.getSessions();

      final request = adapter.recordedRequests.single;
      expect(request.headers['Authorization'], 'Basic abc123');
    });
  });
}

final class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter({required this.responseBody});

  final String responseBody;
  final List<RequestOptions> recordedRequests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    recordedRequests.add(options);
    return ResponseBody.fromString(
      responseBody,
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
