import 'package:flutter/material.dart';
import 'package:aboutbelgium/QuestionAndAnswer//Links.dart';
import 'BasePage.dart';

class HealthcarePage extends StatelessWidget {
  final String title;
  final Locale locale;

  const HealthcarePage({super.key, required this.title, required this.locale});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: title,
      locale: locale,
      getUrlForLocale: (locale) {
        switch (locale.languageCode) {
          case 'en':
            return en_HealthcarePage_Url;
          case 'fr':
            return fr_HealthcarePage_Url;
          case 'de':
            return de_HealthcarePage_Url;
          case 'nl':
            return nl_HealthcarePage_Url;
          case 'it':
            return it_HealthcarePage_Url;
          case 'es':
            return es_HealthcarePage_Url;
          case 'ar':
            return ar_HealthcarePage_Url;
          case 'tr':
            return tr_HealthcarePage_Url;
          case 'pt':
            return pt_HealthcarePage_Url;
          case 'pl':
            return pl_HealthcarePage_Url;
          default:
            return en_HealthcarePage_Url; // Return a default URL if none matches
        }
      },
    );
  }
}
