import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/admin_commission.dart';
import 'package:driver/model/bank_details_model.dart';
import 'package:driver/model/conversation_model.dart';
import 'package:driver/model/currency_model.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/driver_rules_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/inbox_model.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/intercity_service_model.dart';
import 'package:driver/model/language_model.dart';
import 'package:driver/model/language_privacy_policy.dart';
import 'package:driver/model/language_terms_condition.dart';
import 'package:driver/model/on_boarding_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/payment_model.dart';
import 'package:driver/model/referral_model.dart';
import 'package:driver/model/review_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/subscription_history.dart';
import 'package:driver/model/subscription_plan_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/model/withdraw_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:driver/widget/geoflutterfire/src/models/point.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../model/banner_model.dart';
import '../model/cancellation_reason_model.dart';
import '../model/vehicle_type_year.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  // API key tagging for Firestore writes (to satisfy security rules)
  static const String _apiKey =
      "mysecretapikeyisthisonethatshouldbetooscrectandhardtobedetected";
  static Map<String, dynamic> _addApiKey(Map<String, dynamic> data) {
    return {...data, '_apiKey': _apiKey};
  }

  static Future<File> optimizeImage(File originalImage) async {
    try {
      dev.log("🚀 Starting professional image optimization...");
      final String originalPath = originalImage.path;
      final String extension = path.extension(originalPath);
      final String optimizedPath =
          originalPath.replaceAll(extension, '_optimized$extension');

      // Parallel processing: Get file size while setting up compression
      final Future<int> originalSizeFuture = originalImage.length();

      // Pre-calculate compression settings for speed
      final int originalSize = await originalSizeFuture;
      dev.log(
          "📊 Original image size: ${(originalSize / 1024).toStringAsFixed(2)}KB");

      // Professional aggressive compression strategy (faster processing)
      int quality;
      int targetDimension; // Use single dimension for faster processing

      if (originalSize > 3 * 1024 * 1024) {
        // > 3MB - Ultra aggressive for very large files
        quality = 25; // Much more aggressive
        targetDimension = 500;
      } else if (originalSize > 2 * 1024 * 1024) {
        // > 2MB - Very aggressive
        quality = 35; // More aggressive than before
        targetDimension = 600;
      } else if (originalSize > 1024 * 1024) {
        // > 1MB - Aggressive
        quality = 45; // More aggressive
        targetDimension = 700;
      } else if (originalSize > 500 * 1024) {
        // > 500KB - Medium aggressive
        quality = 55; // More aggressive
        targetDimension = 800;
      } else {
        quality = 65; // Still good quality for small files
        targetDimension = 900;
      }

      dev.log(
          "🎯 Using quality: $quality%, target dimension: ${targetDimension}px");

      // Professional compression with optimized settings
      final compressedResult = await FlutterImageCompress.compressAndGetFile(
        originalImage.path,
        optimizedPath,
        quality: quality,
        minWidth: targetDimension,
        minHeight: targetDimension,
        rotate: 0,
        // Keep original format as requested
        format: extension.toLowerCase() == '.png'
            ? CompressFormat.png
            : CompressFormat.jpeg,
        // Professional optimization flags
        autoCorrectionAngle: false, // Skip auto-rotation for speed
        keepExif: false, // Remove metadata for smaller size
      );

      if (compressedResult == null) {
        dev.log("⚠️ Compression failed, using original image");
        return originalImage;
      }

      final compressedFile = File(compressedResult.path);
      final int compressedSize = await compressedFile.length();

      dev.log(
          "✅ Optimized size: ${(compressedSize / 1024).toStringAsFixed(2)}KB");
      dev.log(
          "📈 Size reduction: ${((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)}%");
      dev.log(
          "⚡ Speed gain: ~${((originalSize / compressedSize) * 100).toStringAsFixed(0)}% faster upload");

      return compressedFile;
    } catch (e) {
      dev.log("❌ Error during image optimization: $e");
      return originalImage;
    }
  }

  static Future<String> uploadUserImageToStorage(
      File image, String folderPath) async {
    try {
      ShowToastDialog.showLoader("Optimizing image...".tr);
      dev.log("Starting optimized upload process...");

      // Apply advanced optimization
      final File optimizedImage = await optimizeImage(image);
      dev.log("Advanced image optimization complete");

      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final Reference upload =
          FirebaseStorage.instance.ref().child('$folderPath$fileName');

      // Set storage priority and caching settings for faster uploads
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/${path.extension(image.path).substring(1)}',
        customMetadata: {
          'optimized': 'true',
          'timestamp': DateTime.now().toIso8601String(),
        },
        cacheControl: 'public, max-age=31536000', // Cache for 1 year
      );

      ShowToastDialog.showLoader("Uploading image...".tr);
      dev.log("Starting Firebase upload with optimized settings...");

      // Use a more efficient upload approach
      final UploadTask uploadTask = upload.putFile(optimizedImage, metadata);

      // Professional progress tracking (optimized for maximum speed)
      int lastProgressUpdate = 0;
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        final currentProgress = progress.round();

        // Professional optimization: Update UI only every 25% for maximum speed
        if (currentProgress - lastProgressUpdate >= 25 ||
            currentProgress == 100) {
          lastProgressUpdate = currentProgress;
          dev.log('⚡ Professional upload: ${progress.toStringAsFixed(1)}%');
          ShowToastDialog.showLoader(
              "⚡ ${"Fast Upload".tr}: $currentProgress%");
        }
      });

      // Wait for upload completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      ShowToastDialog.closeLoader();
      dev.log("Upload complete, URL received");

      return downloadUrl;
    } catch (e) {
      dev.log("Error during upload: $e");
      ShowToastDialog.closeLoader();
      return '';
    }
  }

  static Future<bool> isLogin() async {
    bool isLogin = false;
    if (FirebaseAuth.instance.currentUser != null) {
      isLogin = await userExitOrNot(FirebaseAuth.instance.currentUser!.uid);
    } else {
      isLogin = false;
    }
    return isLogin;
  }

  static Future<bool> currentCheckRideCheck() async {
    ShowToastDialog.showLoader("Please wait".tr);
    bool isFirst = false;
    await fireStore
        .collection(CollectionName.orders)
        .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where("status",
            whereIn: [Constant.rideInProgress, Constant.rideActive])
        .get()
        .then((value) {
          ShowToastDialog.closeLoader();
          print(value.size);
          if (value.size >= 1) {
            isFirst = true;
          } else {
            isFirst = false;
          }
        });
    return isFirst;
  }

  static Future<List<CancellationReasonModel>> getCancellationReasons() async {
    List<CancellationReasonModel> freightVehicle = [];
    await fireStore
        .collection(CollectionName.cancellationReasons)
        .where("enable", isEqualTo: true)
        .where("forDriver", isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        CancellationReasonModel documentModel =
            CancellationReasonModel.fromJson(element.data());
        freightVehicle.add(documentModel);
      }
    }).catchError((error) {
      dev.log(error.toString());
    });
    return freightVehicle;
  }

  static Query getReviewsQuery(String customerId) {
    return fireStore
        .collection(CollectionName.reviewCustomer)
        .where("customerId", isEqualTo: customerId)
        .orderBy('date', descending: true);
  }

  static Future<bool?> removeInterCityOrderBid(
      InterCityOrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .update(_addApiKey({
          "acceptedDriverId": FieldValue.arrayRemove([getCurrentUid()])
        }))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      dev.log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<OtherBannerModel>> getBannerOrder() async {
    List<OtherBannerModel> bannerList = [];
    await fireStore
        .collection(CollectionName.ads)
        .where("from_date", isLessThanOrEqualTo: DateTime.now())
        .where("expiry_date", isGreaterThan: DateTime.now())
        .get()
        .then((value) {
      for (var element in value.docs) {
        OtherBannerModel documentModel =
            OtherBannerModel.fromJson(element.data());
        bannerList.add(documentModel);
      }
    }).catchError((error) {
      dev.log("❌ Banner Error: ${error.toString()}");
    });
    return bannerList;
  }

  static Future<bool?> removeOrderBid(OrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .update(_addApiKey({
          "acceptedDriverId": FieldValue.arrayRemove([getCurrentUid()])
        }))
        .then((value) {
      isAdded = true;
      print("---- widthdraw bid success");
    }).catchError((error) {
      print("---- widthdraw bid fail $error");
      isAdded = false;
    });
    return isAdded;
  }

  Future<void> getGoogleAPIKey() async {
    try {
      final keyDoc = await fireStore
          .collection(CollectionName.settings)
          .doc("globalKey")
          .get();
      if (keyDoc.exists) {
        Constant.mapAPIKey = keyDoc.data()?["googleMapKey"] ?? "";
      }
    } catch (e, s) {
      dev.log("⚠️ globalKey failed", error: e, stackTrace: s);
    }

    try {
      final notifyDoc = await fireStore
          .collection(CollectionName.settings)
          .doc("notification_setting")
          .get();
      if (notifyDoc.exists && notifyDoc.data() != null) {
        final data = notifyDoc.data()!;
        Constant.senderId = data['senderId']?.toString() ?? "";
        Constant.jsonNotificationFileURL =
            data['serviceJson']?.toString() ?? "";
      }
    } catch (e, s) {
      dev.log("⚠️ notification_setting failed", error: e, stackTrace: s);
    }

    try {
      final valueDoc = await fireStore
          .collection(CollectionName.settings)
          .doc("globalValue")
          .get();
      if (valueDoc.exists) {
        final data = valueDoc.data()!;
        Constant.distanceType = data["distanceType"] ?? "";
        Constant.radius = data["radius"] ?? 0;
        Constant.minimumAmountToWithdrawal =
            data["minimumAmountToWithdrawal"] ?? 0;
        Constant.minimumDepositToRideAccept =
            data["minimumDepositToRideAccept"] ?? 0;
        Constant.mapType = data["mapType"] ?? "";
        Constant.selectedMapType = data["selectedMapType"] ?? "";
        Constant.driverLocationUpdate = data["driverLocationUpdate"] ?? 10;
        Constant.isVerifyDocument = data["isVerifyDocument"] ?? false;
        Constant.isSubscriptionModelApplied =
            data["subscription_model"] ?? false;
        Constant.regionCode = data["regionCode"] ?? "";
        Constant.regionCountry = data["regionCountry"] ?? "";
      }
    } catch (e, s) {
      dev.log("⚠️ globalValue failed", error: e, stackTrace: s);
    }

    try {
      final adminDoc = await fireStore
          .collection(CollectionName.settings)
          .doc("adminCommission")
          .get();
      if (adminDoc.data() != null) {
        Constant.adminCommission = AdminCommission.fromJson(adminDoc.data()!);
      }
    } catch (e, s) {
      dev.log("⚠️ adminCommission failed", error: e, stackTrace: s);
    }

    try {
      final referralDoc = await fireStore
          .collection(CollectionName.settings)
          .doc("referral")
          .get();
      if (referralDoc.exists) {
        Constant.referralAmount = referralDoc.data()?["referralAmount"] ?? 0;
      }
    } catch (e, s) {
      dev.log("⚠️ referral failed", error: e, stackTrace: s);
    }

    try {
      final globalDoc = await fireStore
          .collection(CollectionName.settings)
          .doc("global")
          .get();
      if (globalDoc.exists && globalDoc.data() != null) {
        final data = globalDoc.data()!;
        Constant.privacyPolicy = (data["privacyPolicy"] as List<dynamic>? ?? [])
            .map((v) => LanguagePrivacyPolicy.fromJson(v))
            .toList();
        Constant.termsAndConditions =
            (data["termsAndConditions"] as List<dynamic>? ?? [])
                .map((v) => LanguageTermsCondition.fromJson(v))
                .toList();
        Constant.appVersion = data["appVersion"] ?? "";
      }
    } catch (e, s) {
      dev.log("⚠️ global terms/privacy failed", error: e, stackTrace: s);
    }

    try {
      final contactDoc = await fireStore
          .collection(CollectionName.settings)
          .doc("contact_us")
          .get();
      if (contactDoc.exists && contactDoc.data() != null) {
        Constant.supportURL = contactDoc.data()?["supportURL"] ?? "";
        Constant.phone = contactDoc.data()?["emergencyPhoneNumber"] ?? "";
      }
    } catch (e, s) {
      dev.log("⚠️ contact_us failed", error: e, stackTrace: s);
    }
  }

  // static String getCurrentUid() {
  //   return FirebaseAuth.instance.currentUser!.uid;
  // }
  static String getCurrentUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (Constant.isGuestUser) return "guest";
      throw Exception("User is not logged in");
    }
    return user.uid;
  }

  static Future<bool> viewWallet() async {
    bool wallet = false;
    try {
      final querySnapshot = await fireStore
          .collection(CollectionName.settings)
          .doc("globalKey")
          .get();
      wallet = querySnapshot["wallet"];
      return wallet;
    } catch (e) {
      dev.log('Error checking pending wallet charge: $e');
      return wallet;
    }
  }

  static Future<String> getEmergencyPhoneNumber() async {
    String phone = "";
    await fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) async {
      if (value.data() != null) {
        phone = value.data()!["emergencyPhoneNumber"];
      }
      return;
    });
    return phone;
  }

  static Future<String> getWhatsAppNumber() async {
    await fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) {
      return value.data()!["whatsappNumber"];
    });
    return "";
  }

  static Future<List<BannerModel>> getBanner() async {
    List<BannerModel> bannerList = [];
    String userType = 'driver';
    String positionField =
        userType == 'driver' ? 'position_driver' : 'position_customer';

    await fireStore
        .collection(CollectionName.banner)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .where('forWho', whereIn: ['driver', 'both'])
        .get()
        .then((value) {
          for (var element in value.docs) {
            BannerModel documentModel = BannerModel.fromJson(element.data());
            bannerList.add(documentModel);
          }

          bannerList.sort((a, b) {
            int aPos = int.tryParse(a.toJson()[positionField].toString())!;
            int bPos = int.tryParse(b.toJson()[positionField].toString())!;
            return aPos.compareTo(bPos);
          });
          print("✅ تم جلب وترتيب البانرات: ${bannerList.length}");
        })
        .catchError((error) {
          dev.log("❌ Banner Error: ${error.toString()}");
        });

    return bannerList;
  }

  static Future<DriverUserModel?> getDriverProfile(String uuid) async {
    DriverUserModel? driverModel;
    await fireStore
        .collection(CollectionName.driverUsers)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        driverModel = DriverUserModel.fromJson(value.data()!);
        driverModel!.id = uuid;
      }
    }).catchError((error) {
      dev.log("Failed to update user: $error");
      driverModel = null;
    });
    return driverModel;
  }

  static Future<UserModel?> getCustomer(String uuid) async {
    UserModel? userModel;
    await fireStore
        .collection(CollectionName.users)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        userModel = UserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      dev.log("Failed to update user: $error");
      userModel = null;
    });
    return userModel;
  }

  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.users)
        .doc(userModel.id)
        .set(_addApiKey(userModel.toJson()))
        .whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      dev.log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  Future<PaymentModel?> getPayment() async {
    PaymentModel? paymentModel;
    await fireStore
        .collection(CollectionName.settings)
        .doc("payment")
        .get()
        .then((value) {
      paymentModel = PaymentModel.fromJson(value.data()!);
    });
    return paymentModel;
  }

  Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currencyModel;
    await fireStore
        .collection(CollectionName.currency)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        currencyModel = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currencyModel;
  }

  static Future<bool> updateDriverUser(DriverUserModel userModel) async {
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.driverUsers)
        .doc(userModel.id)
        .set(_addApiKey(userModel.toJson()))
        .whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      ShowToastDialog.showToast("Failed to update user: $error");
      print('ERROR!->$error');
      isUpdate = false;
    });
    return isUpdate;
  }

  static Future<bool> checkUserInCollection(
      String uid, String collectionName) async {
    try {
      DocumentSnapshot doc =
          await fireStore.collection(collectionName).doc(uid).get();
      return doc.exists;
    } catch (e) {
      dev.log("checkUserInCollection error: $e");
      return false;
    }
  }

  static Future<DriverIdAcceptReject?> getAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<DriverIdAcceptReject?> getInterCItyAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<bool> userExitOrNot(String uid) async {
    bool isExit = false;

    await fireStore.collection(CollectionName.driverUsers).doc(uid).get().then(
      (value) {
        if (value.exists) {
          isExit = true;
        } else {
          isExit = false;
        }
      },
    ).catchError((error) {
      isExit = false;
    });
    return isExit;
  }

  static Future<List<DocumentModel>> getDocumentList() async {
    List<DocumentModel> documentList = [];
    await fireStore
        .collection(CollectionName.documents)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .get()
        .then((value) {
      for (var element in value.docs) {
        DocumentModel documentModel = DocumentModel.fromJson(element.data());
        documentList.add(documentModel);
      }
    }).catchError((error) {});
    return documentList;
  }

  static Future<List<ServiceModel>> getService() async {
    List<ServiceModel> serviceList = [];

    // Fetch from regular service collection
    await fireStore
        .collection(CollectionName.service)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      print("✅ تم جلب ${value.docs.length} خدمة مفعّلة من مجموعة service");
      for (var element in value.docs) {
        ServiceModel documentModel = ServiceModel.fromJson(element.data());
        print(
            "📦 خدمة عادية: ${documentModel.title}, ID: ${documentModel.id}, Enabled: ${element.data()['enable']}");
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      print("خطأ في جلب الخدمات العادية: $error");
    });

    // Fetch from intercity service collection
    await fireStore
        .collection(CollectionName.intercityService)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      print(
          "✅ تم جلب ${value.docs.length} خدمة مفعّلة من مجموعة intercity_service");
      for (var element in value.docs) {
        // Parse as IntercityServiceModel first
        IntercityServiceModel intercityService =
            IntercityServiceModel.fromJson(element.data());

        // Convert to ServiceModel format
        Map<String, dynamic> serviceData = {
          'image': intercityService.image,
          'enable': intercityService.enable,
          'offerRate': intercityService.offerRate,
          'id': intercityService.id,
          'kmCharge': intercityService.kmCharge,
          'intercityType': true, // Mark as intercity service
          'title': intercityService.name
              ?.map((languageName) =>
                  {'title': languageName.name, 'type': languageName.type})
              .toList()
        };

        ServiceModel documentModel = ServiceModel.fromJson(serviceData);
        print(
            "📦 خدمة بين المدن: ${documentModel.title}, ID: ${documentModel.id}, Enabled: ${element.data()['enable']}");
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      print("خطأ في جلب خدمات بين المدن: $error");
    });

    print("✅ إجمالي الخدمات المجلبة: ${serviceList.length}");
    return serviceList;
  }

  static Future<bool> hasChargeWalletPending() async {
    try {
      final querySnapshot = await fireStore
          .collection(CollectionName.chargeWallet)
          .where('userID', isEqualTo: getCurrentUid())
          .where('state', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getStatusForChargeWallet(String walletID) async {
    String status = "";
    var data = await fireStore
        .collection(CollectionName.chargeWallet)
        .where("walletTransaction", isEqualTo: walletID)
        .get();
    if (data.docs.isNotEmpty) {
      status = data.docs.first['state'];
    } else {
      status = "not found";
    }
    return status;
  }

  static Future<void> setChargeTransaction(File image, double amount) async {
    String imageURL = "";
    // Don't show loader here - it's already shown in wallet controller
    try {
      // Use our optimized upload method instead of Constant.uploadUserImageToFireStorage
      imageURL = await uploadUserImageToStorage(image, "chargeWallet/");
      // Generate a unique ID for the transaction to avoid additional DB calls
      final String transactionId = const Uuid().v4();
      // Prepare all data before writing to Firestore
      final Map<String, dynamic> transactionData = {
        "id": transactionId,
        "state": "pending",
        "amount": amount.toString(),
        "createdDate": Timestamp.now(),
        "note": "Charge Wallet",
        "orderType": "",
        "paymentType": "",
        "transactionId": "",
        "userId": getCurrentUid(),
        "userType": "driver"
      };
      // Prepare charge wallet data
      final Map<String, dynamic> chargeWalletData = {
        "image": imageURL,
        "type": "Driver",
        "state": "pending",
        "amount": amount,
        "time": Timestamp.now(),
        "userID": getCurrentUid(),
        "walletTransaction": transactionId
      };
      // Use batch write for better performance
      final WriteBatch batch = fireStore.batch();
      // Set transaction document with predefined ID
      final DocumentReference transactionRef = fireStore
          .collection(CollectionName.walletTransaction)
          .doc(transactionId);
      batch.set(transactionRef, _addApiKey(transactionData));
      // Add charge wallet document
      final DocumentReference chargeRef =
          fireStore.collection(CollectionName.chargeWallet).doc();
      batch.set(chargeRef, _addApiKey(chargeWalletData));
      // Commit the batch
      await batch.commit();
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("chargeWalletUploaded".tr);
    } catch (e) {
      dev.log("Error in setChargeTransaction: $e");
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("${"Upload Error".tr}: ${e.toString()}");
    }
  }

  static Future<DriverDocumentModel?> getDocumentOfDriver() async {
    DriverDocumentModel? driverDocumentModel;
    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        driverDocumentModel = DriverDocumentModel.fromJson(value.data()!);
      }
    });
    return driverDocumentModel;
  }

  static Future<bool> uploadDriverDocument(Documents documents) async {
    bool isAdded = false;
    DriverDocumentModel driverDocumentModel = DriverDocumentModel();
    List<Documents> documentsList = [];
    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .get()
        .then((value) async {
      if (value.exists) {
        DriverDocumentModel newDriverDocumentModel =
            DriverDocumentModel.fromJson(value.data()!);
        documentsList = newDriverDocumentModel.documents!;
        var contain = newDriverDocumentModel.documents!
            .where((element) => element.documentId == documents.documentId);
        if (contain.isEmpty) {
          documentsList.add(documents);

          driverDocumentModel.id = getCurrentUid();
          driverDocumentModel.documents = documentsList;
        } else {
          var index = newDriverDocumentModel.documents!.indexWhere(
              (element) => element.documentId == documents.documentId);

          driverDocumentModel.id = getCurrentUid();
          documentsList.removeAt(index);
          documentsList.insert(index, documents);
          driverDocumentModel.documents = documentsList;
          isAdded = false;
          ShowToastDialog.showToast("Document is under verification");
        }
      } else {
        documentsList.add(documents);
        driverDocumentModel.id = getCurrentUid();
        driverDocumentModel.documents = documentsList;
      }
    });

    await fireStore
        .collection(CollectionName.driverDocument)
        .doc(getCurrentUid())
        .set(_addApiKey(driverDocumentModel.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });

    return isAdded;
  }

  static Future<List<VehicleTypeModel>?> getVehicleType() async {
    List<VehicleTypeModel> vehicleList = [];
    await fireStore
        .collection(CollectionName.vehicleType)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        VehicleTypeModel vehicleModel =
            VehicleTypeModel.fromJson(element.data());
        vehicleList.add(vehicleModel);
      }
    });
    return vehicleList;
  }

  static Future<List<VehicleYearModel>?> getCarVehicleYear() async {
    List<VehicleYearModel> vehicleYear = [];
    Set<String> addedYears = {};

    await fireStore
        .collection(CollectionName.vehicleYear)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        VehicleYearModel vehicleModel =
            VehicleYearModel.fromJson(element.data());

        if (vehicleModel.year != null &&
            !addedYears.contains(vehicleModel.year)) {
          vehicleYear.add(vehicleModel);
          addedYears.add(vehicleModel.year!);
        }
      }
    });

    vehicleYear.sort((a, b) {
      int yearA = int.tryParse(a.year ?? '') ?? 0;
      int yearB = int.tryParse(b.year ?? '') ?? 0;
      return yearA.compareTo(yearB);
    });

    return vehicleYear;
  }

  static Future<List<DriverRulesModel>?> getDriverRules() async {
    List<DriverRulesModel> driverRulesModel = [];
    await fireStore
        .collection(CollectionName.driverRules)
        .where('enable', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        DriverRulesModel vehicleModel =
            DriverRulesModel.fromJson(element.data());
        driverRulesModel.add(vehicleModel);
      }
    });
    return driverRulesModel;
  }

  StreamController<List<OrderModel>>? getNearestOrderRequestController;

  Stream<List<OrderModel>> getOrders(DriverUserModel driverUserModel,
      double? latitude, double? longLatitude) async* {
    dev.log("Driver ID = ${driverUserModel.id}");
    dev.log("Zone ID = ${driverUserModel.zoneIds}");
    //[log] Driver ID = XTKwAD96bFWG5N3t7UetRH8LPex1
    // [log] Zone ID = [2UVJiNEQ8TESj6LGaWSZ]
    getNearestOrderRequestController =
        StreamController<List<OrderModel>>.broadcast();
    List<OrderModel> ordersList = [];
    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.orders)
        .where('serviceId', isEqualTo: driverUserModel.serviceId)
        .where('zoneIds', arrayContainsAny: driverUserModel.zoneIds)
        .where('status', isEqualTo: Constant.ridePlaced);

    GeoFirePoint center = Geoflutterfire()
        .point(latitude: latitude ?? 0.0, longitude: longLatitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
        .collection(collectionRef: query)
        .within(
            center: center,
            radius: double.parse(Constant.radius),
            field: 'position',
            strictMode: true);
    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      // documentList.forEach((d){
      //   log("Document: ${d.id}");
      //   log("Data: ${d.data()}");
      // });
      for (var document in documentList) {
        final data = document.data() as Map<String, dynamic>;
        OrderModel orderModel = OrderModel.fromJson(data);
        if (orderModel.acceptedDriverId != null &&
            orderModel.acceptedDriverId!.isNotEmpty) {
          if (!orderModel.acceptedDriverId!
              .contains(FireStoreUtils.getCurrentUid())) {
            ordersList.add(orderModel);
          }
          //ordersList.add(orderModel);
        } else {
          ordersList.add(orderModel);
        }
      }

      getNearestOrderRequestController!.sink.add(ordersList);
    });
    yield* getNearestOrderRequestController!.stream;
  }

  StreamController<List<InterCityOrderModel>>?
      getNearestFreightOrderRequestController;

  Stream<List<InterCityOrderModel>> getFreightOrders(
      double? latitude, double? longLatitude) async* {
    getNearestFreightOrderRequestController =
        StreamController<List<InterCityOrderModel>>.broadcast();
    List<InterCityOrderModel> ordersList = [];
    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.ordersIntercity)
        .where('intercityServiceId', isEqualTo: "Kn2VEnPI3ikF58uK8YqY")
        .where('status', isEqualTo: Constant.ridePlaced);
    GeoFirePoint center = Geoflutterfire()
        .point(latitude: latitude ?? 0.0, longitude: longLatitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
        .collection(collectionRef: query)
        .within(
            center: center,
            radius: double.parse(Constant.radius),
            field: 'position',
            strictMode: true);

    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      for (var document in documentList) {
        final data = document.data() as Map<String, dynamic>;
        InterCityOrderModel orderModel = InterCityOrderModel.fromJson(data);
        if (orderModel.acceptedDriverId != null &&
            orderModel.acceptedDriverId!.isNotEmpty) {
          if (!orderModel.acceptedDriverId!
              .contains(FireStoreUtils.getCurrentUid())) {
            ordersList.add(orderModel);
          }
        } else {
          ordersList.add(orderModel);
        }
      }
      getNearestFreightOrderRequestController!.sink.add(ordersList);
    });

    yield* getNearestFreightOrderRequestController!.stream;
  }

  closeStream() {
    if (getNearestOrderRequestController != null) {
      getNearestOrderRequestController!.close();
    }
  }

  closeFreightStream() {
    if (getNearestFreightOrderRequestController != null) {
      getNearestFreightOrderRequestController!.close();
    }
  }

  static Future<String> getStoreVersion() async {
    try {
      DocumentSnapshot versionDoc = await FirebaseFirestore.instance
          .collection(CollectionName.settings)
          .doc("globalKey")
          .get();

      final dynamic raw = Platform.isAndroid
          ? (versionDoc['versionAndroid'])
          : (versionDoc['versionIOS']);
      final String value = (raw ?? "").toString().trim();
      dev.log(
          "🧭 Firestore store version fetched → '${Platform.isAndroid ? 'android' : 'ios'}': '$value'");
      return value;
    } catch (e) {
      dev.log("❗ getStoreVersion error: $e");
      return "";
    }
  }

  static Future<void> updateDriverRides() async {
    await fireStore
        .collection(CollectionName.driverUsers)
        .doc(getCurrentUid())
        .set(
            _addApiKey({
              "totalRides": FieldValue.increment(1),
            }),
            SetOptions(merge: true));
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .set(_addApiKey(orderModel.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> bankDetailsIsAvailable() async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.exists) {
        isAdded = true;
      } else {
        isAdded = false;
      }
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<OrderModel?> getOrder(String orderId) async {
    OrderModel? orderModel;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = OrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<InterCityOrderModel?> getInterCityOrder(String orderId) async {
    InterCityOrderModel? orderModel;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = InterCityOrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<bool?> acceptRide(
      OrderModel orderModel, DriverIdAcceptReject driverIdAcceptReject) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .collection("acceptedDriver")
        .doc(driverIdAcceptReject.driverId)
        .set(_addApiKey(driverIdAcceptReject.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.reviewCustomer)
        .doc(reviewModel.id)
        .set(_addApiKey(reviewModel.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<ReviewModel?> getReview(String orderId) async {
    ReviewModel? reviewModel;
    await fireStore
        .collection(CollectionName.reviewCustomer)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        reviewModel = ReviewModel.fromJson(value.data()!);
      }
    });
    return reviewModel;
  }

  static Future<bool?> setInterCityOrder(InterCityOrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .set(_addApiKey(orderModel.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> acceptInterCityRide(InterCityOrderModel orderModel,
      DriverIdAcceptReject driverIdAcceptReject) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .collection("acceptedDriver")
        .doc(driverIdAcceptReject.driverId)
        .set(driverIdAcceptReject.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];

    await fireStore
        .collection(CollectionName.walletTransaction)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) async {
      for (var element in value.docs) {
        WalletTransactionModel taxModel =
            WalletTransactionModel.fromJson(element.data());
        if (element["note"] == "Charge Wallet") {
          taxModel.transactionId = element.id;
          taxModel.state = await getStatusForChargeWallet(element.id);
        }
        walletTransactionModel.add(taxModel);
      }
    }).catchError((error) {});
    return walletTransactionModel;
  }

  // 🚀 EXPERT PAGINATION: New paginated method for wallet transactions
  static Future<Map<String, dynamic>> getWalletTransactionsPaginated({
    required int limit,
    DocumentSnapshot? lastDocument,
  }) async {
    List<WalletTransactionModel> walletTransactionModel = [];
    DocumentSnapshot? newLastDocument;

    try {
      Query query = fireStore
          .collection(CollectionName.walletTransaction)
          .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
          .orderBy('createdDate', descending: true)
          .limit(limit);

      // If we have a lastDocument, start after it for pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot querySnapshot = await query.get();

      for (var element in querySnapshot.docs) {
        WalletTransactionModel taxModel = WalletTransactionModel.fromJson(
            element.data() as Map<String, dynamic>);
        if (element["note"] == "Charge Wallet") {
          taxModel.transactionId = element.id;
          taxModel.state = await getStatusForChargeWallet(element.id);
        }
        walletTransactionModel.add(taxModel);
      }

      // Store the last document for next pagination
      if (querySnapshot.docs.isNotEmpty) {
        newLastDocument = querySnapshot.docs.last;
      }

      dev.log(
          "📄 EXPERT PAGINATION: Loaded ${walletTransactionModel.length} transactions");

      return {
        'transactions': walletTransactionModel,
        'lastDocument': newLastDocument,
      };
    } catch (error) {
      dev.log("❌ Error loading paginated transactions: $error");
      return {
        'transactions': <WalletTransactionModel>[],
        'lastDocument': null,
      };
    }
  }

  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.walletTransaction)
        .doc(walletTransactionModel.id)
        .set(_addApiKey(walletTransactionModel.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> updatedDriverWallet({required String amount}) async {
    bool isAdded = false;
    await getDriverProfile(FireStoreUtils.getCurrentUid()).then((value) async {
      if (value != null) {
        DriverUserModel userModel = value;
        userModel.walletAmount =
            (double.parse(userModel.walletAmount.toString()) +
                    double.parse(amount))
                .toString();
        await FireStoreUtils.updateDriverUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  static Future<List<LanguageModel>?> getLanguage() async {
    List<LanguageModel> languageList = [];

    await fireStore
        .collection(CollectionName.languages)
        .where("enable", isEqualTo: true)
        .where("isDeleted", isEqualTo: false)
        .get()
        .then((value) {
      for (var element in value.docs) {
        LanguageModel taxModel = LanguageModel.fromJson(element.data());
        languageList.add(taxModel);
      }
    }).catchError((error) {});
    return languageList;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore
        .collection(CollectionName.onBoarding)
        .where("type", isEqualTo: "driverApp")
        .get()
        .then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel =
            OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {});
    return onBoardingModel;
  }

  static Future addInBox(InboxModel inboxModel) async {
    return await fireStore
        .collection(CollectionName.chat)
        .doc(inboxModel.orderId)
        .set(_addApiKey(inboxModel.toJson()))
        .then((document) {
      return inboxModel;
    });
  }

  static Future addChat(ConversationModel conversationModel) async {
    return await fireStore
        .collection(CollectionName.chat)
        .doc(conversationModel.orderId)
        .collection("thread")
        .doc(conversationModel.id)
        .set(_addApiKey(conversationModel.toJson()))
        .then((document) {
      return conversationModel;
    });
  }

  static Future<BankDetailsModel?> getBankDetails() async {
    BankDetailsModel? bankDetailsModel;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.data() != null) {
        bankDetailsModel = BankDetailsModel.fromJson(value.data()!);
      }
    });
    return bankDetailsModel;
  }

  static Future<bool?> updateBankDetails(
      BankDetailsModel bankDetailsModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.bankDetails)
        .doc(bankDetailsModel.userId)
        .set(_addApiKey(bankDetailsModel.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> setWithdrawRequest(WithdrawModel withdrawModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.withdrawalHistory)
        .doc(withdrawModel.id)
        .set(_addApiKey(withdrawModel.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<WithdrawModel>> getWithDrawRequest() async {
    List<WithdrawModel> withdrawalList = [];
    await fireStore
        .collection(CollectionName.withdrawalHistory)
        .where('userId', isEqualTo: getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        WithdrawModel documentModel = WithdrawModel.fromJson(element.data());
        withdrawalList.add(documentModel);
      }
    }).catchError((error) {});
    return withdrawalList;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      await fireStore
          .collection(CollectionName.driverUsers)
          .doc(FireStoreUtils.getCurrentUid())
          .delete();

      // delete user  from firebase auth
      await FirebaseAuth.instance.currentUser!.delete().then((value) {
        isDelete = true;
      });
    } catch (e, s) {
      dev.log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isDelete;
  }

  static Future<bool> getIntercityFirstOrderOrNOt(
      InterCityOrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future updateIntercityReferralAmount(
      InterCityOrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                      double.parse(Constant.referralAmount.toString()))
                  .toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                  id: Constant.getUuid(),
                  amount: Constant.referralAmount.toString(),
                  createdDate: Timestamp.now(),
                  paymentType: "Wallet".tr,
                  transactionId: orderModel.id,
                  userId: user.id.toString(),
                  orderType: "intercity",
                  userType: "customer",
                  note: "Referral Amount");

              await FireStoreUtils.setWalletTransaction(transactionModel);
            } catch (error) {}
          }
        });
      } else {
        return;
      }
    }
  }

  static Future<bool> getFirestOrderOrNOt(OrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future updateReferralAmount(OrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        await fireStore
            .collection(CollectionName.users)
            .doc(referralModel!.referralBy)
            .get()
            .then((value) async {
          DocumentSnapshot<Map<String, dynamic>> userDocument = value;
          if (userDocument.data() != null && userDocument.exists) {
            try {
              UserModel user = UserModel.fromJson(userDocument.data()!);
              user.walletAmount = (double.parse(user.walletAmount.toString()) +
                      double.parse(Constant.referralAmount.toString()))
                  .toString();
              updateUser(user);

              WalletTransactionModel transactionModel = WalletTransactionModel(
                  id: Constant.getUuid(),
                  amount: Constant.referralAmount.toString(),
                  createdDate: Timestamp.now(),
                  paymentType: "Wallet".tr,
                  transactionId: orderModel.id,
                  userId: user.id.toString(),
                  orderType: "city",
                  userType: "customer",
                  note: "Referral Amount");

              await FireStoreUtils.setWalletTransaction(transactionModel);
            } catch (error) {
              print(error);
            }
          }
        });
      } else {
        return;
      }
    }
  }

  static Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> airPortList = [];
    await fireStore
        .collection(CollectionName.zone)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ZoneModel ariPortModel = ZoneModel.fromJson(element.data());
        airPortList.add(ariPortModel);
      }
    }).catchError((error) {});
    return airPortList;
  }

  static Future<List<SubscriptionPlanModel>> getAllSubscriptionPlans() async {
    List<SubscriptionPlanModel> subscriptionPlanModels = [];
    await fireStore
        .collection(CollectionName.subscriptionPlans)
        .where('isEnable', isEqualTo: true)
        .orderBy('place', descending: false)
        .get()
        .then((value) async {
      if (value.docs.isNotEmpty) {
        for (var element in value.docs) {
          SubscriptionPlanModel subscriptionPlanModel =
              SubscriptionPlanModel.fromJson(element.data());
          if (subscriptionPlanModel.id != Constant.commissionSubscriptionID) {
            subscriptionPlanModels.add(subscriptionPlanModel);
          }
        }
      }
    });
    return subscriptionPlanModels;
  }

  static Future<SubscriptionPlanModel?> getSubscriptionPlanById(
      {required String planId}) async {
    SubscriptionPlanModel? subscriptionPlanModel = SubscriptionPlanModel();
    if (planId.isNotEmpty) {
      await fireStore
          .collection(CollectionName.subscriptionPlans)
          .doc(planId)
          .get()
          .then((value) async {
        if (value.exists) {
          subscriptionPlanModel = SubscriptionPlanModel.fromJson(
              value.data() as Map<String, dynamic>);
        }
      });
    }
    return subscriptionPlanModel;
  }

  static Future<SubscriptionPlanModel> setSubscriptionPlan(
      SubscriptionPlanModel subscriptionPlanModel) async {
    if (subscriptionPlanModel.id?.isEmpty == true) {
      subscriptionPlanModel.id = const Uuid().v4();
    }
    await fireStore
        .collection(CollectionName.subscriptionPlans)
        .doc(subscriptionPlanModel.id)
        .set(_addApiKey(subscriptionPlanModel.toJson()))
        .then((value) async {});
    return subscriptionPlanModel;
  }

  static Future<bool?> setSubscriptionTransaction(
      SubscriptionHistoryModel subscriptionPlan) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.subscriptionHistory)
        .doc(subscriptionPlan.id)
        .set(_addApiKey(subscriptionPlan.toJson()))
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      isAdded = false;
    });
    return isAdded;
  }

  static Future<List<SubscriptionHistoryModel>> getSubscriptionHistory() async {
    List<SubscriptionHistoryModel> subscriptionHistoryList = [];
    await fireStore
        .collection(CollectionName.subscriptionHistory)
        .where('user_id', isEqualTo: getCurrentUid())
        .orderBy('createdAt', descending: true)
        .get()
        .then((value) async {
      if (value.docs.isNotEmpty) {
        for (var element in value.docs) {
          SubscriptionHistoryModel subscriptionHistoryModel =
              SubscriptionHistoryModel.fromJson(element.data());
          subscriptionHistoryList.add(subscriptionHistoryModel);
        }
      }
    });
    return subscriptionHistoryList;
  }
}
