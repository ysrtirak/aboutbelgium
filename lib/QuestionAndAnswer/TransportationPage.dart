import 'package:flutter/material.dart';
import 'package:aboutbelgium/QuestionAndAnswer//Links.dart';
import 'BasePage.dart';

class TransportationPage extends StatelessWidget {
  final String title;
  final Locale locale;

  const TransportationPage({super.key, required this.title, required this.locale});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: title,
      locale: locale,
      getUrlForLocale: (locale) {
        switch (locale.languageCode) {
          case 'en':
            return en_TransportationPage_Url;
          case 'fr':
            return fr_TransportationPage_Url;
          case 'de':
            return de_TransportationPage_Url;
          case 'nl':
            return nl_TransportationPage_Url;
          case 'it':
            return it_TransportationPage_Url;
          case 'es':
            return es_TransportationPage_Url;
          case 'ar':
            return ar_TransportationPage_Url;
          case 'tr':
            return tr_TransportationPage_Url;
          case 'pt':
            return pt_TransportationPage_Url;
          case 'pl':
            return pl_TransportationPage_Url;
          default:
            return en_TransportationPage_Url; // Return a default URL if none matches
        }
      },
    );
  }
}
