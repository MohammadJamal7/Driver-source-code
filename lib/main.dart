import 'dart:developer';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/global_setting_conroller.dart';
import 'package:driver/firebase_options.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/ui/splash_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import 'controller/vehicle_information_controller.dart';
import 'services/localization_service.dart';
import 'themes/Styles.dart';
import 'utils/Preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase مع معالجة الأخطاء المحسّنة
  await _initializeFirebase();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log('❌ Flutter Error: ${details.exception}', stackTrace: details.stack);
    print('❌ Flutter Error: ${details.exception}');
  };

  await Preferences.initPref();

  EasyLoading.instance
    ..displayDuration = const Duration(seconds: 2)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..backgroundColor = AppColors.darkModePrimary
    ..textColor = Colors.black
    ..indicatorColor = Colors.black
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;

  await GetStorage.init();
  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  try {
    // التحقق من وجود تطبيق Firebase افتراضي
    FirebaseApp? defaultApp;

    try {
      defaultApp = Firebase.app();
      log('✅ Firebase app already exists');
    } catch (e) {
      // التطبيق الافتراضي غير موجود، سيتم إنشاؤه
      log('ℹ️ Default Firebase app not found, initializing...');
    }

    // إذا لم يكن هناك تطبيق افتراضي، قم بإنشائه
    if (defaultApp == null) {
      defaultApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 10), // زيادة المهلة الزمنية
        onTimeout: () {
          throw Exception(
              'انتهت مهلة تهيئة Firebase - تحقق من الاتصال بالإنترنت');
        },
      );
      log('✅ Firebase initialized successfully');
    }

    // التحقق من حالة Firebase
    if (defaultApp.options.projectId.isNotEmpty) {
      log('✅ Firebase is ready with project: ${defaultApp.options.projectId}');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      log('⚠️ Firebase app already exists, continuing...');
    } else {
      log('❌ Firebase initialization failed: ${e.message}', error: e);
      rethrow;
    }
  } catch (e, stack) {
    log('❌ فشل في تهيئة Firebase', error: e, stackTrace: stack);
    // لا نرمي الخطأ مرة أخرى لتجنب توقف التطبيق
    // rethrow;
  }
}

Future<bool> _checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com').timeout(
      const Duration(seconds: 5),
    );
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  } catch (e) {
    log('خطأ في التحقق من الاتصال بالإنترنت', error: e);
    return false;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initApp();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initApp() async {
    await getCurrentAppTheme();
    _checkConnectionPeriodically();
  }

  void _checkConnectionPeriodically() async {
    // التحقق من الاتصال كل 10 ثواني
    Future.delayed(const Duration(seconds: 10), () async {
      if (mounted) {
        // التحقق من أن الـ widget ما زال موجود
        final isConnected = await _checkInternetConnection();
        if (isConnected != _isOnline) {
          setState(() {
            _isOnline = isConnected;
          });
          if (isConnected) {
            _retryFirebaseOperations();
          }
        }
        _checkConnectionPeriodically(); // استدعاء ذاتي للتحقق الدوري
      }
    });
  }

  Future<void> _retryFirebaseOperations() async {
    try {
      if (Firebase.apps.isNotEmpty &&
          FirebaseAuth.instance.currentUser != null) {
        if (Get.isRegistered<GlobalSettingController>()) {
          await Get.find<GlobalSettingController>().notificationInit();
        }
      }
    } catch (e) {
      log('فشل في إعادة محاولة عمليات Firebase', error: e);
    }
  }

  getCurrentAppTheme() async {
    try {
      themeChangeProvider.darkTheme =
          await themeChangeProvider.darkThemePreference.getTheme();
    } catch (e) {
      log('فشل في الحصول على تفضيلات السمة', error: e);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeChangeProvider,
      child: Consumer<DarkThemeProvider>(
        builder: (context, value, child) {
          return GetMaterialApp(
            title: "كابتن ودني",
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(
              themeChangeProvider.darkTheme == 0
                  ? true
                  : themeChangeProvider.darkTheme == 1
                      ? false
                      : themeChangeProvider.getSystemThem(),
              context,
            ),
            localizationsDelegates: const [
              CountryLocalizations.delegate,
            ],
            locale: LocalizationService.locale,
            fallbackLocale: LocalizationService.locale,
            translations: LocalizationService(),
            builder: (context, child) {
              if (!Get.isRegistered<VehicleInformationController>()) {
                Get.put(VehicleInformationController());
              }
              return FlutterEasyLoading(child: child);
            },
            home: FutureBuilder<bool>(
              future: _checkInternetConnection(),
              builder: (context, snapshot) {
                final isOnline = snapshot.data ?? true;

                return GetX<GlobalSettingController>(
                  init: GlobalSettingController(),
                  builder: (controller) {
                    if (controller.isLoading.value) {
                      return Constant.loader(context);
                    }

                    if (!isOnline) {
                      return _buildOfflineUI();
                    }

                    return const SplashScreen();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineUI() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 50),
            const SizedBox(height: 20),
            Text(
              'لا يوجد اتصال بالإنترنت',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('حاول مرة أخرى'),
            ),
          ],
        ),
      ),
    );
  }
}
