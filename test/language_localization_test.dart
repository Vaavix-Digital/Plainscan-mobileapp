import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/localization/app_translations.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/features/onboarding/screens/language_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StorageService Language Persistence Tests', () {
    test('Defaults to en when no language is saved', () async {
      final lang = await StorageService.getLanguage();
      expect(lang, 'en');
    });

    test('Persists and retrieves selected language correctly', () async {
      await StorageService.setLanguage('es');
      expect(await StorageService.getLanguage(), 'es');

      await StorageService.setLanguage('hi');
      expect(await StorageService.getLanguage(), 'hi');

      await StorageService.setLanguage('de');
      expect(await StorageService.getLanguage(), 'de');

      await StorageService.setLanguage('ja');
      expect(await StorageService.getLanguage(), 'ja');
    });
  });

  group('AppTranslations Dictionary Integrity Tests', () {
    final translations = AppTranslations();
    final keys = translations.keys;

    test('Contains all 12 primary supported language codes', () {
      final supportedCodes = ['en', 'es', 'fr', 'de', 'hi', 'ja', 'pt', 'zh', 'ar', 'it', 'ru', 'ko'];
      for (final code in supportedCodes) {
        expect(keys.containsKey(code), isTrue, reason: 'Missing translation dictionary for $code');
        expect(keys[code]!.isNotEmpty, isTrue, reason: 'Dictionary for $code is empty');
      }
    });

    test('Contains regional fallback mappings', () {
      expect(keys.containsKey('en_US'), isTrue);
      expect(keys.containsKey('es_ES'), isTrue);
      expect(keys.containsKey('fr_FR'), isTrue);
      expect(keys.containsKey('zh_CN'), isTrue);
    });

    test('Translates common keys across all 12 languages', () {
      expect(keys['es']!['Skip'], 'Omitir');
      expect(keys['fr']!['Skip'], 'Passer');
      expect(keys['de']!['Skip'], 'Überspringen');
      expect(keys['hi']!['Skip'], 'छोड़ें');
      expect(keys['ja']!['Skip'], 'スキップ');
      expect(keys['pt']!['Skip'], 'Pular');
      expect(keys['zh']!['Skip'], '跳过');
      expect(keys['ar']!['Skip'], 'تخطي');
      expect(keys['it']!['Skip'], 'Salta');
      expect(keys['ru']!['Skip'], 'Пропустить');
      expect(keys['ko']!['Skip'], '건너뛰기');
    });

    test('Scanner keys are localized across languages', () {
      expect(keys['es']!['Scan Preview'], 'Vista previa del escaneo');
      expect(keys['fr']!['Scan Preview'], 'Aperçu de la numérisation');
      expect(keys['de']!['Scan Preview'], 'Scan-Vorschau');
      expect(keys['hi']!['Scan Preview'], 'स्कैन पूर्वावलोकन');
      expect(keys['ja']!['Scan Preview'], 'スキャンプレビュー');
      expect(keys['zh']!['Scan Preview'], '扫描预览');
    });
  });

  group('Language Selection UI & Dynamic Locale Switching Tests', () {
    testWidgets('Selecting a language item changes active locale and updates stored preference', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          home: const LanguageSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(Get.locale?.languageCode, 'en');
      expect(find.text('Choose Your Language'), findsOneWidget);

      // Select Spanish
      final spanishOption = find.text('Spanish');
      expect(spanishOption, findsOneWidget);
      await tester.tap(spanishOption);
      await tester.pumpAndSettle();

      // Check locale switched to Spanish immediately
      expect(Get.locale?.languageCode, 'es');

      // Check persisted in storage
      expect(await StorageService.getLanguage(), 'es');

      // Now select German
      final germanOption = find.text('German');
      expect(germanOption, findsOneWidget);
      await tester.tap(germanOption);
      await tester.pumpAndSettle();

      expect(Get.locale?.languageCode, 'de');
      expect(await StorageService.getLanguage(), 'de');
    });

    testWidgets('GetX .tr dynamically translates text based on active locale', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Text('Skip'.tr),
                      Text('Subscription Plans'.tr),
                      Text('Scan Preview'.tr),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Subscription Plans'), findsOneWidget);
      expect(find.text('Scan Preview'), findsOneWidget);

      // Switch to French
      Get.updateLocale(const Locale('fr'));
      await tester.pumpAndSettle();

      expect(find.text('Passer'), findsOneWidget);
      expect(find.text('Plans d\'abonnement'), findsOneWidget);
      expect(find.text('Aperçu de la numérisation'), findsOneWidget);

      // Switch to Hindi
      Get.updateLocale(const Locale('hi'));
      await tester.pumpAndSettle();

      expect(find.text('छोड़ें'), findsOneWidget);
      expect(find.text('सदस्यता योजनाएं'), findsOneWidget);
      expect(find.text('स्कैन पूर्वावलोकन'), findsOneWidget);

      // Switch to Japanese
      Get.updateLocale(const Locale('ja'));
      await tester.pumpAndSettle();

      expect(find.text('スキップ'), findsOneWidget);
      expect(find.text('スキャンプレビュー'), findsOneWidget);
    });
  });
}
