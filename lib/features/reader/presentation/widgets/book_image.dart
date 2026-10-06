import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/null_string.dart';

class BookImage extends StatelessWidget {
  const BookImage({
    super.key,
    required this.isSvg,
    required this.imageUrl,
  });

  final bool isSvg;
  final String imageUrl;

  bool get _hasUrl => imageUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!_hasUrl) {
      child = Image.asset(
        AppConstants.placeholderImage,
        fit: BoxFit.contain,
      );
    } else {
      child = isSvg ? _svg() : _raster();
    }

    return SizedBox.expand(child: child);
  }

  Widget _svg() {
    return SvgPicture.network(
      sanitizeMediaUrl(imageUrl),
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.loaderBlue),
      ),
    );
  }

  Widget _raster() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Image.network(
        sanitizeMediaUrl(imageUrl),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          AppConstants.placeholderImage,
          fit: BoxFit.contain,
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }
}
