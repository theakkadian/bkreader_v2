import '../../../../core/error/exception_mapper.dart';
import '../../../../core/network/http_client_wrapper.dart';
import '../../../reader/domain/entities/book_text.dart';
import '../../domain/entities/book_content.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/betkanu_remote_datasource.dart';
import '../datasources/text_remote_datasource.dart';
import '../datasources/xml_book_remote_datasource.dart';

class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl({
    required BetKanuRemoteDataSource api,
    required XmlBookRemoteDataSource xml,
    required TextRemoteDataSource text,
    required HttpClientWrapper http,
  })  : _api = api,
        _xml = xml,
        _text = text,
        _http = http;

  final BetKanuRemoteDataSource _api;
  final XmlBookRemoteDataSource _xml;
  final TextRemoteDataSource _text;
  final HttpClientWrapper _http;

  @override
  Future<BookContent> fetchFromApi(
    Map<String, String> query, {
    String? cancelToken,
  }) async {
    try {
      final model = await _api.getBook(query, cancelToken: cancelToken);
      return model.toEntity();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<BookContent> fetchFromXml(
    String normalizedUrl, {
    String? cancelToken,
  }) async {
    try {
      final model =
          await _xml.getBookFromXml(normalizedUrl, cancelToken: cancelToken);
      return model.toEntity();
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  Future<BookText> loadText(
    String textUrl, {
    String? cancelToken,
  }) async {
    try {
      return await _text.loadText(textUrl, cancelToken: cancelToken);
    } catch (e) {
      throw mapExceptionToFailure(e);
    }
  }

  @override
  void cancelRequests(String cancelToken) {
    _http.cancel(cancelToken);
  }
}
