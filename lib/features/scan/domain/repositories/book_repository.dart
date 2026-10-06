import '../../../reader/domain/entities/book_text.dart';
import '../entities/book_content.dart';

abstract class BookRepository {
  Future<BookContent> fetchFromApi(
    Map<String, String> query, {
    String? cancelToken,
  });

  Future<BookContent> fetchFromXml(
    String normalizedUrl, {
    String? cancelToken,
  });

  Future<BookText> loadText(
    String textUrl, {
    String? cancelToken,
  });

  void cancelRequests(String cancelToken);
}
