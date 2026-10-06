import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/brand_button.dart';
import '../../domain/about_content.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final shortScreen = height < 700;
    final titleSize = Responsive.scaled(
      context,
      height * 0.025,
      min: 14,
      max: 22,
    );
    final bodySize = Responsive.scaled(
      context,
      height * 0.016,
      min: 12,
      max: 16,
    );
    final buttonHeight = Responsive.scaled(
      context,
      height * 0.055,
      min: 40,
      max: 52,
    );
    final buttonTextSize = Responsive.scaled(
      context,
      height * 0.018,
      min: 12,
      max: 16,
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.backgroundImage),
            fit: BoxFit.fill,
          ),
        ),
        child: SafeArea(
          child: ResponsiveBody(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Expanded(
                      flex: shortScreen ? 5 : 6,
                      child: _AboutCard(
                        titleSize: titleSize,
                        bodySize: bodySize,
                        screenHeight: height,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: Responsive.scaled(
                          context,
                          constraints.maxHeight * 0.18,
                          min: 100,
                          max: 140,
                        ),
                      ),
                      child: _SocialCard(
                        titleSize: titleSize,
                        screenHeight: height,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: BrandButton(
                              textSize: buttonTextSize,
                              icon: Icons.arrow_back,
                              color: Colors.grey,
                              width: double.infinity,
                              height: buttonHeight,
                              text: 'Back',
                              onPressed: () => context.pop(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BrandButton(
                              textSize: buttonTextSize,
                              icon: Icons.share_rounded,
                              color: AppColors.accentOrange,
                              width: double.infinity,
                              height: buttonHeight,
                              text: 'Share',
                              onPressed: () =>
                                  Share.share(AppConstants.shareMessage),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BrandButton(
                              textSize: buttonTextSize,
                              icon: Icons.thumb_up,
                              color: AppColors.primaryBlue,
                              width: double.infinity,
                              height: buttonHeight,
                              text: 'Rate',
                              onPressed: () {
                                StoreRedirect.redirect(
                                  androidAppId: AppConstants.androidAppId,
                                  iOSAppId: AppConstants.iosAppId,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.titleSize,
    required this.bodySize,
    required this.screenHeight,
  });

  final double titleSize;
  final double bodySize;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(width: 5, color: AppColors.accentOrange),
            bottom: BorderSide(width: 5, color: AppColors.primaryBlue),
          ),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            children: [
              _AboutText(
                text: AboutContent.title,
                color: AppColors.primaryBlue,
                textSize: titleSize,
                weight: FontWeight.bold,
              ),
              const SizedBox(height: 12),
              _AboutText(
                text: AboutContent.body,
                color: AppColors.bodyGray,
                textSize: bodySize,
                weight: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => context.push(AppRoutes.instructions),
                child: _AboutText(
                  text: AboutContent.appUsage,
                  color: AppColors.accentOrange,
                  textSize: Responsive.scaled(
                    context,
                    titleSize * 0.85,
                    min: 13,
                    max: 18,
                  ),
                  weight: FontWeight.w400,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  thickness: 3,
                  color: AppColors.dividerGray,
                ),
              ),
              _AboutText(
                text: AboutContent.sponsored,
                color: AppColors.primaryBlue,
                textSize: titleSize,
                weight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: Responsive.scaled(
                  context,
                  screenHeight * 0.065,
                  min: 40,
                  max: 56,
                ),
                width: Responsive.scaled(
                      context,
                      screenHeight * 0.065,
                      min: 40,
                      max: 56,
                    ) *
                    1.4,
                child: Image.asset(
                  AppConstants.capniLogo,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              _AboutText(
                text: AboutContent.credits,
                color: AppColors.primaryBlue,
                textSize: titleSize,
                weight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _deepGray(context, AboutContent.jobTitles[0]),
                        _lightGray(context, AboutContent.names[0]),
                        const SizedBox(height: 7),
                        _deepGray(context, AboutContent.jobTitles[1]),
                        _lightGray(context, AboutContent.names[1]),
                        _lightGray(context, AboutContent.names[2]),
                        _lightGray(context, AboutContent.names[3]),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _deepGray(context, AboutContent.jobTitles[2]),
                        _lightGray(context, AboutContent.names[4]),
                        const SizedBox(height: 7),
                        _deepGray(context, AboutContent.jobTitles[4]),
                        _lightGray(context, AboutContent.names[6]),
                        const SizedBox(height: 7),
                        _deepGray(context, AboutContent.jobTitles[5]),
                        _lightGray(context, AboutContent.names[7]),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lightGray(BuildContext context, String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      softWrap: true,
      style: TextStyle(
        color: AppColors.mutedGray,
        fontSize: Responsive.scaled(
          context,
          screenHeight * 0.018,
          min: 11,
          max: 15,
        ),
        fontFamily: 'Roboto',
      ),
    );
  }

  Widget _deepGray(BuildContext context, String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      softWrap: true,
      style: TextStyle(
        color: AppColors.deepGray,
        fontSize: Responsive.scaled(
          context,
          screenHeight * 0.02,
          min: 12,
          max: 16,
        ),
        fontWeight: FontWeight.w800,
        fontFamily: 'Roboto',
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.titleSize,
    required this.screenHeight,
  });

  final double titleSize;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = Responsive.scaled(
      context,
      screenHeight * 0.035,
      min: 22,
      max: 32,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(width: 5, color: AppColors.accentOrange),
            bottom: BorderSide(width: 5, color: AppColors.primaryBlue),
          ),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AboutText(
                text: AboutContent.followUs,
                color: AppColors.primaryBlue,
                textSize: titleSize,
                weight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SocialIcon(
                    radius: avatarRadius,
                    bg: AppColors.facebookBg,
                    asset: 'assets/images/facebook.svg',
                    url: AppConstants.facebookUrl,
                  ),
                  _SocialIcon(
                    radius: avatarRadius,
                    bg: AppColors.youtubeBg,
                    asset: 'assets/images/youtube.svg',
                    url: AppConstants.youtubeChannelUrl,
                  ),
                  _SocialIcon(
                    radius: avatarRadius,
                    bg: AppColors.webBg,
                    asset: 'assets/images/web.svg',
                    url: AppConstants.websiteUrl,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({
    required this.radius,
    required this.bg,
    required this.asset,
    required this.url,
  });

  final double radius;
  final Color bg;
  final String asset;
  final String url;

  @override
  Widget build(BuildContext context) {
    final iconSize = radius * 1.2;

    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: CircleAvatar(
          radius: radius * 0.92,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: radius * 0.82,
            backgroundColor: bg,
            child: SizedBox(
              height: iconSize,
              width: iconSize,
              child: SvgPicture.asset(
                asset,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutText extends StatelessWidget {
  const _AboutText({
    required this.text,
    required this.color,
    required this.textSize,
    required this.weight,
  });

  final String text;
  final Color color;
  final double textSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      softWrap: true,
      style: TextStyle(
        color: color,
        fontSize: textSize,
        fontWeight: weight,
        fontFamily: 'Roboto',
      ),
    );
  }
}
