import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/pages/about_page.dart';
import '../../features/about/presentation/pages/instructions_page.dart';
import '../../features/reader/presentation/pages/home_page.dart';
import '../../features/scan/presentation/bloc/scan_bloc.dart';
import '../../features/scan/presentation/pages/scan_page.dart';
import '../di/injection.dart';

class AppRoutes {
  AppRoutes._();

  static const home = '/home';
  static const scan = '/scan';
  static const reader = '/reader';
  static const about = '/about';
  static const instructions = '/instructions';
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.scan,
        name: 'scan',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<ScanBloc>()..add(const ScanStarted()),
          child: const ScanPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.reader,
        name: 'reader',
        // Reader content is shown on HomePage via ReaderBloc;
        // this named route redirects for deep-link compatibility.
        redirect: (context, state) => AppRoutes.home,
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.instructions,
        name: 'instructions',
        builder: (context, state) => const InstructionsPage(),
      ),
    ],
  );
}
