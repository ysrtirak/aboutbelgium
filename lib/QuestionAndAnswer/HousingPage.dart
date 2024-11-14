import 'package:flutter/material.dart';
import 'package:aboutbelgium/QuestionAndAnswer//Links.dart';
import 'BasePage.dart';

class HousingPage extends StatelessWidget {
  final String title;
  final Locale locale;

  const HousingPage({super.key, required this.title, required this.locale});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: title,
      locale: locale,
      getUrlForLocale: (locale) {
        switch (locale.languageCode) {
          case 'en':
            return en_Housing_Url;
          case 'fr':
            return fr_Housing_Url;
          case 'de':
            return de_Housing_Url;
          case 'nl':
            return nl_Housing_Url;
          case 'it':
            return it_Housing_Url;
          case 'es':
            return es_Housing_Url;
          case 'ar':
            return ar_Housing_Url;
          case 'tr':
            return tr_Housing_Url;
          case 'pt':
            return pt_Housing_Url;
          case 'pl':
            return pl_Housing_Url;
          default:
            return en_Housing_Url; // Return a default URL if none matches
        }
      },
    );
  }
}
