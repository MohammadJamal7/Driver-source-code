import 'package:driver/model/document_model.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../model/driver_user_model.dart';

class OnlineRegistrationController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getDocument();
    super.onInit();
  }

  RxList documentList = <DocumentModel>[].obs;
  RxList driverDocumentList = <Documents>[].obs;
  DriverUserModel driverList = DriverUserModel() ;

  getDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ لا يوجد مستخدم مسجل الدخول");
      return;
    }

    isLoading.value = true;

    final driverData = await FireStoreUtils.getDriverProfile(user.uid);
    if (driverData != null) {
      driverList = driverData;

      print("✅ ${driverData.toJson()}");
      await FireStoreUtils.updateDriverUser(driverList);
    }


    final documents = await FireStoreUtils.getDocumentList();
    documentList.value = documents;

    final uploadedDocs = await FireStoreUtils.getDocumentOfDriver();
    if (uploadedDocs != null) {
      driverDocumentList.value = uploadedDocs.documents!;
    }

    isLoading.value = false;
    update();


  await FireStoreUtils.getDocumentOfDriver().then((value) {
      if(value != null){
        driverDocumentList.value = value.documents!;
      }
    });
    update();
  }
}
