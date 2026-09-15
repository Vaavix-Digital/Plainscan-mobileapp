import 'package:get/get.dart';
import 'package:plainscan/core/localization/translations/ar.dart';
import 'package:plainscan/core/localization/translations/de.dart';
import 'package:plainscan/core/localization/translations/en.dart';
import 'package:plainscan/core/localization/translations/es.dart';
import 'package:plainscan/core/localization/translations/fr.dart';
import 'package:plainscan/core/localization/translations/hi.dart';
import 'package:plainscan/core/localization/translations/it.dart';
import 'package:plainscan/core/localization/translations/ja.dart';
import 'package:plainscan/core/localization/translations/ko.dart';
import 'package:plainscan/core/localization/translations/pt.dart';
import 'package:plainscan/core/localization/translations/ru.dart';
import 'package:plainscan/core/localization/translations/zh.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': enTranslations,
        'en_US': enTranslations,
        'es': esTranslations,
        'es_ES': esTranslations,
        'fr': frTranslations,
        'fr_FR': frTranslations,
        'de': deTranslations,
        'de_DE': deTranslations,
        'hi': hiTranslations,
        'hi_IN': hiTranslations,
        'ja': jaTranslations,
        'ja_JP': jaTranslations,
        'pt': ptTranslations,
        'pt_PT': ptTranslations,
        'pt_BR': ptTranslations,
        'zh': zhTranslations,
        'zh_CN': zhTranslations,
        'ar': arTranslations,
        'ar_AE': arTranslations,
        'it': itTranslations,
        'it_IT': itTranslations,
        'ru': ruTranslations,
        'ru_RU': ruTranslations,
        'ko': koTranslations,
        'ko_KR': koTranslations,
      };
}
