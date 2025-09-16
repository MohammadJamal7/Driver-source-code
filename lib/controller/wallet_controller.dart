import 'dart:developer' as dev;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/model/bank_details_model.dart';
import 'package:driver/model/payment_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:get/get.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';

class WalletController extends GetxController {
  Rx<TextEditingController> withdrawalAmountController =
      TextEditingController().obs;
  Rx<TextEditingController> noteController = TextEditingController().obs;

  @override
  void onClose() {
    withdrawalAmountController.value.dispose();
    noteController.value.dispose();
    amountController.value.dispose();
    super.onClose();
  }

  Rx<TextEditingController> amountController = TextEditingController().obs;
  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  Rx<DriverUserModel> driverUserModel = DriverUserModel().obs;
  Rx<BankDetailsModel> bankDetailsModel = BankDetailsModel().obs;
  RxString selectedPaymentMethod = "".obs;
  Rxn<XFile> imagePrice = Rxn<XFile>();

  RxBool isLoading = false.obs;
  RxBool isLoadingTransactions = true.obs; // Initial loading state
  RxBool isLoadingMore = false.obs; // Loading more transactions
  RxBool hasMoreTransactions = true.obs; // Has more data to load
  RxList transactionList = <WalletTransactionModel>[].obs;
  bool hasChargeAmount = false;
  RxBool viewWallet = false.obs; // 🔥 EXPERT FIX: Make viewWallet reactive

  // Pagination variables
  DocumentSnapshot? lastDocument;
  final int pageSize = 15;

  @override
  void onInit() {
    viewWalletCharge();
    getUser();
    getTraction();
    super.onInit();
  }

  void viewWalletCharge() async {
    viewWallet.value = await FireStoreUtils.viewWallet();
  }

  void setCharge() async {
    dev.log("🚀 EXPERT DEBUG: setCharge() method called!");
    if (imagePrice.value == null) {
      ShowToastDialog.showToast("Select Image".tr);
    } else if (amountController.value.text.isEmpty) {
      ShowToastDialog.showToast("Enter Amount".tr);
    } else if (double.tryParse(amountController.value.text) == null ||
        double.parse(amountController.value.text) <= 0) {
      ShowToastDialog.showToast("Enter Valid Amount".tr);
    } else {
      try {
        String processingMessage = "Processing your request...".tr;
        dev.log("🌐 Processing message: $processingMessage");
        ShowToastDialog.showLoader(processingMessage);
        File imageFile = File(imagePrice.value!.path);

        dev.log("💰 Processing wallet charge request...");
        // The image will be optimized during the upload process
        await FireStoreUtils.setChargeTransaction(
          imageFile,
          double.tryParse(amountController.value.text) ?? 0.0,
        ).then((value) {
          imagePrice.value = null;
          amountController.value.clear();
          hasChargeAmount = true;
          getTraction();
          ShowToastDialog.closeLoader();
          Get.back();
          ShowToastDialog.showToast("Transaction added successfully!".tr);
        });
      } catch (e) {
        dev.log("❌ Error processing transaction: $e");
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "Error processing transaction. Please try again.".tr);
      }
    }
  }

  getUser() async {
    await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      if (value != null) {
        driverUserModel.value = value;
      }
    });

    await FireStoreUtils.getBankDetails().then((value) {
      if (value != null) {
        bankDetailsModel.value = value;
      }
    });
  }

  getTraction() async {
    // Reset pagination state for initial load
    lastDocument = null;
    hasMoreTransactions.value = true;
    transactionList.clear();

    isLoadingTransactions.value = true;
    try {
      await loadTransactions();
    } catch (e) {
      dev.log("Error loading initial transactions: $e");
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  // Load transactions with pagination
  Future<void> loadTransactions() async {
    try {
      Map<String, dynamic> result =
          await FireStoreUtils.getWalletTransactionsPaginated(
        limit: pageSize,
        lastDocument: lastDocument,
      );

      List<WalletTransactionModel> newTransactions =
          result['transactions'] as List<WalletTransactionModel>;
      lastDocument = result['lastDocument'] as DocumentSnapshot?;

      if (newTransactions.isNotEmpty) {
        transactionList.addAll(newTransactions);

        // Update pagination state
        if (newTransactions.length == pageSize) {
          // There might be more data
          hasMoreTransactions.value = true;
        } else {
          // This was the last page
          hasMoreTransactions.value = false;
        }
      } else {
        hasMoreTransactions.value = false;
      }
    } catch (e) {
      dev.log("Error loading transactions: $e");
      hasMoreTransactions.value = false;
    }
  }

  // Load more transactions for infinite scroll
  Future<void> loadMoreTransactions() async {
    if (isLoadingMore.value || !hasMoreTransactions.value) return;

    isLoadingMore.value = true;
    try {
      await loadTransactions();
    } catch (e) {
      dev.log("Error loading more transactions: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }
}
