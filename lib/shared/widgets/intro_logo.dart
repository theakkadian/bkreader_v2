import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

class IntroLogo extends StatelessWidget {
  const IntroLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final taglineSize = Responsive.scaled(
      context,
      height * 0.018,
      min: 13,
      max: 18,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          width: 5,
                          color: AppColors.accentOrange,
                        ),
                        bottom: BorderSide(
                          width: 5,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.12,
                          vertical: constraints.maxHeight * 0.08,
                        ),
                        child: Image.asset(
                          AppConstants.logoImage,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    ' ܩܪܘܢܬܐ ܕܒܢܬ ܥܐܢܘ \n ܬܘܠܚܡܐ ܡܥܕܪܢܐ ܠܝܘܠܦܢܐ ܕܠܫܢܐ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: taglineSize,
                      fontFamily: 'ClassicSyriac',
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
