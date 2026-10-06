import 'package:bloc_test/bloc_test.dart';
import 'package:bk_reader_v2/features/reader/presentation/cubit/zoom_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZoomCubit', () {
    blocTest<ZoomCubit, bool>(
      'starts unzoomed',
      build: ZoomCubit.new,
      expect: () => <bool>[],
      verify: (c) => expect(c.state, isFalse),
    );

    blocTest<ZoomCubit, bool>(
      'setZoomed(true) then false',
      build: ZoomCubit.new,
      act: (c) {
        c.setZoomed(true);
        c.setZoomed(false);
      },
      expect: () => [true, false],
    );

    blocTest<ZoomCubit, bool>(
      'duplicate zoomed value is not re-emitted',
      build: ZoomCubit.new,
      act: (c) {
        c.setZoomed(true);
        c.setZoomed(true);
      },
      expect: () => [true],
    );
  });
}
