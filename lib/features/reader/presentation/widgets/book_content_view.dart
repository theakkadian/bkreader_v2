import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../scan/domain/entities/book_content.dart';
import '../bloc/reader_bloc.dart';
import 'book_image.dart';
import 'internal_video_player.dart';
import 'zoomable_image.dart';

class BookContentView extends StatelessWidget {
  const BookContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      builder: (context, state) {
        final content = state.contentOrNull;
        final failure = state is ReaderError ? state.failure : null;
        final isZoomed = state.isImageZoomed;

        final notProduct = content != null && !content.isBetkanuProduct;
        final showError = failure != null ||
            (content != null &&
                content.isBetkanuProduct &&
                state is ReaderError);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 5, color: AppColors.accentOrange),
                  bottom: BorderSide(width: 5, color: AppColors.primaryBlue),
                ),
                color: Colors.white,
              ),
              child: notProduct
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        const QrParseFailure().message,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: const TextStyle(fontFamily: 'Roboto'),
                      ),
                    )
                  : _BookCard(
                      content: content,
                      showError: showError || content == null,
                      isZoomed: isZoomed,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.content,
    required this.showError,
    required this.isZoomed,
  });

  final BookContent? content;
  final bool showError;
  final bool isZoomed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardH = constraints.maxHeight;
        final cardW = constraints.maxWidth;
        final fontSize = Responsive.scaled(
          context,
          cardH * cardW * 0.00008,
          min: 12,
          max: 22,
        );
        final companionSize = Responsive.scaled(
          context,
          fontSize * 0.9,
          min: 12,
          max: 18,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: showError
                    ? Center(
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: Responsive.scaled(
                            context,
                            cardH * 0.2,
                            min: 48,
                            max: 88,
                          ),
                          color: AppColors.accentOrange,
                        ),
                      )
                    : content!.isInternalVideo && content!.videoUrl != null
                        ? InternalVideoPlayer(videoUrl: content!.videoUrl!)
                        : ZoomableImage(
                            imageWidget: BookImage(
                              isSvg: content!.isSvg,
                              imageUrl: content!.imageUrl ?? '',
                            ),
                          ),
              ),
              Divider(
                thickness: 2,
                color: isZoomed || showError
                    ? Colors.transparent
                    : AppColors.mutedGray,
              ),
              Expanded(
                flex: 4,
                child: showError || content == null
                    ? const Center(
                        child: Text(
                          'Something went wrong! \nPlease try again later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Roboto'),
                        ),
                      )
                    : Scrollbar(
                        scrollbarOrientation: ScrollbarOrientation.left,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(right: 12, top: 8),
                          child: Column(
                            children: [
                              Text(
                                isZoomed ? '' : content!.syriacText,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: AppColors.primaryBlue,
                                  fontFamily: AppTheme.syriacFontFamily(
                                    content!.textLanguage,
                                  ),
                                ),
                                textDirection: TextDirection.rtl,
                                softWrap: true,
                              ),
                              if (!content!.isOnlySyriac)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    content!.companionText,
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontFamily: 'Roboto',
                                      fontSize: companionSize,
                                    ),
                                    textDirection: TextDirection.ltr,
                                    softWrap: true,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
