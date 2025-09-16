import 'dart:developer';
import 'dart:typed_data';

import 'package:driver/constant/constant.dart';
import 'package:driver/controller/home_controller.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ActiveOrderController extends GetxController {
  HomeController homeController = Get.put(HomeController());
  TextEditingController? otpController; // Make nullable

  // Map marker icons
  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropoffIcon;
  BitmapDescriptor? driverIcon;
  BitmapDescriptor? destinationIcon; // Added destination icon

  // Loading state
  bool isLoadingIcons = true;

  @override
  void onInit() {
    super.onInit();
    otpController = TextEditingController(); // Initialize here
    loadMapIcons();
  }

  // Load map marker icons with improved error handling
  Future<void> loadMapIcons() async {
    try {
      isLoadingIcons = true;
      update();

      // Load icons with proper error handling
      final Uint8List pickupIconData =
          await Constant().getBytesFromAsset('assets/images/pickup.png', 100);
      final Uint8List dropoffIconData =
          await Constant().getBytesFromAsset('assets/images/dropoff.png', 100);
      final Uint8List driverIconData =
          await Constant().getBytesFromAsset('assets/images/ic_cab.png', 50);

      pickupIcon = BitmapDescriptor.fromBytes(pickupIconData);
      dropoffIcon = BitmapDescriptor.fromBytes(dropoffIconData);
      driverIcon = BitmapDescriptor.fromBytes(driverIconData);
      destinationIcon = BitmapDescriptor.fromBytes(
          dropoffIconData); // Use dropoff icon for destination

      isLoadingIcons = false;
      update();

      log('✅ Map icons loaded successfully');
    } catch (e) {
      log('❌ Error loading map icons: $e');
      isLoadingIcons = false;
      update();

      // Set default icons if loading fails
      pickupIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      dropoffIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      driverIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      destinationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      update();
    }
  }

  // Check if all icons are loaded
  bool get areIconsLoaded =>
      pickupIcon != null &&
      dropoffIcon != null &&
      driverIcon != null &&
      destinationIcon != null;

  // Create small circle icon for pickup location
  BitmapDescriptor get smallPickupIcon =>
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  // Refresh map icons
  Future<void> refreshMapIcons() async {
    await loadMapIcons();
  }

  // Clear OTP controller safely
  void clearOtpController() {
    try {
      if (otpController != null) {
        otpController!.clear();
      }
    } catch (e) {
      log('❌ Error clearing OTP controller: $e');
    }
  }

  // Clear OTP controller
  @override
  void onClose() {
    try {
      if (otpController != null) {
        otpController!.dispose();
      }
    } catch (e) {
      log('❌ Error disposing OTP controller: $e');
    }
    super.onClose();
  }
}
