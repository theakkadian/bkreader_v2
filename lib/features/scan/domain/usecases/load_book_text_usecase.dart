import '../../../reader/domain/entities/book_text.dart';
import '../repositories/book_repository.dart';

/// Loads remote text and splits Syriac / companion lines.
class LoadBookTextUseCase {
  LoadBookTextUseCase(this._repository);

  final BookRepository _repository;

  Future<BookText> call(String? textUrl, {String? cancelToken}) async {
    if (textUrl == null || textUrl.trim().isEmpty) {
      return const BookText(syriacText: '');
    }
    return _repository.loadText(textUrl, cancelToken: cancelToken);
  }
}
