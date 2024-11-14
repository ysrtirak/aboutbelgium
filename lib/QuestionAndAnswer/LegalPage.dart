import 'package:flutter/material.dart';
import 'package:aboutbelgium/QuestionAndAnswer//Links.dart';
import 'BasePage.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final Locale locale;

  const LegalPage({super.key, required this.title, required this.locale});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: title,
      locale: locale,
      getUrlForLocale: (locale) {
        switch (locale.languageCode) {
          case 'en':
            return en_LegalPage_Url;
          case 'fr':
            return fr_LegalPage_Url;
          case 'de':
            return de_LegalPage_Url;
          case 'nl':
            return nl_LegalPage_Url;
          case 'it':
            return it_LegalPage_Url;
          case 'es':
            return es_LegalPage_Url;
          case 'ar':
            return ar_LegalPage_Url;
          case 'tr':
            return tr_LegalPage_Url;
          case 'pt':
            return pt_LegalPage_Url;
          case 'pl':
            return pl_LegalPage_Url;
          default:
            return en_LegalPage_Url; // Return a default URL if none matches
        }
      },
    );
  }
}
