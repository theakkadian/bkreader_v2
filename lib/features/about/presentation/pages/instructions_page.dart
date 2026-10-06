import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/brand_button.dart';
import '../../domain/about_content.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final titleSize = Responsive.scaled(
      context,
      height * 0.028,
      min: 18,
      max: 24,
    );
    final stepLabelSize = Responsive.scaled(
      context,
      height * 0.022,
      min: 14,
      max: 18,
    );
    final stepBodySize = Responsive.scaled(
      context,
      height * 0.018,
      min: 12,
      max: 15,
    );
    final buttonHeight = Responsive.scaled(
      context,
      height * 0.055,
      min: 40,
      max: 52,
    );
    final buttonTextSize = Responsive.scaled(
      context,
      height * 0.02,
      min: 13,
      max: 17,
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
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Column(
                          children: [
                            Text(
                              AboutContent.appInstructions,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const SizedBox(height: 20),
                            for (var i = 0;
                                i < AboutContent.instructionSteps.length;
                                i++) ...[
                              Text(
                                'Step ${i + 1}:',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: stepLabelSize,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AboutContent.instructionSteps[i],
                                textAlign: TextAlign.center,
                                softWrap: true,
                                style: TextStyle(
                                  color: AppColors.accentOrange,
                                  fontSize: stepBodySize,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                BrandButton(
                  height: buttonHeight,
                  textSize: buttonTextSize,
                  width: double.infinity,
                  icon: Icons.arrow_back,
                  text: 'Back',
                  color: Colors.grey,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
