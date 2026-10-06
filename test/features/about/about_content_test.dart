import 'package:bk_reader_v2/features/about/domain/about_content.dart';
import 'package:bk_reader_v2/features/about/presentation/pages/instructions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AboutContent', () {
    test('exposes non-empty branding and body copy', () {
      expect(AboutContent.title, 'BET KANU READER');
      expect(AboutContent.body, isNotEmpty);
      expect(AboutContent.appUsage, isNotEmpty);
      expect(AboutContent.sponsored, 'Sponsored By');
      expect(AboutContent.credits, 'Credits');
      expect(AboutContent.followUs, 'Follow us');
      expect(AboutContent.appInstructions, 'App Instructions');
    });

    test('credits lists stay aligned with legacy data', () {
      expect(AboutContent.jobTitles, hasLength(6));
      expect(AboutContent.names, hasLength(8));
      expect(AboutContent.names.first, 'Akkad Saadi');
      expect(AboutContent.jobTitles.first, 'Architect');
    });

    test('instruction steps cover the printed-book flow', () {
      expect(AboutContent.instructionSteps, hasLength(4));
      expect(
        AboutContent.instructionSteps,
        containsAll([
          'Go to BET KANU READER page',
          'Download the book you like to scan and read',
          'Print out the PDF book you downloaded',
          'Use the App to scan the codes',
        ]),
      );
    });
  });

  group('InstructionsPage', () {
    testWidgets('renders title, steps, and back button', (tester) async {
      final router = GoRouter(
        initialLocation: '/instructions',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/instructions',
            builder: (_, __) => const InstructionsPage(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text(AboutContent.appInstructions), findsOneWidget);
      for (final step in AboutContent.instructionSteps) {
        expect(find.text(step), findsOneWidget);
      }
      expect(find.text('Back'), findsOneWidget);
    });
  });
}
