import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/home_intercity_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:driver/utils/utils.dart';

class IntercityController extends GetxController {
  HomeIntercityController homeController = Get.put(HomeIntercityController());

  Rx<TextEditingController> sourceCityController = TextEditingController().obs;
  Rx<TextEditingController> destinationCityController =
      TextEditingController().obs;
  Rx<TextEditingController> whenController = TextEditingController().obs;
  Rx<TextEditingController> suggestedTimeController =
      TextEditingController().obs;
  DateTime? suggestedTime = DateTime.now();
  DateTime? dateAndTime = DateTime.now();
  StreamSubscription<QuerySnapshot>? _ordersSub;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    // Auto-load orders so the screen shows results without tapping Search
    // When no filters are selected, getOrder() will fetch nearby intercity orders
    getOrder();
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    sourceCityController.value.dispose();
    destinationCityController.value.dispose();
    whenController.value.dispose();
    suggestedTimeController.value.dispose();
    enterOfferRateController.value.dispose();
    super.onClose();
  }

  RxList<InterCityOrderModel> intercityServiceOrder =
      <InterCityOrderModel>[].obs;
  RxBool isLoading = false.obs;
  RxString newAmount = "0.0".obs;
  Rx<InterCityOrderModel?> selectedIntercityServiceOrder =
      InterCityOrderModel().obs;
  Rx<TextEditingController> enterOfferRateController =
      TextEditingController().obs;

  Rx<DriverUserModel> driverModel = DriverUserModel().obs;

  // Map to store original creation dates for reappearing rides
  final Map<String, Timestamp> originalCreationDates = {};

  getSelectedOrder(String orderId) async {
    selectedIntercityServiceOrder.value =
        await FireStoreUtils.getInterCityOrder(orderId);
  }

  acceptOrder(InterCityOrderModel orderModel,
      DriverIdAcceptReject driverIdAcceptReject) async {
    ShowToastDialog.showLoader("Processing bid".tr);

    try {
      // Use existing order data for acceptedDriverId to avoid redundant fetch
      List<dynamic> acceptedDriverId = orderModel.acceptedDriverId ?? [];

      // Avoid duplicate entries for the same driver
      final currentUid = FireStoreUtils.getCurrentUid();
      if (!acceptedDriverId.contains(currentUid)) {
        acceptedDriverId.add(currentUid);
      }

      // Get driverIdAcceptReject list from Firestore in parallel with other operations
      List<dynamic> driverIdAcceptRejectList = [];

      // CRITICAL FIX: Use the original creation date for reappearing rides
      if (originalCreationDates.containsKey(orderModel.id)) {
        print(
            "Using original creation date for offer on ride ${orderModel.id}");
        driverIdAcceptReject.acceptedRejectTime =
            originalCreationDates[orderModel.id]!;
        print(
            "Set acceptedRejectTime to original creation date: ${originalCreationDates[orderModel.id]}");
      } else {
        // For truly new offers, use current timestamp
        driverIdAcceptReject.acceptedRejectTime = Timestamp.now();
        print("Set acceptedRejectTime to current time for new offer");
      }

      // Create subcollection offer object
      DriverIdAcceptReject subcollectionOffer = DriverIdAcceptReject(
        driverId: driverIdAcceptReject.driverId,
        offerAmount: driverIdAcceptReject.offerAmount,
        suggestedTime: driverIdAcceptReject.suggestedTime,
        suggestedDate: driverIdAcceptReject.suggestedDate,
        acceptedRejectTime: driverIdAcceptReject.acceptedRejectTime,
      );

      // Execute critical operations in parallel for better performance
      final results = await Future.wait([
        // Get current driverIdAcceptReject list
        FireStoreUtils.fireStore
            .collection(CollectionName.ordersIntercity)
            .doc(orderModel.id)
            .get()
            .then((doc) =>
                doc.exists ? (doc.data()?['driverIdAcceptReject'] ?? []) : []),
        // Store offer in subcollection
        FireStoreUtils.acceptInterCityRide(orderModel, subcollectionOffer),
        // Get customer data for notification
        FireStoreUtils.getCustomer(orderModel.userId.toString()),
      ]);

      // Update driverIdAcceptRejectList with fetched data
      driverIdAcceptRejectList = results[0] as List<dynamic>;
      driverIdAcceptRejectList.add(driverIdAcceptReject.toJson());

      // Update main order document with all data
      await FireStoreUtils.fireStore
          .collection(CollectionName.ordersIntercity)
          .doc(orderModel.id)
          .update({
        "acceptedDriverId": acceptedDriverId,
        "driverIdAcceptReject": driverIdAcceptRejectList,
        "updateDate": Timestamp.now(),
      });

      print(
          "Successfully stored offer in subcollection with timestamp: ${subcollectionOffer.acceptedRejectTime}");

      // Show success immediately after parallel operations complete
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Offer sent successfully".tr);
      Get.back();

      // Send notification in background (non-blocking)
      final customer = results[2] as UserModel?;
      if (customer != null) {
        unawaited(SendNotification.sendOneNotification(
          token: customer.fcmToken.toString(),
          title: "Driver App ${"Driver".tr}",
          body:
              "${'Your request has been accepted by'.tr} ${driverModel.value.fullName}",
          payload: {"orderId": orderModel.id, "type": "intercity_order"},
        ));
      }
    } catch (error) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(error.toString());
      print("acceptOrder error: $error");
    }
  }

  getOrder() async {
    isLoading.value = true;
    intercityServiceOrder.clear();
    _ordersSub?.cancel();

    // Debug: Print driver's zone IDs
    print("Driver zone IDs: ${driverModel.value.zoneIds}");

    // Set up real-time listener for driver profile changes
    FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen((event) {
      if (event.exists) {
        DriverUserModel newDriverModel =
            DriverUserModel.fromJson(event.data()!);

        // Check if service type changed
        bool serviceChanged =
            driverModel.value.serviceId != newDriverModel.serviceId;

        driverModel.value = newDriverModel;

        // Rebuild query if service type changed
        if (serviceChanged) {
          print(
              "🔄 Service type changed to ${newDriverModel.serviceId} - rebuilding intercity orders query");
          _buildAndExecuteQuery();
        }
      }
    });

    // Initial query build
    _buildAndExecuteQuery();
  }

  void _buildAndExecuteQuery() {
    // Cancel existing subscription
    _ordersSub?.cancel();
    intercityServiceOrder.clear();

    // Build the query based on current filters and driver's serviceId
    Query query = FireStoreUtils.fireStore
        .collection(CollectionName.ordersIntercity)
        .where('status', isEqualTo: Constant.ridePlaced)
        .where('intercityServiceId', isEqualTo: driverModel.value.serviceId);
    
   

    // Add source/destination filters if specified
    if (sourceCityController.value.text.isNotEmpty) {
      query =
          query.where('sourceCity', isEqualTo: sourceCityController.value.text);
    }

    if (destinationCityController.value.text.isNotEmpty) {
      query = query.where('destinationCity',
          isEqualTo: destinationCityController.value.text);
    }

    if (whenController.value.text.isNotEmpty) {
      query = query.where('whenDates',
          isEqualTo: DateFormat("dd-MMM-yyyy").format(dateAndTime!));
    }

    // Execute the query
    _ordersSub = query.snapshots().listen((snapshot) {
      isLoading.value = false;
      intercityServiceOrder.clear();


      // Process results
      for (var element in snapshot.docs) {
        InterCityOrderModel documentModel = InterCityOrderModel.fromJson(
            element.data() as Map<String, dynamic>);

        // Debug info
     

        // Check if this order should be shown to the driver
        bool showOrder = true;

        // Only filter by distance if no source/destination filters
        if (sourceCityController.value.text.isEmpty &&
            destinationCityController.value.text.isEmpty) {
          final src = documentModel.sourceLocationLAtLng;
          if (src?.latitude != null && src?.longitude != null) {
            double? driverLat = driverModel.value.location?.latitude;
            double? driverLng = driverModel.value.location?.longitude;

            if (driverLat != null && driverLng != null) {
              final meters = Geolocator.distanceBetween(
                  driverLat, driverLng, src!.latitude!, src.longitude!);
            

              // Only show orders within 2km if no filters applied
              if (meters > 2000) {
                showOrder = false;
              }
            }
          }
        }

        // CRITICAL CHANGE: Always show orders regardless of acceptedDriverId
        // This ensures orders with expired offers will reappear
        if (showOrder) {
          

          // Store the original creation date if we haven't seen this order before
          if (!originalCreationDates.containsKey(documentModel.id)) {
            if (documentModel.createdDate != null) {
              originalCreationDates[documentModel.id!] =
                  documentModel.createdDate!;
              
            } else {
              // Guard against null createdDate; use current time as fallback
              
              originalCreationDates[documentModel.id!] = Timestamp.now();
            }
          } else {
            
          }

          intercityServiceOrder.add(documentModel);
        } else {
        }
      }
      
      
    });
  }
}
