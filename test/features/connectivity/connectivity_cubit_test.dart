import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bk_reader_v2/features/connectivity/presentation/cubit/connectivity_cubit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> changes;

  setUp(() {
    connectivity = _MockConnectivity();
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => changes.stream);
  });

  tearDown(() async {
    await changes.close();
  });

  Future<ConnectivityCubit> buildCubit(
    List<ConnectivityResult> initial,
  ) async {
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => initial);
    final cubit = ConnectivityCubit(connectivity: connectivity);
    // Wait for async cold check in constructor.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  blocTest<ConnectivityCubit, ConnectivityState>(
    'cold check online → ConnectivityOnline (no snackbar noise path)',
    build: () {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      return ConnectivityCubit(connectivity: connectivity);
    },
    wait: const Duration(milliseconds: 20),
    expect: () => [const ConnectivityOnline()],
  );

  blocTest<ConnectivityCubit, ConnectivityState>(
    'cold check offline → ConnectivityOffline',
    build: () {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      return ConnectivityCubit(connectivity: connectivity);
    },
    wait: const Duration(milliseconds: 20),
    expect: () => [const ConnectivityOffline()],
  );

  test('emits Offline then Online when connectivity changes', () async {
    final cubit = await buildCubit([ConnectivityResult.wifi]);
    expect(cubit.state, const ConnectivityOnline());

    final expectations = expectLater(
      cubit.stream,
      emitsInOrder([
        const ConnectivityOffline(),
        const ConnectivityOnline(),
      ]),
    );

    changes.add([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);
    changes.add([ConnectivityResult.mobile]);
    await expectations;
    await cubit.close();
  });

  test('duplicate online change after first emit is ignored by Cubit equality',
      () async {
    final cubit = await buildCubit([ConnectivityResult.wifi]);
    expect(cubit.state, const ConnectivityOnline());

    var emissions = 0;
    final sub = cubit.stream.listen((_) => emissions++);

    changes.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(emissions, 0);

    await sub.cancel();
    await cubit.close();
  });

  test('close cancels subscription', () async {
    final cubit = await buildCubit([ConnectivityResult.wifi]);
    await cubit.close();

    // After close, further stream events must not throw or update state.
    changes.add([ConnectivityResult.none]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cubit.state, const ConnectivityOnline());
  });
}
