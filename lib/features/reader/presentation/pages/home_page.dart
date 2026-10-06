import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/intro_logo.dart';
import '../../../scan/domain/entities/book_content.dart';
import '../bloc/reader_bloc.dart';
import '../widgets/book_content_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AudioPlayer? _introPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playIntro());
  }

  Future<void> _playIntro() async {
    try {
      _introPlayer = AudioPlayer();
      await _introPlayer!.setAudioSource(
        AudioSource.asset(AppConstants.introAudioAsset),
      );
      await _introPlayer!.play();
    } catch (e, st) {
      AppLogger.e('Intro audio failed', e, st);
    }
  }

  @override
  void dispose() {
    _introPlayer?.dispose();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (!status.isGranted) {
      final permanently = status.isPermanentlyDenied;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            permanently
                ? 'Camera permission is permanently denied. Enable it in Settings.'
                : const PermissionFailure().message,
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    final result = await context.push<Object?>(AppRoutes.scan);
    if (!mounted || result == null) return;

    if (result is BookContent) {
      if (result.isYoutube) return;
      context.read<ReaderBloc>().add(LoadContent(result));
    } else if (result is Failure) {
      context.read<ReaderBloc>().add(
            ShowReaderFailure(
              result,
              notBetkanuProduct: result is QrParseFailure,
            ),
          );
    }
  }

  void _onPlayTapped() {
    final reader = context.read<ReaderBloc>();
    final state = reader.state;
    if (!state.canPlayAudio) return;
    if (state.isPlaying) {
      reader.add(const PauseAudio());
    } else {
      reader.add(const PlayAudio());
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    // FAB diameter ≈ 2 * radius; reserve chrome so content never sits under it.
    final fabRadius = Responsive.scaled(
      context,
      height * 0.055,
      min: 36,
      max: 48,
    );
    final chromeHeight = fabRadius * 2.2 + 28;

    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<ReaderBloc, ReaderState>(
          builder: (context, readerState) {
            final showContent = readerState is ReaderReady ||
                readerState is ReaderPlaying ||
                readerState is ReaderError ||
                readerState is ReaderLoading;

            return Stack(
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppConstants.backgroundImage),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
                Column(
                  children: [
                    Expanded(
                      child: ResponsiveBody(
                        child: !showContent
                            ? const IntroLogo()
                            : readerState is ReaderLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.loaderBlue,
                                    ),
                                  )
                                : const BookContentView(),
                      ),
                    ),
                    SizedBox(height: chromeHeight),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: chromeHeight,
                  child: ResponsiveBody(
                    child: _BottomChrome(
                      fabRadius: fabRadius,
                      canPlay: readerState.canPlayAudio,
                      isPlaying: readerState.isPlaying,
                      audioCompleted: readerState.audioCompleted,
                      onScan: _openScanner,
                      onPlay: _onPlayTapped,
                      onAbout: () => context.push(AppRoutes.about),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BottomChrome extends StatelessWidget {
  const _BottomChrome({
    required this.fabRadius,
    required this.canPlay,
    required this.isPlaying,
    required this.audioCompleted,
    required this.onScan,
    required this.onPlay,
    required this.onAbout,
  });

  final double fabRadius;
  final bool canPlay;
  final bool isPlaying;
  final bool audioCompleted;
  final VoidCallback onScan;
  final VoidCallback onPlay;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final iconSize = fabRadius * 1.35; // ~67% of diameter (2*radius)

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: fabRadius * 0.9,
          child: SvgPicture.asset(
            AppConstants.bottomBarSvg,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          bottom: fabRadius * 0.35,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: canPlay ? onPlay : null,
                child: CircleAvatar(
                  radius: fabRadius,
                  backgroundColor:
                      canPlay ? AppColors.softOrange : AppColors.disabledGray,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: fabRadius * 0.92,
                    child: Icon(
                      audioCompleted || !isPlaying
                          ? Icons.play_arrow_rounded
                          : Icons.pause,
                      size: iconSize,
                      color: canPlay
                          ? AppColors.accentOrange
                          : AppColors.mutedOrange,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: onAbout,
                child: Icon(
                  Icons.info_outline_rounded,
                  size: Responsive.scaled(
                    context,
                    fabRadius * 0.9,
                    min: 28,
                    max: 40,
                  ),
                  color: AppColors.bottomIcon,
                ),
              ),
              InkWell(
                onTap: onScan,
                child: CircleAvatar(
                  radius: fabRadius,
                  backgroundColor: AppColors.softBlue,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: fabRadius * 0.92,
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: iconSize,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
