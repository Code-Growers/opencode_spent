import 'package:dio/dio.dart' hide Headers;

abstract interface class OpenCodeSessionApiClient {
  factory OpenCodeSessionApiClient(
    Dio dio, {
    String? baseUrl,
    String? authorizationHeader,
  }) = _DioOpenCodeSessionApiClient;

  Future<List<dynamic>> getSessions();

  Future<List<dynamic>> getSessionMessages({required String sessionId});
}

final class _DioOpenCodeSessionApiClient implements OpenCodeSessionApiClient {
  _DioOpenCodeSessionApiClient(
    this._dio, {
    String? baseUrl,
    String? authorizationHeader,
  }) : _baseUrl = baseUrl,
       _authorizationHeader = authorizationHeader;

  final Dio _dio;
  final String? _baseUrl;
  final String? _authorizationHeader;

  @override
  Future<List<dynamic>> getSessions() async {
    final response = await _dio.get<List<dynamic>>(
      _resolvePath('/session'),
      options: _jsonOptions,
    );
    return response.data ?? const <dynamic>[];
  }

  @override
  Future<List<dynamic>> getSessionMessages({required String sessionId}) async {
    final response = await _dio.get<List<dynamic>>(
      _resolvePath('/session/$sessionId/message'),
      options: _jsonOptions,
    );
    return response.data ?? const <dynamic>[];
  }

  Options get _jsonOptions => Options(
    responseType: ResponseType.json,
    headers: _authorizationHeader == null
        ? null
        : <String, Object?>{'Authorization': _authorizationHeader},
  );

  String _resolvePath(String path) {
    final baseUrl = _resolvedBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      return path;
    }

    return Uri.parse(baseUrl).resolve(path).toString();
  }

  String? get _resolvedBaseUrl {
    final baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return null;
    }

    final parsedBaseUrl = Uri.parse(baseUrl);
    if (parsedBaseUrl.isAbsolute) {
      return parsedBaseUrl.toString();
    }

    return _dio.options.baseUrl.isEmpty
        ? parsedBaseUrl.toString()
        : Uri.parse(_dio.options.baseUrl).resolveUri(parsedBaseUrl).toString();
  }
}
