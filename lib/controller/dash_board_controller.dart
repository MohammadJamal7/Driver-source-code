import 'dart:async';

import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/ui/bank_details/bank_details_screen.dart';
import 'package:driver/ui/chat_screen/inbox_screen.dart';
import 'package:driver/ui/freight/freight_screen.dart';
import 'package:driver/ui/home_screens/home_screen.dart';
import 'package:driver/ui/intercity_screen/home_intercity_screen.dart';
import 'package:driver/ui/online_registration/online_registartion_screen.dart';
import 'package:driver/ui/profile_screen/profile_screen.dart';
import 'package:driver/ui/settings_screen/setting_screen.dart';
import 'package:driver/ui/subscription_plan_screen/subscription_history.dart';
import 'package:driver/ui/subscription_plan_screen/subscription_list_screen.dart';
import 'package:driver/ui/vehicle_information/vehicle_information_screen.dart';
import 'package:driver/ui/wallet/wallet_screen.dart';
import 'package:driver/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant/collection_name.dart';
import '../model/banner_model.dart';
import '../model/driver_user_model.dart';
import '../utils/fire_store_utils.dart';

class DashBoardController extends GetxController {
  RxList<DrawerItem> drawerItems = <DrawerItem>[].obs;

  RxList bannerList = <BannerModel>[].obs;
  final PageController pageController =
      PageController(viewportFraction: 0.96, keepPage: true);

  getDrawerItemWidget(int pos) {
    if (Constant.isSubscriptionModelApplied == true) {
      switch (pos) {
        case 0:
          return const HomeScreen();
        // case 1:
        //   return const OrderScreen();
        case 1:
          return const HomeIntercityScreen();
        // case 2:
        //   return const OrderIntercityScreen();
        case 2:
          return const FreightScreen();
        case 3:
          return const WalletScreen();
        case 4:
          return const BankDetailsScreen();
        case 5:
          return const InboxScreen();
        case 6:
          return const ProfileScreen();
        case 7:
          if (Constant.isVerifyDocument == true) {
            return const OnlineRegistrationScreen();
          } else {
            return VehicleInformationScreen();
          }
        case 8:
          return Constant.isVerifyDocument == true
              ? VehicleInformationScreen()
              : const SettingScreen();
        case 9:
          //return Constant.isVerifyDocument == true ? const SettingScreen() : const SubscriptionListScreen();
          return const SettingScreen();
        // case 10:
        //   return Constant.isVerifyDocument == true ? const SubscriptionListScreen() : const SubscriptionHistory();
        case 11:
          //return Constant.isVerifyDocument == true ? const SubscriptionHistory() : const Text("Error");
          return const Text("Error");
        default:
          return const Text("Error");
      }
    } else {
      switch (pos) {
        case 0:
          return const HomeScreen();
        // case 1:
        //   return const OrderScreen();
        case 1:
          return const HomeIntercityScreen();
        // case 2:
        //   return const OrderIntercityScreen();
        case 2:
          return const FreightScreen();
        case 3:
          return const WalletScreen();
        case 4:
          return const BankDetailsScreen();
        case 5:
          return const InboxScreen();
        case 6:
          return const ProfileScreen();
        case 7:
          if (Constant.isVerifyDocument == true) {
            return const OnlineRegistrationScreen();
          } else {
            return VehicleInformationScreen();
          }
        case 8:
          return Constant.isVerifyDocument == true
              ? VehicleInformationScreen()
              : const SettingScreen();
        case 9:
          return const SettingScreen();
        case 10:
          return const Text("Error");
        default:
          return const Text("Error");
      }
    }
  }

  RxInt selectedDrawerIndex = 0.obs;

  onSelectItem(int index) async {
    // Prevent guest users from navigating to restricted pages via the drawer
    if (Constant.isGuestUser) {
      // Allow Home (0), Settings, and Log out.
      // Settings index is 9 when documents are verified, else 8.
      // Log out index is 10 when documents are verified, else 9.
      final settingsIndex = Constant.isVerifyDocument == true ? 9 : 8;
      final logoutIndex = Constant.isVerifyDocument == true ? 10 : 9;
      // Include Profile at index 6
      final allowed = {0, 6, settingsIndex, logoutIndex};
      if (!allowed.contains(index)) {
        ShowToastDialog.showToast('Available for registered drivers only');
        Get.back();
        return;
      }
    }

    if (Constant.isSubscriptionModelApplied == true) {
      if (Constant.isVerifyDocument == true ? index == 10 : index == 9) {
        await FirebaseAuth.instance.signOut();
        Get.offAll(const LoginScreen());
      } else {
        selectedDrawerIndex.value = index;
      }
    } else {
      if (Constant.isVerifyDocument == true ? index == 10 : index == 9) {
        await FirebaseAuth.instance.signOut();
        Get.offAll(const LoginScreen());
      } else {
        selectedDrawerIndex.value = index;
      }
    }

    Get.back();
  }

  @override
  void onInit() {
    // TODO: implement onInit
    // If an authenticated user exists, ensure guest mode is OFF
    if (FirebaseAuth.instance.currentUser != null) {
      Constant.isGuestUser = false;
    }
    if (!Constant.isGuestUser) {
      // Set up real-time listener for driver profile changes
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        FireStoreUtils.fireStore
            .collection(CollectionName.driverUsers)
            .doc(currentUser.uid)
            .snapshots()
            .listen((event) {
          if (event.exists && event.data() != null) {
            DriverUserModel driverModel =
                DriverUserModel.fromJson(event.data()!);
            print("----- driver id ${driverModel.id}");

            // Update drawer index based on service type changes
            _updateDrawerIndexForServiceType(driverModel.serviceId);
          }
        });
      } else {
        print("🚫 المستخدم غير مسجل دخول في DashBoardController");
      }
    }
    setDrawerList();
    getLocation();
    super.onInit();
    // getServiceType();
  }

  // Helper method to update drawer index based on service type
  void _updateDrawerIndexForServiceType(String? serviceId) {
    if (serviceId != null && serviceId.isNotEmpty) {
      // freight
      if (serviceId == "Kn2VEnPI3ikF58uK8YqY") {
        selectedDrawerIndex.value = 2;
        print(
            "🔄 Service type changed to Freight - switching to drawer index 2");
      }
      // intercity
      else if (serviceId == 'RrfW48PJVmyzjxrNN8j1' ||
          serviceId == 'XkIwHouQV5jWJfxIgFuw' ||
          serviceId == 'PN10GNOtRkRMA2CmW5pS') {
        selectedDrawerIndex.value = 1;
        print(
            "🔄 Service type changed to Intercity - switching to drawer index 1");
      }
      // regular orders (default)
      else {
        selectedDrawerIndex.value = 0;
        print(
            "🔄 Service type changed to Regular - switching to drawer index 0");
      }
    }
  }
  // getServiceType() async{
  //   await FireStoreUtils.getBanner().then((value) {
  //     bannerList.value = value;
  //   });
  //   startAutoScroll();
  // }
  //
  // Timer? bannerTimer;
  // void startAutoScroll() {
  //   bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
  //     if (pageController.hasClients && bannerList.isNotEmpty) {
  //       int nextPage = pageController.page!.round() + 1;
  //
  //       if (nextPage >= bannerList.length) {
  //         nextPage = 0;
  //       }
  //
  //       pageController.animateToPage(
  //         nextPage,
  //         duration: const Duration(milliseconds: 500),
  //         curve: Curves.easeInOut,
  //       );
  //     }
  //   });
  // }

  setDrawerList() {
    if (Constant.isSubscriptionModelApplied == true) {
      drawerItems.value = [
        DrawerItem('City'.tr, "assets/icons/ic_city.svg"),
        // DrawerItem('Rides'.tr, "assets/icons/ic_order.svg"),
        DrawerItem('OutStation'.tr, "assets/icons/ic_intercity.svg"),
        // DrawerItem('OutStation Rides'.tr, "assets/icons/ic_order.svg"),
        DrawerItem('Freight'.tr, "assets/icons/ic_freight.svg"),
        DrawerItem('My Wallet'.tr, "assets/icons/ic_wallet.svg"),
        DrawerItem('Bank Details'.tr, "assets/icons/ic_profile.svg"),
        DrawerItem('Inbox'.tr, "assets/icons/ic_inbox.svg"),
        DrawerItem('Profile'.tr, "assets/icons/ic_profile.svg"),
        if (Constant.isVerifyDocument == true)
          DrawerItem('Online Registration'.tr, "assets/icons/ic_document.svg"),
        DrawerItem('Vehicle Information'.tr, "assets/icons/ic_city.svg"),
        DrawerItem('Settings'.tr, "assets/icons/ic_settings.svg"),
        // DrawerItem('Subscription'.tr, "assets/icons/ic_subscription.svg"),
        // DrawerItem('Subscription History'.tr, "assets/icons/ic_subscription_history.svg"),
        DrawerItem('Log out'.tr, "assets/icons/ic_logout.svg"),
      ];
    } else {
      drawerItems.value = [
        DrawerItem('City'.tr, "assets/icons/ic_city.svg"),
        // DrawerItem('Rides'.tr, "assets/icons/ic_order.svg"),
        DrawerItem('OutStation'.tr, "assets/icons/ic_intercity.svg"),
        // DrawerItem('OutStation Rides'.tr, "assets/icons/ic_order.svg"),
        DrawerItem('Freight'.tr, "assets/icons/ic_freight.svg"),
        DrawerItem('My Wallet'.tr, "assets/icons/ic_wallet.svg"),
        DrawerItem('Bank Details'.tr, "assets/icons/ic_profile.svg"),
        DrawerItem('Inbox'.tr, "assets/icons/ic_inbox.svg"),
        DrawerItem('Profile'.tr, "assets/icons/ic_profile.svg"),
        if (Constant.isVerifyDocument == true)
          DrawerItem('Online Registration'.tr, "assets/icons/ic_document.svg"),
        DrawerItem('Vehicle Information'.tr, "assets/icons/ic_city.svg"),
        DrawerItem('Settings'.tr, "assets/icons/ic_settings.svg"),
        //DrawerItem('Subscription History'.tr, "assets/icons/ic_subscription_history.svg"),
        DrawerItem('Log out'.tr, "assets/icons/ic_logout.svg"),
      ];
    }
  }

  getLocation() async {
    await Utils.determinePosition();
  }

  Rx<DateTime> currentBackPressTime = DateTime.now().obs;

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (now.difference(currentBackPressTime.value) >
        const Duration(seconds: 2)) {
      currentBackPressTime.value = now;
      ShowToastDialog.showToast(
        "Double press to exit",
      );
      return Future.value(false);
    }
    return Future.value(true);
  }

  // @override
  // void onClose() {
  //   bannerTimer?.cancel();
  //   super.onClose();
  // }
}

class DrawerItem {
  String title;
  String icon;

  DrawerItem(this.title, this.icon);
}
