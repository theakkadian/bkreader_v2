import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';
import 'features/connectivity/presentation/cubit/connectivity_cubit.dart';
import 'features/reader/presentation/bloc/reader_bloc.dart';

class BkReaderApp extends StatefulWidget {
  const BkReaderApp({super.key});

  @override
  State<BkReaderApp> createState() => _BkReaderAppState();
}

class _BkReaderAppState extends State<BkReaderApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  late final ReaderBloc _readerBloc;
  late final ConnectivityCubit _connectivityCubit;
  bool? _lastWasTablet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = createRouter();
    _readerBloc = sl<ReaderBloc>();
    _connectivityCubit = sl<ConnectivityCubit>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _readerBloc.close();
    _connectivityCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _readerBloc.onAppPaused();
    }
  }

  void _applyOrientationsIfNeeded(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    if (_lastWasTablet == isTablet) return;
    _lastWasTablet = isTablet;
    final orientations = isTablet
        ? DeviceOrientation.values
        : const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ];
    SystemChrome.setPreferredOrientations(orientations);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _connectivityCubit),
        BlocProvider.value(value: _readerBloc),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'BET KANU Reader',
        theme: AppTheme.light,
        routerConfig: _router,
        builder: (context, child) {
          _applyOrientationsIfNeeded(context);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: _ConnectivityBanner(child: child ?? const SizedBox()),
          );
        },
      ),
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listenWhen: (previous, current) =>
          previous is! ConnectivityInitial &&
          previous.runtimeType != current.runtimeType,
      listener: (context, state) {
        final online = state is ConnectivityOnline;
        final message = online
            ? 'We got Wi-Fi connection back'
            : 'We have lost internet connection';
        final color = online ? Colors.green : Colors.red;
        final background = online
            ? const Color.fromARGB(255, 213, 251, 213)
            : const Color.fromARGB(255, 252, 208, 205);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: background,
            duration: const Duration(seconds: 3),
            content: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        );

        if (!online) {
          // Mirror legacy: mark reader unsuccessful when offline mid-session.
          // Content remains visible; play button disables via network failure UX.
        }
      },
      child: child,
    );
  }
}
