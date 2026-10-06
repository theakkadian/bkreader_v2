import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/http_client_wrapper.dart';
import '../models/book_content_model.dart';

abstract class BetKanuRemoteDataSource {
  Future<BookContentModel> getBook(
    Map<String, String> query, {
    String? cancelToken,
  });
}

class BetKanuRemoteDataSourceImpl implements BetKanuRemoteDataSource {
  BetKanuRemoteDataSourceImpl(this._http);

  final HttpClientWrapper _http;

  @override
  Future<BookContentModel> getBook(
    Map<String, String> query, {
    String? cancelToken,
  }) async {
    final uri = Uri.https(
      AppConstants.apiHost,
      AppConstants.apiPath,
      query,
    );
    final json = await _http.getJson(
      uri,
      headers: {'FROM': AppConstants.fromHeader},
      cancelToken: cancelToken,
    );
    if (json.isEmpty) {
      throw const ApiException('Empty API response');
    }
    return BookContentModel.fromJson(json);
  }
}
