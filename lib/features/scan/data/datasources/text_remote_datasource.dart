import '../../../../core/error/exceptions.dart';
import '../../../../core/network/http_client_wrapper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/null_string.dart';
import '../../../reader/domain/entities/book_text.dart';
import '../text/book_text_codec.dart';

abstract class TextRemoteDataSource {
  Future<BookText> loadText(String textUrl, {String? cancelToken});
}

class TextRemoteDataSourceImpl implements TextRemoteDataSource {
  TextRemoteDataSourceImpl(this._http);

  final HttpClientWrapper _http;

  @override
  Future<BookText> loadText(String textUrl, {String? cancelToken}) async {
    final cleaned = sanitizeMediaUrl(textUrl).replaceAll('%0D%0A', '');
    final encoded = Uri.encodeFull(cleaned);

    try {
      final bytes = await _http.getBytes(
        Uri.parse(encoded),
        headers: {'Content-Type': 'text/plain'},
        cancelToken: cancelToken,
      );
      final contents = decodeBookTextBytes(bytes);
      return _parseContents(contents);
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.e('Text load failed', e, st);
      throw TextLoadException(e.toString());
    }
  }

  BookText _parseContents(String contents) {
    final isOnlySyriac = !RegExp(r'[a-zA-Z]').hasMatch(contents);
    if (isOnlySyriac) {
      return BookText(syriacText: contents, isOnlySyriac: true);
    }
    final lines = contents.split('\n');
    final companion = lines.isNotEmpty ? lines[0] : '';
    final syriac = lines.length > 1 ? lines[1] : '';
    return BookText(
      syriacText: syriac,
      companionText: companion,
      isOnlySyriac: false,
    );
  }
}
