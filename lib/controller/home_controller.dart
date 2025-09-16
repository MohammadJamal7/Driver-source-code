import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/dash_board_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order/location_lat_lng.dart';
import 'package:driver/model/order/positions.dart';
import 'package:driver/ui/home_screens/accepted_orders.dart';
import 'package:driver/ui/home_screens/active_order_screen.dart';
import 'package:driver/ui/home_screens/new_orders_screen.dart';
import 'package:driver/ui/order_screen/order_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:driver/widget/geoflutterfire/src/models/point.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';

import '../model/banner_model.dart';
import '../utils/notification_service.dart';

class HomeController extends GetxController {
  RxInt selectedIndex = 0.obs;
  List<Widget> widgetOptions = <Widget>[
    const NewOrderScreen(),
    const AcceptedOrders(),
    const ActiveOrderScreen(),
    const OrderScreen(),
  ];
  DashBoardController dashboardController = Get.put(DashBoardController());

  RxList bannerList = <BannerModel>[].obs;
  RxList bannerListLow = <OtherBannerModel>[].obs;
  final PageController pageController =
      PageController(viewportFraction: 0.96, keepPage: true);
  final PageController pageControllerLow =
      PageController(viewportFraction: 0.96, keepPage: true);

  void onItemTapped(int index) {
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    // TODO: implement onInit
    getDriver();
    getActiveRide();
    getServiceType();
    super.onInit();
  }

  @override
  void onClose() {
    bannerTimer?.cancel();
    bannerTimerLow?.cancel();
    super.onInit();
  }

  getServiceType() async {
    await FireStoreUtils.getBanner().then((value) {
      bannerList.value = value;
    });
    await FireStoreUtils.getBannerOrder().then((value) {
      bannerListLow.value = value;
    });
    startAutoScroll();
    startAutoScrollLow();
  }

  Timer? bannerTimer;
  Timer? bannerTimerLow;

  void startAutoScroll() {
    bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (pageController.hasClients && bannerList.isNotEmpty) {
        int nextPage = pageController.page!.round() + 1;

        if (nextPage >= bannerList.length) {
          nextPage = 0;
        }

        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void startAutoScrollLow() {
    bannerTimerLow = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (pageControllerLow.hasClients && bannerListLow.isNotEmpty) {
        int nextPage = pageControllerLow.page!.round() + 1;

        if (nextPage >= bannerListLow.length) {
          nextPage = 0;
        }

        pageControllerLow.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  RxBool isLoading = false.obs;

  getDriver() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("🚫 المستخدم غير مسجل دخول في HomeController.getDriver");
      return;
    }

    FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(currentUser.uid)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        driverModel.value = DriverUserModel.fromJson(event.data()!);
      }
    });
    updateCurrentLocation();
  }

  RxInt isActiveValue = 0.obs;

  getActiveRide() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("🚫 المستخدم غير مسجل دخول في HomeController.getActiveRide");
      return;
    }

    FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('driverId', isEqualTo: currentUser.uid)
        .where('status',
            whereIn: [Constant.rideInProgress, Constant.rideActive])
        .snapshots()
        .listen((event) {
          isActiveValue.value = event.size;
        });
  }

  Location location = Location();

  Future<void> updateCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // 1. التحقق من تفعيل خدمة الموقع
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        // المستخدم لم يقم بتفعيل خدمة الموقع، يجب التعامل مع هذا.
        print('Location services are disabled by the user.');
        // يمكنك عرض رسالة للمستخدم هنا أو إعادة توجيهه
        return;
      }
    }

    // 2. التحقق وطلب أذونات الموقع
    permissionGranted = await location.hasPermission();

    // إذا لم يتم منح الإذن، اطلب الأذونات
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // المستخدم رفض إذن الموقع، يجب التعامل مع هذا.
        print('Location permission denied by the user.');
        // يمكنك عرض رسالة للمستخدم هنا أو إعادة توجيهه
        return;
      }
    }

    // 3. التعامل مع إذن تحديد الموقع في الخلفية (ACCESS_BACKGROUND_LOCATION)
    // هذا هو الجزء الحاسم لـ Android 11+
    // إذا تم منح إذن "أثناء الاستخدام" فقط، يجب توجيه المستخدم لتمكين "طوال الوقت"
    if (permissionGranted == PermissionStatus.granted) {
      // حاول تمكين وضع الخلفية.
      // على Android 11+، قد تفشل هذه الخطوة إذا لم يتم منح إذن "Always" يدوياً.
      bool backgroundModeEnabled = false;
      try {
        backgroundModeEnabled =
            await location.enableBackgroundMode(enable: true);
      } catch (e) {
        print('Error trying to enable background mode: $e');
        // قد تحدث هذه الأخطاء إذا لم يكن الإذن "Always" متاحاً أو تم رفضه.
      }

      if (!backgroundModeEnabled) {
        print('Background location mode was not enabled automatically.');
        // هنا يجب أن تظهر للمستخدم رسالة تشرح لماذا يحتاج تطبيقك إلى الموقع في الخلفية
        // وكيف يمكنه تمكينه يدويًا من إعدادات الجهاز.
        // مثال لرسالة توجيهية (يمكنك استخدامها في AlertDialog):
        // "لتزويدك بتحديثات الموقع المستمرة حتى عندما يكون التطبيق في الخلفية،
        // يرجى الانتقال إلى إعدادات التطبيق وتغيير إذن الموقع إلى "السماح طوال الوقت" (Allow all the time)."
        // يمكنك فتح إعدادات التطبيق مباشرة إذا كنت تستخدم حزمة مثل 'app_settings' أو 'permission_handler'
        // مثال باستخدام permission_handler (يجب عليك إضافتها إلى pubspec.yaml):
        // import 'package:permission_handler/permission_handler.dart';
        // await openAppSettings(); // سيفتح إعدادات التطبيق مباشرة
      }

      // بغض النظر عما إذا كانت الخلفية مفعلة تلقائيًا أم لا،
      // نتابع إعداد مستمع الموقع، لأنه قد يعمل على الأقل "أثناء الاستخدام".
      _setupLocationListener();
    }

    //isLoading.value = false; // إذا كان هذا جزءًا من GetX controller، استخدمه
    //update(); // إذا كان هذا جزءًا من GetX controller، استخدمه
  }

// دالة منفصلة لإعداد مستمع الموقع لتجنب تكرار الكود
  void _setupLocationListener() {
    location.changeSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: double.parse(Constant.driverLocationUpdate.toString()),
      interval: 2000,
    );

    location.onLocationChanged.listen((locationData) {
      // تأكد من أن الـ locationData.latitude و locationData.longitude ليست null
      log("Start Listen");
      if (locationData.latitude != null && locationData.longitude != null) {
        log("IF Listen");
        Constant.currentLocation = LocationLatLng(
            latitude: locationData.latitude!,
            longitude: locationData.longitude!);

        FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid())
            .then((value) async {
          DriverUserModel driverUserModel = value!;
          if (driverUserModel.isOnline == true) {
            driverUserModel.location = LocationLatLng(
                latitude: locationData.latitude!,
                longitude: locationData.longitude!);
            GeoFirePoint position = Geoflutterfire().point(
                latitude: locationData.latitude!,
                longitude: locationData.longitude!);
            log("IF IF Listen");
            driverUserModel.position =
                Positions(geoPoint: position.geoPoint, geohash: position.hash);
            driverUserModel.rotation =
                locationData.heading; // Heading قد يكون null، تعامل معه.
            String token = await NotificationService.getToken();
            driverUserModel.fcmToken = token;
            FireStoreUtils.updateDriverUser(driverUserModel);
          }
        }).catchError((error) {
          log("Error getting or updating driver profile: $error");
        });
      } else {
        log("Location data is null.");
      }
    });
  }

// updateCurrentLocation() async {
//   PermissionStatus permissionStatus = await location.hasPermission();
//   if (permissionStatus == PermissionStatus.granted) {
//     await location.enableBackgroundMode(enable: true);
//     location.changeSettings(accuracy: LocationAccuracy.high, distanceFilter: double.parse(Constant.driverLocationUpdate.toString()),interval: 2000);
//     location.onLocationChanged.listen((locationData) {
//       Constant.currentLocation = LocationLatLng(latitude: locationData.latitude, longitude: locationData.longitude);
//       FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid()).then((value) {
//         DriverUserModel driverUserModel = value!;
//         if (driverUserModel.isOnline == true) {
//           driverUserModel.location = LocationLatLng(latitude: locationData.latitude, longitude: locationData.longitude);
//           GeoFirePoint position = Geoflutterfire().point(latitude: locationData.latitude!, longitude: locationData.longitude!);
//
//           driverUserModel.position = Positions(geoPoint: position.geoPoint, geohash: position.hash);
//           driverUserModel.rotation = locationData.heading;
//           FireStoreUtils.updateDriverUser(driverUserModel);
//         }
//       });
//     });
//   } else {
//     location.requestPermission().then((permissionStatus) {
//       if (permissionStatus == PermissionStatus.granted) {
//         location.enableBackgroundMode(enable: true);
//         location.changeSettings(accuracy: LocationAccuracy.high, distanceFilter: double.parse(Constant.driverLocationUpdate.toString()),interval: 2000);
//         location.onLocationChanged.listen((locationData) async {
//           Constant.currentLocation = LocationLatLng(latitude: locationData.latitude, longitude: locationData.longitude);
//
//           FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid()).then((value) {
//             DriverUserModel driverUserModel = value!;
//             if (driverUserModel.isOnline == true) {
//               driverUserModel.location = LocationLatLng(latitude: locationData.latitude, longitude: locationData.longitude);
//               driverUserModel.rotation = locationData.heading;
//               GeoFirePoint position = Geoflutterfire().point(latitude: locationData.latitude!, longitude: locationData.longitude!);
//
//               driverUserModel.position = Positions(geoPoint: position.geoPoint, geohash: position.hash);
//
//               FireStoreUtils.updateDriverUser(driverUserModel);
//             }
//           });
//         });
//       }
//     });
//   }
//   //isLoading.value = false;
//   update();
// }
}
