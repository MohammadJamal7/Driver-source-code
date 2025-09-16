import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/ui/intercity_screen/accepted_intercity_orders.dart';
import 'package:driver/ui/intercity_screen/active_intercity_order_screen.dart';
import 'package:driver/ui/intercity_screen/new_order_intercity_screen.dart';
import 'package:driver/ui/order_intercity_screen/order_intercity_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeIntercityController extends GetxController {
  RxInt selectedIndex = 0.obs;
  List<Widget> widgetOptions = <Widget>[
    const NewOrderInterCityScreen(),
    const AcceptedIntercityOrders(),
    const ActiveIntercityOrderScreen(),
    const OrderIntercityScreen(),
  ];

  void onItemTapped(int index) {
    selectedIndex.value = index;
  }

  @override
  void onInit() {
    // TODO: implement onInit
    getDriver();
    getActiveRide();
    super.onInit();
  }

  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  Rx<ServiceModel> selectedService = ServiceModel().obs;
  RxBool isLoading = true.obs;

  getDriver() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("🚫 المستخدم غير مسجل دخول في HomeIntercityController.getDriver");
      isLoading.value = false;
      return;
    }
    
    // Set up real-time listener for driver profile changes
    FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(currentUser.uid)
        .snapshots()
        .listen((event) {
      if (event.exists) {
        DriverUserModel newDriverModel =
            DriverUserModel.fromJson(event.data()!);

        // Check if service type changed
        bool serviceChanged =
            driverModel.value.serviceId != newDriverModel.serviceId;

        driverModel.value = newDriverModel;
        isLoading.value = false;

        // Update selected service when service type changes
        if (serviceChanged && newDriverModel.serviceId != null) {
          _updateSelectedService(newDriverModel.serviceId!);
        }
      }
    });

    // Initial service setup
    if (driverModel.value.serviceId != null) {
      _updateSelectedService(driverModel.value.serviceId!);
    }
  }

  _updateSelectedService(String serviceId) async {
    await FireStoreUtils.getService().then((value) {
      for (var element in value) {
        if (element.id == serviceId) {
          selectedService.value = element;
        }
      }
    });
  }

  RxInt isActiveValue = 0.obs;

  getActiveRide() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("🚫 المستخدم غير مسجل دخول في HomeIntercityController.getActiveRide");
      return;
    }
    
    // First get the driver profile to access serviceId
    FireStoreUtils.getDriverProfile(currentUser.uid)
        .then((driver) {
      if (driver != null) {
        FirebaseFirestore.instance
            .collection(CollectionName.ordersIntercity)
            .where('driverId', isEqualTo: currentUser.uid)
            .where('status', whereIn: [
              Constant.rideInProgress,
              Constant.rideActive,
              Constant.rideHoldAccepted
            ])
            .snapshots()
            .listen((event) {
              isActiveValue.value = event.size;
            });
      }
    });
  }
}
