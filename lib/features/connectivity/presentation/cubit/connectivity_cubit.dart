import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectivityInitial()) {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _hasEmittedOnce = false;

  Future<void> _init() async {
    final initial = await _connectivity.checkConnectivity();
    _emitFrom(initial, notify: false);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _emitFrom(results, notify: true);
    });
  }

  void _emitFrom(List<ConnectivityResult> results, {required bool notify}) {
    final online = results.any((r) => r != ConnectivityResult.none);
    final next =
        online ? const ConnectivityOnline() : const ConnectivityOffline();

    // Skip snackbar noise on first cold check unless already offline.
    if (!_hasEmittedOnce) {
      _hasEmittedOnce = true;
      emit(next);
      return;
    }

    if (!notify && state.runtimeType == next.runtimeType) return;
    emit(next);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
