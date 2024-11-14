// const String AdsBanner = "ca-app-pub-3940256099942544/6300978111";
// const String AdsInterstitial = "ca-app-pub-3940256099942544/1033173712";
// const String AdsRewarded = "ca-app-pub-3940256099942544/5224354917";
//
//
// const String AdsIOSBanner = "ca-app-pub-3940256099942544/6300978111";
// const String AdsIOSInterstitial = "ca-app-pub-3940256099942544/1033173712";
// const String AdsIOSRewarded = "ca-app-pub-3940256099942544/5224354917";

import 'dart:io';

// orjinal idler
 String get AdsBanner {
  if (Platform.isAndroid) {
    return "ca-app-pub-4068786848730614/1159453905"; // Android Banner ID
  } else if (Platform.isIOS) {
    return "ca-app-pub-4068786848730614/2502634781"; // iOS Banner ID
  }
  return ""; // Eğer başka bir platformsa
}

 String get AdsInterstitial {
  if (Platform.isAndroid) {
    return "ca-app-pub-4068786848730614/8334763588"; // Android Interstitial ID
  } else if (Platform.isIOS) {
    return "ca-app-pub-4068786848730614/3217080538"; // iOS Interstitial ID
  }
  return ""; // Eğer başka bir platformsa
}


//Test Idler
// String get AdsBanner {
//   if (Platform.isAndroid) {
//     return "ca-app-pub-3940256099942544/6300978111"; // Android Banner ID
//   } else if (Platform.isIOS) {
//     return "ca-app-pub-3940256099942544/6300978111"; // iOS Banner ID
//   }
//   return ""; // Eğer başka bir platformsa
// }
//
// String get AdsInterstitial {
//   if (Platform.isAndroid) {
//     return "ca-app-pub-3940256099942544/1033173712"; // Android Interstitial ID
//   } else if (Platform.isIOS) {
//     return "ca-app-pub-3940256099942544/1033173712"; // iOS Interstitial ID
//   }
//   return ""; // Eğer başka bir platformsa
// }