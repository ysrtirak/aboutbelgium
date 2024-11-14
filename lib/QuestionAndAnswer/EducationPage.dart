import 'package:flutter/material.dart';
import 'package:aboutbelgium/QuestionAndAnswer//Links.dart';
import 'BasePage.dart';

class EducationPage extends StatelessWidget {
  final String title;
  final Locale locale;

  const EducationPage({super.key, required this.title, required this.locale});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: title,
      locale: locale,
      getUrlForLocale: (locale) {
        switch (locale.languageCode) {
          case 'en':
            return en_EducationPage_Url;
          case 'fr':
            return fr_EducationPage_Url;
          case 'de':
            return de_EducationPage_Url;
          case 'nl':
            return nl_EducationPage_Url;
          case 'it':
            return it_EducationPage_Url;
          case 'es':
            return es_EducationPage_Url;
          case 'ar':
            return ar_EducationPage_Url;
          case 'tr':
            return tr_EducationPage_Url;
          case 'pt':
            return pt_EducationPage_Url;
          case 'pl':
            return pl_EducationPage_Url;
          default:
            return en_EducationPage_Url; // Return a default URL if none matches
        }
      },
    );
  }
}
