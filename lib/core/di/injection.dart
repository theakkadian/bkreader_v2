import 'package:get_it/get_it.dart';

import '../../features/connectivity/presentation/cubit/connectivity_cubit.dart';
import '../../features/reader/presentation/bloc/reader_bloc.dart';
import '../../features/scan/data/datasources/betkanu_remote_datasource.dart';
import '../../features/scan/data/datasources/text_remote_datasource.dart';
import '../../features/scan/data/datasources/xml_book_remote_datasource.dart';
import '../../features/scan/data/repositories/book_repository_impl.dart';
import '../../features/scan/domain/repositories/book_repository.dart';
import '../../features/scan/domain/usecases/fetch_book_content_usecase.dart';
import '../../features/scan/domain/usecases/load_book_text_usecase.dart';
import '../../features/scan/domain/usecases/normalize_qr_url_usecase.dart';
import '../../features/scan/domain/usecases/resolve_qr_usecase.dart';
import '../../features/scan/presentation/bloc/scan_bloc.dart';
import '../../shared/ai/ai_assistant_port.dart';
import '../../shared/ai/auto_read_coordinator.dart';
import '../../shared/ai/tts_port.dart';
import '../../shared/audio/just_audio_adapter.dart';
import '../../shared/network/url_launcher_port.dart';
import '../network/http_client_wrapper.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // Core
  sl.registerLazySingleton<HttpClientWrapper>(HttpClientWrapper.new);
  sl.registerLazySingleton<UrlLauncherPort>(UrlLauncherAdapter.new);

  // Data sources
  sl.registerLazySingleton<BetKanuRemoteDataSource>(
    () => BetKanuRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<XmlBookRemoteDataSource>(
    () => XmlBookRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TextRemoteDataSource>(
    () => TextRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<BookRepository>(
    () => BookRepositoryImpl(
      api: sl(),
      xml: sl(),
      text: sl(),
      http: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(NormalizeQrUrlUseCase.new);
  sl.registerLazySingleton(() => ResolveQrUseCase(sl()));
  sl.registerLazySingleton(() => FetchBookContentUseCase(sl()));
  sl.registerLazySingleton(() => LoadBookTextUseCase(sl()));

  // AI / TTS stubs
  sl.registerLazySingleton<TtsPort>(FakeTtsPort.new);
  sl.registerLazySingleton<AiAssistantPort>(FakeAiAssistantPort.new);
  sl.registerLazySingleton(() => AutoReadCoordinator(sl()));

  // Blocs / Cubits (factories — owned players disposed with bloc)
  sl.registerFactory(ConnectivityCubit.new);

  sl.registerFactory(
    () => ScanBloc(
      resolveQr: sl(),
      fetchBookContent: sl(),
      loadBookText: sl(),
      bookRepository: sl(),
      sfxPlayer: JustAudioAdapter(),
      urlLauncher: sl(),
    ),
  );

  sl.registerFactory(
    () => ReaderBloc(
      audioPlayer: JustAudioAdapter(),
      bookRepository: sl(),
    ),
  );
}
