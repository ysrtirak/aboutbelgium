import 'package:flutter/material.dart';
import 'package:aboutbelgium/QuestionAndAnswer//Links.dart';
import 'BasePage.dart';
class EmploymentPage extends StatelessWidget {
  final String title;
  final Locale locale;

  const EmploymentPage({super.key, required this.title, required this.locale});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: title,
      locale: locale,
      getUrlForLocale: (locale) {
      switch (locale.languageCode) {
        case 'en':
          return en_Employment_Url;
        case 'fr':
          return fr_Employment_Url;
        case 'de':
          return de_Employment_Url;
        case 'nl':
          return nl_Employment_Url;
        case 'it':
          return it_Employment_Url;
        case 'es':
          return es_Employment_Url;
        case 'ar':
          return ar_Employment_Url;
        case 'tr':
          return tr_Employment_Url;
        case 'pt':
          return pt_Employment_Url;
        case 'pl':
          return pl_Employment_Url;
        default:
          return en_Employment_Url; // Return a default URL if none matches

        }
      },
    );
  }
}
