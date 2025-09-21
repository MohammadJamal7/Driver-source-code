import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:driver/constant/constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/model/currency_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/language_model.dart';
import 'package:driver/services/localization_service.dart';
import 'package:driver/utils/Preferences.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GlobalSettingController extends GetxController {
  RxBool isLoading = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Delay initialization to ensure Firebase is ready
    _delayedInit();
  }

  void _delayedInit() async {
    // Wait for Firebase to be ready
    await Future.delayed(const Duration(milliseconds: 1000));
    
    try {
      await notificationInit();
      await getCurrentCurrency();
      isLoading.value = false;
    } catch (e) {
      log('❌ GlobalSettingController initialization failed', error: e);
      isLoading.value = false; // Don't block the app
    }
  }

  getCurrentCurrency() async {
    if (Preferences.getString(Preferences.languageCodeKey)
        .toString()
        .isNotEmpty) {
      LanguageModel? languageModel = Constant.getLanguage();
      LocalizationService().changeLocale(languageModel!.code.toString());
    } else {
      await FireStoreUtils.getLanguage().then((value) {
        if (value != null) {
          List<LanguageModel> languageList = value;
          if (languageList
              .where((element) => element.isDefault == true)
              .isNotEmpty) {
            LanguageModel languageModel =
                languageList.firstWhere((element) => element.isDefault == true);
            Preferences.setString(
                Preferences.languageCodeKey, jsonEncode(languageModel));
            LocalizationService().changeLocale(languageModel.code.toString());
          }
        }
      });
    }

    await FireStoreUtils().getCurrency().then((value) {
      if (value != null) {
        Constant.currencyModel = value;
      } else {
        Constant.currencyModel = CurrencyModel(
            id: "",
            code: "USD",
            decimalDigits: 2,
            enable: true,
            name: "US Dollar",
            symbol: "\$",
            symbolAtRight: false);
      }
    });

    FireStoreUtils().getGoogleAPIKey();

    isLoading.value = false;
    update();
  }

  NotificationService notificationService = NotificationService();

  notificationInit() async {
    try {
      // Use connectivity_plus for more reliable connection detection
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        log("⛔ لا يوجد اتصال بالإنترنت، سيتم تخطي تهيئة الإشعارات");
        return;
      }
      
      // Additional verification with actual network request
      final result = await InternetAddress.lookup('google.com');
      final hasConnection =
          result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (!hasConnection) {
        log("⛔ لا يوجد اتصال بالإنترنت، سيتم تخطي تهيئة الإشعارات");
        return;
      }

      await notificationService.initInfo();

      String token = await NotificationService.getToken();
      log(":::::::FCM TOKEN:::::: $token");

      if (FirebaseAuth.instance.currentUser != null) {
        await FireStoreUtils.getDriverProfile(
                FirebaseAuth.instance.currentUser!.uid)
            .then((value) {
          if (value != null) {
            DriverUserModel driverUserModel = value;
            driverUserModel.fcmToken = token;
            FireStoreUtils.updateDriverUser(driverUserModel);
          }
        });
      }
    } catch (e, stack) {
      log("❌ خطأ أثناء تهيئة الإشعارات", error: e, stackTrace: stack);
    }
  }
}
