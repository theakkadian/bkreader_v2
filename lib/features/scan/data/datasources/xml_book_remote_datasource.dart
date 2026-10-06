import 'dart:convert';

import 'package:xml2json/xml2json.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/http_client_wrapper.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/book_content_model.dart';

abstract class XmlBookRemoteDataSource {
  Future<BookContentModel> getBookFromXml(
    String url, {
    String? cancelToken,
  });
}

class XmlBookRemoteDataSourceImpl implements XmlBookRemoteDataSource {
  XmlBookRemoteDataSourceImpl(this._http);

  final HttpClientWrapper _http;
  final Xml2Json _transformer = Xml2Json();

  @override
  Future<BookContentModel> getBookFromXml(
    String url, {
    String? cancelToken,
  }) async {
    try {
      final body = await _http.getBody(Uri.parse(url), cancelToken: cancelToken);
      _transformer.parse(body);
      final jsonString = _transformer.toParker();
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        throw const ApiException('Invalid XML bundle');
      }
      final map = Map<String, dynamic>.from(decoded);
      final bundle = map['BKRBundle'];
      if (bundle is! Map) {
        throw const ApiException('Missing BKRBundle');
      }
      return BookContentModel.fromXmlBundle(Map<String, dynamic>.from(bundle));
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('XML parse failed', e, st);
      throw ApiException(e.toString());
    }
  }
}
