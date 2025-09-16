import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_rules_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import '../constant/collection_name.dart';
import '../model/vehicle_type_year.dart';

class VehicleInformationController extends GetxController {
  VehicleInformationController();

  Rx<TextEditingController> vehicleNumberController =
      TextEditingController().obs;
  Rx<TextEditingController> seatsController = TextEditingController().obs;
  Rx<TextEditingController> registrationDateController =
      TextEditingController().obs;
  Rx<TextEditingController> driverRulesController = TextEditingController().obs;
  Rx<TextEditingController> zoneNameController = TextEditingController().obs;
  Rx<TextEditingController> acPerKmRate = TextEditingController().obs;
  Rx<TextEditingController> nonAcPerKmRate = TextEditingController().obs;
  Rx<TextEditingController> acNonAcWithoutPerKmRate =
      TextEditingController().obs;
  Rx<DateTime?> selectedDate = Rx<DateTime?>(null);

  // Rx<DateTime?> selectedDate = DateTime.now().obs;

  RxBool isLoading = true.obs;
  RxBool hasAcFeature = false.obs;
  RxBool isEditable = true.obs;

  // Helper method to check if core vehicle info fields are locked
  bool get isCoreFieldsLocked =>
      driverModel.value.coreVehicleInfoLocked ?? false;

  Rx<String> selectedColor = "".obs;
  Rx<String> selectedCarModel = "".obs;

  List<String> carColorList = <String>[
    'Red'.tr,
    'Black'.tr,
    'White'.tr,
    'Blue'.tr,
    'Green'.tr,
    'Orange'.tr,
    'Silver'.tr,
    'Gray'.tr,
    'Yellow'.tr,
    'Brown'.tr,
    'Gold'.tr,
    'Beige'.tr,
    'Purple'.tr
  ].obs;
  List<String> sheetList = List.generate(15, (index) => '${index + 1}').obs;

  RxBool isDataReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<VehicleInformationController>()) {
      log("🛑 VehicleInformationController مسجل مسبقًا!");
    }
    // final box = GetStorage();
    // bool isLocked = box.read('vehicle_locked') ?? false;
    // isEditable.value = !isLocked;

    // Set up real-time listener for driver profile changes
    _setupDriverProfileListener();

    waitForUserAndLoadData();
  }

  List<VehicleTypeModel> vehicleList = <VehicleTypeModel>[].obs;
  List<VehicleYearModel> vehicleYearList = <VehicleYearModel>[].obs;
  List<String> whereWork = <String>["داخل المدينة", "بين المدن (خط طويل)"].obs;
  Rx<VehicleTypeModel> selectedVehicle = VehicleTypeModel().obs;
  Rx<VehicleYearModel> selectedYear = VehicleYearModel().obs;
  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3
  ];
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;
  RxList<DriverRulesModel> driverRulesList = <DriverRulesModel>[].obs;
  RxList<DriverRulesModel> selectedDriverRulesList = <DriverRulesModel>[].obs;

  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;
  Rx<ServiceModel> selectedServiceType = ServiceModel().obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  RxList selectedZone = <String>[].obs;
  String? selectedWhereWork;
  RxString zoneString = "".obs;

  getVehicleTye() async {
    isLoading.value = true;

    try {
      final services = await FireStoreUtils.getService();
      serviceList.value = services;
      print("object");

      // Refresh service cards state after loading services
      await _refreshServiceCardsState();
    } catch (e) {
      ShowToastDialog.showToast("ERROR!getService->$e");
      print("ERROR!getService->$e");
      isLoading.value = false;
      return;
    }

    try {
      final zones = await FireStoreUtils.getZone();
      if (zones != null) zoneList.value = zones;
    } catch (e) {
      ShowToastDialog.showToast("ERROR!$e");
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        log("🚫 المستخدم غير مسجل دخول في getVehicleTye");
        isLoading.value = false;
        return;
      }
      String driverId = currentUser.uid;
      final driver = await FireStoreUtils.getDriverProfile(driverId);
      if (driver != null) {
        print("driverId Firebase-> $driverId");
        print("getDriverProfile Firebase-> $driver");
        driverModel.value = driver;
        driverModel.value.id = driverId;
        // Defensive: ensure new drivers have coreVehicleInfoLocked == false
        if (driver.coreVehicleInfoLocked == null) {
          await FirebaseFirestore.instance
              .collection(CollectionName.driverUsers)
              .doc(driverId)
              .set({'coreVehicleInfoLocked': false}, SetOptions(merge: true));
          driverModel.value.coreVehicleInfoLocked = false;
        }
        final info = driver.vehicleInformation;
        if (info != null) {
          vehicleNumberController.value.text = info.vehicleNumber ?? "";
          selectedDate.value = info.registrationDate?.toDate();
          registrationDateController.value.text = selectedDate.value != null
              ? DateFormat("dd-MM-yyyy").format(selectedDate.value!)
              : "";
          selectedColor.value = info.vehicleColor ?? "";
          seatsController.value.text = info.seats ?? "2";
          hasAcFeature.value = info.is_AC ?? false;

          if (info.acPerKmRate != null) {
            acPerKmRate.value.text = info.acPerKmRate ?? '';
          } else {
            nonAcPerKmRate.value.text = info.nonAcPerKmRate ?? '';
            acNonAcWithoutPerKmRate.value.text = info.perKmRate ?? '';
          }

          if (driver.zoneIds != null) {
            selectedZone.clear();
            zoneString.value = "";
            final uniqueZoneIds = <String>{};
            for (var element in driver.zoneIds!) {
              if (uniqueZoneIds.add(element)) {
                List<ZoneModel> list =
                    zoneList.where((p0) => p0.id == element).toList();
                if (list.isNotEmpty) {
                  selectedZone.add(element);
                  zoneString.value +=
                      "${zoneString.value.isEmpty ? "" : ","} ${Constant.localizationName(list.first.name)}";
                }
              }
            }
            zoneNameController.value.text = zoneString.value;
          }

          for (var service in serviceList) {
            if (service.id == driver.serviceId) {
              selectedServiceType.value = service;
              break;
            }
          }

          // Ensure service cards are properly enabled each time page loads
          _refreshServiceCardsState();
          selectedWhereWork = driver.workWhere ?? "";
        }
      }
    } catch (e) {
      ShowToastDialog.showToast("ERROR!$e");
    }

    try {
      final vehicles = await FireStoreUtils.getVehicleType();
      vehicleList = vehicles ?? [];

      if (driverModel.value.vehicleInformation != null) {
        final vehicleId = driverModel.value.vehicleInformation!.vehicleTypeId;
        selectedVehicle.value = vehicleList.firstWhere(
          (e) => e.id == vehicleId,
          orElse: () => VehicleTypeModel(),
        );
      }
    } catch (e) {
      ShowToastDialog.showToast("ERROR!$e");
    }

    try {
      final years = await FireStoreUtils.getCarVehicleYear();
      vehicleYearList = years ?? [];

      if (driverModel.value.vehicleInformation != null) {
        final carYear = driverModel.value.vehicleInformation!.vehicle_year;
        selectedYear.value = vehicleYearList.firstWhere(
          (e) => e.year == carYear,
          orElse: () => VehicleYearModel(),
        );
        // Sync selectedCarModel with selectedYear to prevent data loss
        if (carYear != null) {
          selectedCarModel.value = carYear.toString();
        }
      }
    } catch (e) {
      ShowToastDialog.showToast("ERROR!$e");
    }

    try {
      final rules = await FireStoreUtils.getDriverRules();
      if (rules != null) {
        driverRulesList.value = rules;
        if (driverModel.value.vehicleInformation?.driverRules != null) {
          selectedDriverRulesList.value =
              driverModel.value.vehicleInformation!.driverRules!;
        }
      }
    } catch (e) {
      ShowToastDialog.showToast("ERROR!$e");
    }

    // Non-blocking auto-lock for existing users
    if (driverModel.value.vehicleInformation != null &&
        driverModel.value.coreVehicleInfoLocked == null) {
      // Run in background without awaiting
      Future.microtask(() async {
        try {
          await FirebaseFirestore.instance
              .collection(CollectionName.driverUsers)
              .doc(driverModel.value.id)
              .update({'coreVehicleInfoLocked': true});
          // Update UI only if the controller is still active
          if (isLoading.isTrue) {
            driverModel.value.coreVehicleInfoLocked = true;
            driverModel.refresh();
          }
        } catch (e) {
          print("Failed to auto-lock existing user: $e");
        }
      });
    }

    isLoading.value = false;
    isDataReady.value = true;
    update();
  }

  saveDetails() async {
    if (isLoading.value || !isDataReady.value) {
      ShowToastDialog.showToast("الرجاء الانتظار حتى يتم تحميل البيانات...");
      return;
    }

    final driverId =
        driverModel.value.id ?? FirebaseAuth.instance.currentUser?.uid;

    if (driverId == null || driverId.isEmpty) {
      ShowToastDialog.showToast("فشل في الحصول على معرّف السائق");
      return;
    }

    try {
      // بناء كائن معلومات المركبة فقط
      final vehicleInfo = VehicleInformation(
        registrationDate:
            Timestamp.fromDate(selectedDate.value ?? DateTime.now()),
        vehicleColor: selectedColor.value,
        vehicleNumber: vehicleNumberController.value.text,
        vehicleType: selectedVehicle.value.name,
        acPerKmRate: acPerKmRate.value.text,
        nonAcPerKmRate: nonAcPerKmRate.value.text,
        vehicleTypeId: selectedVehicle.value.id ?? "",
        vehicle_year: selectedCarModel.value,
        is_AC: hasAcFeature.value,
        seats: seatsController.value.text,
        perKmRate: acNonAcWithoutPerKmRate.value.text,
        driverRules: selectedDriverRulesList.toList(),
      );

      final json = {
        "vehicleInformation": vehicleInfo.toJson(),
        "workWhere": selectedWhereWork,
        "serviceId": selectedServiceType.value.id,
        "zoneIds": selectedZone,
        "coreVehicleInfoLocked": true, // Lock core fields after first save
      };

      ShowToastDialog.showLoader("جاري حفظ معلومات المركبة...");

      await FirebaseFirestore.instance
          .collection(CollectionName.driverUsers)
          .doc(driverId)
          .set(json, SetOptions(merge: true));

      // Update local model immediately to reflect locked state
      driverModel.value.coreVehicleInfoLocked = true;
      driverModel.refresh(); // Trigger UI update

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("تم حفظ معلومات المركبة بنجاح");
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("حدث خطأ أثناء حفظ معلومات المركبة: $e");
      print("❌ خطأ في saveDetails: $e");
    }
  }

  // saveDetails() async {
  //   try {
  //     if (driverModel.value.serviceId == null) {
  //       driverModel.value.serviceId = selectedServiceType.value.id;
  //     }
  //     driverModel.value.zoneIds = selectedZone;
  //     driverModel.value.workWhere = selectedWhereWork;
  //
  //     driverModel.value.vehicleInformation = VehicleInformation(
  //       registrationDate: Timestamp.fromDate(selectedDate.value ?? DateTime.now()),
  //       vehicleColor: selectedColor.value,
  //       vehicleNumber: vehicleNumberController.value.text,
  //       vehicleType: selectedVehicle.value.name,
  //       acPerKmRate: "",
  //       nonAcPerKmRate: "",
  //       vehicleTypeId: selectedVehicle.value.id.toString() ?? "",
  //       vehicle_year: selectedCarModel.value.toString(),
  //       is_AC: hasAcFeature.value,
  //       seats: seatsController.value.text,
  //       perKmRate: acNonAcWithoutPerKmRate.value.text,
  //       driverRules: selectedDriverRulesList.toList(),
  //     );
  //
  //     ShowToastDialog.showLoader("Saving...".tr);
  //     await FireStoreUtils.updateDriverUser(driverModel.value).then((value) {
  //       ShowToastDialog.closeLoader();
  //       if (value == true) {
  //         ShowToastDialog.showToast("Information update successfully".tr);
  //       }
  //     });
  //   } catch (e) {
  //     ShowToastDialog.closeLoader();
  //     ShowToastDialog.showToast("ERROR IN SAVE DETAILS-> $e");
  //   }
  // }

  /// Ensures service cards are properly enabled and refreshed each time the page loads
  Future<void> _refreshServiceCardsState() async {
    try {
      print("🔄 Fetching fresh services from Firestore...");

      // Actually fetch fresh data from Firestore
      final freshServices = await FireStoreUtils.getService();
      serviceList.value = freshServices;

      // Ensure selected service is properly set if it exists
      if (selectedServiceType.value.id != null &&
          selectedServiceType.value.id!.isNotEmpty) {
        // Find and re-select the current service to ensure proper state
        final currentService = serviceList.firstWhere(
          (service) => service.id == selectedServiceType.value.id,
          orElse: () => ServiceModel(),
        );
        if (currentService.id != null) {
          selectedServiceType.value = currentService;
        }
      }

      // Trigger UI update to refresh card states
      update();

      print(
          "✅ Service cards refreshed with fresh data: ${serviceList.length} services");
    } catch (e) {
      print("❌ Error refreshing service cards from Firestore: $e");
    }
  }

  /// Public method to manually refresh service cards state
  /// Can be called from UI when page becomes visible or needs refresh
  Future<void> refreshServiceCards() async {
    await _refreshServiceCardsState();
  }

  void _setupDriverProfileListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      log("🚫 المستخدم غير مسجل دخول في _setupDriverProfileListener");
      return;
    }
    String driverId = currentUser.uid;

    FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(driverId)
        .snapshots()
        .listen((event) {
      if (event.exists && event.data() != null) {
        DriverUserModel newDriverModel =
            DriverUserModel.fromJson(event.data()!);
        newDriverModel.id = driverId;

        // Check if any data changed
        bool dataChanged =
            _hasDriverDataChanged(driverModel.value, newDriverModel);

        if (dataChanged) {
          print("🔄 Driver profile data changed, updating UI");

          // Update driver model
          driverModel.value = newDriverModel;

          // Update all UI fields with new data
          _updateUIWithDriverData(newDriverModel);

          // Refresh service cards state
          _refreshServiceCardsState();
        }
      }
    });
  }

  bool _hasDriverDataChanged(
      DriverUserModel oldModel, DriverUserModel newModel) {
    // Check service type change
    if (oldModel.serviceId != newModel.serviceId) return true;

    // Check vehicle information changes
    final oldVehicle = oldModel.vehicleInformation;
    final newVehicle = newModel.vehicleInformation;

    if (oldVehicle?.vehicleNumber != newVehicle?.vehicleNumber) return true;
    if (oldVehicle?.vehicleColor != newVehicle?.vehicleColor) return true;
    if (oldVehicle?.seats != newVehicle?.seats) return true;
    if (oldVehicle?.is_AC != newVehicle?.is_AC) return true;
    if (oldVehicle?.acPerKmRate != newVehicle?.acPerKmRate) return true;
    if (oldVehicle?.nonAcPerKmRate != newVehicle?.nonAcPerKmRate) return true;
    if (oldVehicle?.perKmRate != newVehicle?.perKmRate) return true;
    if (oldVehicle?.vehicleTypeId != newVehicle?.vehicleTypeId) return true;
    if (oldVehicle?.vehicle_year != newVehicle?.vehicle_year) return true;

    // Check zone changes
    if (oldModel.zoneIds?.length != newModel.zoneIds?.length) return true;
    if (oldModel.zoneIds != null && newModel.zoneIds != null) {
      for (int i = 0; i < oldModel.zoneIds!.length; i++) {
        if (oldModel.zoneIds![i] != newModel.zoneIds![i]) return true;
      }
    }

    // Check work location change
    if (oldModel.workWhere != newModel.workWhere) return true;

    return false;
  }

  void _updateUIWithDriverData(DriverUserModel newDriverModel) {
    final info = newDriverModel.vehicleInformation;

    if (info != null) {
      // Update vehicle information fields
      vehicleNumberController.value.text = info.vehicleNumber ?? "";
      selectedDate.value = info.registrationDate?.toDate();
      registrationDateController.value.text = selectedDate.value != null
          ? DateFormat("dd-MM-yyyy").format(selectedDate.value!)
          : "";
      selectedColor.value = info.vehicleColor ?? "";
      seatsController.value.text = info.seats ?? "2";
      hasAcFeature.value = info.is_AC ?? false;

      if (info.acPerKmRate != null) {
        acPerKmRate.value.text = info.acPerKmRate ?? '';
      } else {
        nonAcPerKmRate.value.text = info.nonAcPerKmRate ?? '';
        acNonAcWithoutPerKmRate.value.text = info.perKmRate ?? '';
      }

      // Update vehicle type selection
      if (info.vehicleTypeId != null) {
        selectedVehicle.value = vehicleList.firstWhere(
          (e) => e.id == info.vehicleTypeId,
          orElse: () => VehicleTypeModel(),
        );
      }

      // Update vehicle year selection
      if (info.vehicle_year != null) {
        selectedYear.value = vehicleYearList.firstWhere(
          (e) => e.year == info.vehicle_year,
          orElse: () => VehicleYearModel(),
        );
        // Sync selectedCarModel with selectedYear to prevent data loss
        selectedCarModel.value = info.vehicle_year.toString();
      }
    }

    // Update zone selection
    if (newDriverModel.zoneIds != null) {
      selectedZone.clear();
      zoneString.value = "";
      final uniqueZoneIds = <String>{};
      for (var element in newDriverModel.zoneIds!) {
        if (uniqueZoneIds.add(element)) {
          List<ZoneModel> list =
              zoneList.where((p0) => p0.id == element).toList();
          if (list.isNotEmpty) {
            selectedZone.add(element);
            zoneString.value +=
                "${zoneString.value.isEmpty ? "" : ","} ${Constant.localizationName(list.first.name)}";
          }
        }
      }
      zoneNameController.value.text = zoneString.value;
    }

    // Update service type selection
    for (var service in serviceList) {
      if (service.id == newDriverModel.serviceId) {
        selectedServiceType.value = service;
        print(
            "✅ Updated selected service to: ${Constant.localizationTitle(service.title)}");
        break;
      }
    }

    // Update work location
    selectedWhereWork = newDriverModel.workWhere ?? "";

    print("✅ All UI fields updated with latest driver data");
  }

  void waitForUserAndLoadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        log("🚫 المستخدم غير مسجل دخول");
        //ShowToastDialog.showToast("يرجى تسجيل الدخول أولاً");
        isLoading.value = false;
        return;
      }

      final driverId = user.uid;
      log("🚀 بدء تحميل بيانات السائق ID: $driverId");

      isLoading.value = true;
      await getVehicleTye();
    } catch (e) {
      log("🔥 خطأ في تحميل بيانات المستخدم: $e");
      //ShowToastDialog.showToast("فشل تحميل البيانات");
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    vehicleNumberController.value.dispose();
    seatsController.value.dispose();
    registrationDateController.value.dispose();
    driverRulesController.value.dispose();
    zoneNameController.value.dispose();
    acPerKmRate.value.dispose();
    nonAcPerKmRate.value.dispose();
    acNonAcWithoutPerKmRate.value.dispose();
    super.onClose();
  }
}
