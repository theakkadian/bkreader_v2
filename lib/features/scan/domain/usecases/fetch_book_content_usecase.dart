import '../entities/book_content.dart';
import '../entities/resolved_target.dart';
import '../repositories/book_repository.dart';

/// Fetches book media metadata for a resolved QR target.
class FetchBookContentUseCase {
  FetchBookContentUseCase(this._repository);

  final BookRepository _repository;

  Future<BookContent> call(
    ResolvedTarget target, {
    String? cancelToken,
  }) async {
    switch (target) {
      case YoutubeTarget(:final url):
        return BookContent(
          videoUrl: url,
          isYoutube: true,
          isBetkanuProduct: true,
        );
      case XmlTarget(:final normalizedUrl):
        return _repository.fetchFromXml(
          normalizedUrl,
          cancelToken: cancelToken,
        );
      case BetKanuApiTarget(:final queryParams):
        return _repository.fetchFromApi(
          queryParams,
          cancelToken: cancelToken,
        );
      case InvalidTarget():
        return const BookContent(isBetkanuProduct: false);
    }
  }
}
