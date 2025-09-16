import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<DriverUserModel> driverModel = DriverUserModel().obs;

  Rx<TextEditingController> fullNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumberController = TextEditingController().obs;
  RxString countryCode = "+1".obs;

  RxBool isEditable = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    if (Constant.isGuestUser) {
      // Pre-populate guest details
      fullNameController.value.text = 'السائق الضيف';
      emailController.value.text = 'guest@wdni.com';
      phoneNumberController.value.text = '-';
      countryCode.value = '+966';
      profileImage.value = '';
      isEditable.value = false;
      isLoading.value = false;
    } else {
      getData();
    }
    super.onInit();
    final box = GetStorage();
    bool isLocked = box.read('vehicle_locked') ?? false;
    if (!Constant.isGuestUser) {
      isEditable.value = !isLocked;
    }
  }

  @override
  void onClose() {
    fullNameController.value.dispose();
    emailController.value.dispose();
    phoneNumberController.value.dispose();
    super.onClose();
  }

  getData() async {
    await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      if (value != null) {
        driverModel.value = value;

        phoneNumberController.value.text =
            driverModel.value.phoneNumber.toString();
        countryCode.value = driverModel.value.countryCode.toString();
        emailController.value.text = driverModel.value.email.toString();
        fullNameController.value.text = driverModel.value.fullName.toString();
        profileImage.value = driverModel.value.profilePic ?? '';
        isLoading.value = false;
      }
    });
  }

  final ImagePicker _imagePicker = ImagePicker();
  RxString profileImage = "".obs;

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      Get.back();
      profileImage.value = image.path;
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to Pick : \n $e");
    }
  }
}
