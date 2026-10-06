import 'package:flutter_test/flutter_test.dart';
import 'package:bk_reader_v2/features/scan/domain/usecases/normalize_qr_url_usecase.dart';

void main() {
  test('smoke: NormalizeQrUrlUseCase is constructible', () {
    expect(const NormalizeQrUrlUseCase(), isNotNull);
  });
}
