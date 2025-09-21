import 'dart:developer';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constant/constant.dart';
import '../../constant/show_toast_dialog.dart';
import '../../model/driver_user_model.dart';
import '../../utils/Preferences.dart';
import '../../utils/fire_store_utils.dart';
import '../auth_screen/login_screen.dart';
import '../dashboard_screen.dart';
import '../on_boarding_screen.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    log("init");
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkForUpdates();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> checkForUpdates() async {
    // Add delay to ensure iOS platform is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    String currentVersion = await VersionChecker.getInstalledVersion();
    String? storeVersion = await VersionChecker.getStoreVersion();
    final String storePrintable = storeVersion ?? '<null>';
    log("🔎 Version check (raw) → current: '$currentVersion', store: '$storePrintable'");
    // Ensure visibility in Flutter console
    print("🔎 Version check (raw) → current: '$currentVersion', store: '$storePrintable'");

    // If we cannot fetch store version (e.g., Firestore read blocked pre-login), don't block.
    if (storeVersion == null || storeVersion.trim().isEmpty) {
      log("⚠️ Store version unavailable, skipping forced update.");
      print("⚠️ Store version unavailable, skipping forced update.");
      _navigateToNextScreen();
      return;
    }

    final bool upToDate = VersionChecker.isUpToDate(currentVersion, storeVersion);
    log("📐 Comparison result → upToDate: $upToDate (installed vs store)");
    print("📐 Comparison result → upToDate: $upToDate (installed vs store)");
    if (upToDate) {
      log("✅ Proceeding: installed version is up-to-date or newer than store.");
      print("✅ Proceeding: installed version is up-to-date or newer than store.");
      _navigateToNextScreen();
    } else {
      log("⬆️ Blocking: installed version is older than store, showing update dialog.");
      print("⬆️ Blocking: installed version is older than store, showing update dialog.");
      _showUpdateDialog();
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text("تحديث متاح"),
          content: Text("يرجى تحديث التطبيق للمتابعة"),
          actions: [
            TextButton(
              onPressed: launchUpdateUrl,
              child: Text("تحديث الآن"),
            ),
          ],
        );
      },
    );
  }

  void launchUpdateUrl() async {
    const android =
        'https://play.google.com/store/apps/details?id=com.wdni.drivers';
    const ios =
        'https://apps.apple.com/us/app/كابتن-ودني-سوق-وأكسب-مع-ودني/id6747668310';
    final uri = Platform.isIOS ? Uri.parse(ios) : Uri.parse(android);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ShowToastDialog.showToast("Could not launch".tr);
    }
  }

  void _navigateToNextScreen() async {
    if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
      Get.offAll(() => const OnBoardingScreen());
    } else {
      loginFirebase();
    }
  }

  void loginFirebase() async {
    bool isLogin = await FireStoreUtils.isLogin();
    if (isLogin == true) {
      await FireStoreUtils.getDriverProfile(
              FirebaseAuth.instance.currentUser!.uid)
          .then(
        (value) {
          if (value != null) {
            DriverUserModel userModel = value;
            bool isPlanExpire = false;
            if (userModel.subscriptionPlan?.id != null) {
              if (userModel.subscriptionExpiryDate == null) {
                if (userModel.subscriptionPlan?.expiryDay == '-1') {
                  isPlanExpire = false;
                } else {
                  isPlanExpire = true;
                }
              } else {
                DateTime expiryDate =
                    userModel.subscriptionExpiryDate!.toDate();
                isPlanExpire = expiryDate.isBefore(DateTime.now());
              }
            } else {
              isPlanExpire = true;
            }
            if (userModel.subscriptionPlanId == null || isPlanExpire == true) {
              if (Constant.adminCommission?.isEnabled == false &&
                  Constant.isSubscriptionModelApplied == false) {
                Get.offAll(() => const DashBoardScreen());
              } else {
                Get.offAll(() => const DashBoardScreen());
              }
            } else {
              Get.offAll(() => const DashBoardScreen());
            }
          }
        },
      );
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black);
  }
}

class VersionChecker {
  static Future<String> getInstalledVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      log('❌ Failed to get package info: $e');
      return '1.0.0'; // Fallback version
    }
  }

  static Future<String> getStoreVersion() async {
    try {
      final v = await FireStoreUtils.getStoreVersion();
      return v;
    } catch (e) {
      // Do not return toast text as a version. Return empty so caller can skip blocking.
      log("❗ Failed to fetch store version: $e");
      return "";
    }
  }

  static bool isUpToDate(String current, String latest) {
    String c = _normalize(current);
    String l = _normalize(latest);

    // Special-case: if one is single-part (e.g., '15') and the other is multi-part (e.g., '1.0.15'),
    // compare the single number against the other's last segment (patch).
    final cp = _parts(c);
    final lp = _parts(l);

    if ((cp.length == 1 && lp.length > 1) || (lp.length == 1 && cp.length > 1)) {
      final int single = (cp.length == 1 ? cp.first : lp.first);
      final List<int> multi = (cp.length > 1 ? cp : lp);
      final int multiPatch = multi.isNotEmpty ? multi.last : 0;
      log("🔁 Mixed format compare → single: $single vs multiPatch: $multiPatch");
      print("🔁 Mixed format compare → single: $single vs multiPatch: $multiPatch");
      if (single < multiPatch) {
        log("➡️ Mixed compare: $single < $multiPatch → needs update (false)");
        print("➡️ Mixed compare: $single < $multiPatch → needs update (false)");
        return false;
      }
      if (single > multiPatch) {
        log("➡️ Mixed compare: $single > $multiPatch → installed newer (true)");
        print("➡️ Mixed compare: $single > $multiPatch → installed newer (true)");
        return true;
      }
      log("➡️ Mixed compare equal → up-to-date (true)");
      print("➡️ Mixed compare equal → up-to-date (true)");
      return true;
    }

    final weightCurrent = _weightFromParts(cp);
    final weightLatest = _weightFromParts(lp);

    log("🔧 Normalized versions → current: '$c' weight: $weightCurrent | latest: '$l' weight: $weightLatest");
    print("🔧 Normalized versions → current: '$c' weight: $weightCurrent | latest: '$l' weight: $weightLatest");

    if (weightCurrent < weightLatest) {
      log("➡️ Weighted compare: $weightCurrent < $weightLatest → needs update (false)");
      print("➡️ Weighted compare: $weightCurrent < $weightLatest → needs update (false)");
      return false;
    }
    if (weightCurrent > weightLatest) {
      log("➡️ Weighted compare: $weightCurrent > $weightLatest → installed newer (true)");
      print("➡️ Weighted compare: $weightCurrent > $weightLatest → installed newer (true)");
      return true;
    }
    log("➡️ Weights equal → up-to-date (true)");
    print("➡️ Weights equal → up-to-date (true)");
    return true;
  }

  static String _normalize(String v) {
    // Keep only digits and dots, trim, collapse multiple dots
    final cleaned = v.trim().replaceAll(RegExp(r'[^0-9\.]'), '');
    return cleaned.isEmpty ? '0' : cleaned;
  }

  static List<int> _parts(String v) {
    return v.split('.')
        .where((e) => e.isNotEmpty)
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
  }

  // Convert semantic version to a weighted integer for comparison.
  // e.g., 1.2.3 -> 1*1e6 + 2*1e3 + 3 = 1002003
  // Single number like '15' becomes 15 (treated as patch level).
  static int _weightFromParts(List<int> parts) {
    final major = parts.isNotEmpty ? parts[0] : 0;
    final minor = parts.length > 1 ? parts[1] : 0;
    final patch = parts.length > 2 ? parts[2] : (parts.length == 1 ? parts[0] : 0);
    final isSingle = parts.length == 1;
    final m = isSingle ? 0 : major;
    final n = isSingle ? 0 : minor;
    final p = isSingle ? parts[0] : patch;
    return m * 1000000 + n * 1000 + p;
  }
}
