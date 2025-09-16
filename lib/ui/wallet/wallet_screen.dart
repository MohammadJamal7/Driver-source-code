import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/wallet_controller.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/wallet_transaction_model.dart';
import 'package:driver/model/withdraw_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/ui/order_intercity_screen/complete_intecity_order_screen.dart';
import 'package:driver/ui/order_screen/complete_order_screen.dart';
import 'package:driver/ui/withdraw_history/withdraw_history_screen.dart';
import 'package:driver/ui/wallet/widgets/wallet_skeleton_loader.dart';
import 'package:driver/ui/wallet/widgets/infinite_scroll_transactions.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<WalletController>(
        init: WalletController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            body: controller.isLoading.value
                ? Constant.loader(context)
                : Column(
                    children: [
                      Container(
                        height: Responsive.width(24, context),
                        width: Responsive.width(100, context),
                        color: AppColors.primary,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Balance".tr,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16),
                                    ),
                                    Text(
                                      Constant.amountShow(
                                          amount: controller.driverUserModel
                                              .value.walletAmount
                                              .toString()),
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 24),
                                    ),
                                  ],
                                ),
                              ),
                              if (controller.viewWallet.value)
                                Transform.translate(
                                  offset: const Offset(0, -22),
                                  child: MaterialButton(
                                    onPressed: () async {
                                      if (!await FireStoreUtils
                                          .hasChargeWalletPending()) {
                                        paymentMethodDialog(
                                            context, controller);
                                      } else {
                                        ShowToastDialog.showToast(
                                            "WaitAdminApproval".tr);
                                      }
                                    },
                                    height: 40,
                                    elevation: 0.5,
                                    minWidth: 0.40,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    color: themeChange.getThem()
                                        ? AppColors.darkModePrimary
                                        : Colors.white,
                                    child: Text(
                                      "Topup Wallet".tr.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25))),
                          child: InfiniteScrollTransactions(
                            controller: controller,
                            onTransactionTap: (walletTransactionModel) async {
                              if (walletTransactionModel.orderType == "city") {
                                await FireStoreUtils.getOrder(
                                        walletTransactionModel.transactionId
                                            .toString())
                                    .then((value) {
                                  if (value != null) {
                                    OrderModel orderModel = value;
                                    Get.to(const CompleteOrderScreen(),
                                        arguments: {
                                          "orderModel": orderModel,
                                        });
                                  }
                                });
                              } else if (walletTransactionModel.orderType ==
                                  "intercity") {
                                await FireStoreUtils.getInterCityOrder(
                                        walletTransactionModel.transactionId
                                            .toString())
                                    .then((value) {
                                  if (value != null) {
                                    InterCityOrderModel orderModel = value;
                                    Get.to(const CompleteIntercityOrderScreen(),
                                        arguments: {
                                          "orderModel": orderModel,
                                        });
                                  }
                                });
                              } else {
                                showTransactionDetails(
                                    context: context,
                                    walletTransactionModel:
                                        walletTransactionModel);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: ButtonThem.buildBorderButton(
                      context,
                      title: "withdraw".tr,
                      onPress: () async {
                        if (double.parse(controller
                                .driverUserModel.value.walletAmount
                                .toString()) <=
                            0) {
                          ShowToastDialog.showToast("Insufficient balance".tr);
                        } else {
                          ShowToastDialog.showLoader("Please wait".tr);
                          await FireStoreUtils.bankDetailsIsAvailable()
                              .then((value) {
                            ShowToastDialog.closeLoader();
                            if (value == true) {
                              withdrawAmountBottomSheet(context, controller);
                            } else {
                              ShowToastDialog.showToast(
                                  "Your bank details is not available.Please add bank details"
                                      .tr);
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: ButtonThem.buildButton(
                      context,
                      title: "Withdrawal history".tr,
                      onPress: () {
                        Get.to(const WithDrawHistoryScreen());
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  showTransactionDetails(
      {required BuildContext context,
      required WalletTransactionModel walletTransactionModel}) {
    return showModalBottomSheet(
        elevation: 5,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            final themeChange = Provider.of<DarkThemeProvider>(context);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        "Transaction Details".tr,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: themeChange.getThem()
                            ? AppColors.darkContainerBackground
                            : AppColors.containerBackground,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        border: Border.all(
                            color: themeChange.getThem()
                                ? AppColors.darkContainerBorder
                                : AppColors.containerBorder,
                            width: 0.5),
                        boxShadow: themeChange.getThem()
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 5,
                                  offset: const Offset(
                                      0, 4), // changes position of shadow
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Transaction ID".tr,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "#${walletTransactionModel.transactionId!.toUpperCase().tr}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: themeChange.getThem()
                            ? AppColors.darkContainerBackground
                            : AppColors.containerBackground,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        border: Border.all(
                            color: themeChange.getThem()
                                ? AppColors.darkContainerBorder
                                : AppColors.containerBorder,
                            width: 0.5),
                        boxShadow: themeChange.getThem()
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 5,
                                  offset: const Offset(
                                      0, 4), // changes position of shadow
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Payment Details".tr,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Row(
                                      children: [
                                        Opacity(
                                          opacity: 0.7,
                                          child: Text(
                                            "Pay Via".tr,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "wallet".tr,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Divider(),
                            ),
                            Row(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Date in UTC Format".tr,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Opacity(
                                        opacity: 0.7,
                                        child: Text(
                                          DateFormat('KK:mm:ss a, dd MMM yyyy')
                                              .format(walletTransactionModel
                                                  .createdDate!
                                                  .toDate())
                                              .toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                ),
              ),
            );
          });
        });
  }

  withdrawAmountBottomSheet(BuildContext context, WalletController controller) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        builder: (context) {
          final themeChange = Provider.of<DarkThemeProvider>(context);

          return StatefulBuilder(builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 25.0, bottom: 10),
                      child: Text(
                        "Withdraw".tr,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                        decoration: BoxDecoration(
                          color: themeChange.getThem()
                              ? AppColors.darkContainerBackground
                              : AppColors.containerBackground,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          border: Border.all(
                              color: themeChange.getThem()
                                  ? AppColors.darkContainerBorder
                                  : AppColors.containerBorder,
                              width: 0.5),
                          boxShadow: themeChange.getThem()
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(
                                        0, 2), // changes position of shadow
                                  ),
                                ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    controller.bankDetailsModel.value.bankName
                                        .toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.account_balance,
                                    size: 40,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                controller.bankDetailsModel.value.accountNumber
                                    .toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                controller.bankDetailsModel.value.holderName
                                    .toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                controller.bankDetailsModel.value.branchName
                                    .toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                controller
                                    .bankDetailsModel.value.otherInformation
                                    .toString(),
                                style: GoogleFonts.poppins(),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(
                      height: 20,
                    ),
                    RichText(
                      text: TextSpan(
                        text: "Amount to Withdraw".tr,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldThem.buildTextFiled(context,
                        hintText: 'Enter Amount'.tr,
                        controller: controller.withdrawalAmountController.value,
                        keyBoardType: TextInputType.number),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldThem.buildTextFiled(context,
                        hintText: 'Notes'.tr,
                        maxLine: 3,
                        controller: controller.noteController.value),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ButtonThem.buildButton(
                          context,
                          title: "Withdrawal".tr,
                          onPress: () async {
                            if (double.parse(controller
                                    .driverUserModel.value.walletAmount
                                    .toString()) <
                                double.parse(controller
                                    .withdrawalAmountController.value.text)) {
                              ShowToastDialog.showToast(
                                  "Insufficient balance".tr);
                            } else if (double.parse(
                                    Constant.minimumAmountToWithdrawal) >
                                double.parse(controller
                                    .withdrawalAmountController.value.text)) {
                              ShowToastDialog.showToast(
                                  "${"Withdraw amount must be greater or equal to".tr}${Constant.amountShow(amount: Constant.minimumAmountToWithdrawal.toString().tr)}");
                            } else {
                              ShowToastDialog.showLoader("Please wait".tr);
                              WithdrawModel withdrawModel = WithdrawModel();
                              withdrawModel.id = Constant.getUuid();
                              withdrawModel.userId =
                                  FireStoreUtils.getCurrentUid();
                              withdrawModel.paymentStatus = "pending";
                              withdrawModel.amount = controller
                                  .withdrawalAmountController.value.text;
                              withdrawModel.note =
                                  controller.noteController.value.text;
                              withdrawModel.createdDate = Timestamp.now();

                              await FireStoreUtils.updatedDriverWallet(
                                  amount:
                                      "-${controller.withdrawalAmountController.value.text}");

                              await FireStoreUtils.setWithdrawRequest(
                                      withdrawModel)
                                  .then((value) {
                                controller.getUser();
                                ShowToastDialog.closeLoader();
                                ShowToastDialog.showToast(
                                    "Request sent to admin".tr);
                                Get.back();
                              });
                            }
                          },
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  paymentMethodDialog(BuildContext context, WalletController controller) {
    return showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(30), topLeft: Radius.circular(30))),
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        builder: (context) {
          final themeChange = Provider.of<DarkThemeProvider>(context);

          return FractionallySizedBox(
            heightFactor: 0.9,
            child: StatefulBuilder(builder: (context, setState) {
              return Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: const Icon(Icons.arrow_back_ios)),
                            // Expanded(
                            //     child: Center(
                            //         child: Text(
                            //   "Topup Wallet".tr,
                            //   style: GoogleFonts.poppins(),
                            // ))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Add Topup Amount".tr,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                TextFieldThem.buildTextFiled(
                                  context,
                                  hintText: 'Enter Amount'.tr,
                                  keyBoardType: TextInputType.number,
                                  controller: controller.amountController.value,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9*]')),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    parcelImageWidget(context, controller),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "خطوات شحن المحفظة :",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                _buildSteps(
                                    "١- الإيداع  في احدى الحسابات التالية."),
                                _buildSteps(
                                    "٢-رفع  إشعار الإيداع وتسجيل البيانات المطلوبة."),
                                _buildSteps(
                                    "٣-الإنتظار حتى الانتهاء من المراجعة."),
                                _buildSteps("وأرقام الحسابات البنكية :"),
                                _buildSteps("حساب بنك الكريمي 3004591096"),
                                _buildSteps("حساب بنك القطيبي 435491446"),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ButtonThem.buildButton(context, title: "Topup".tr,
                          onPress: () {
                        print("🔥 EXPERT DEBUG: Topup button clicked!");
                        controller.setCharge();
                      }),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  _buildSteps(String text) {
    return Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w500));
  }

  parcelImageWidget(BuildContext context, WalletController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            Obx(() {
              if (controller.imagePrice.value != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: FileImage(
                                File(controller.imagePrice.value!.path)),
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                            controller.imagePrice.value = null;
                          },
                          child: const Icon(
                            Icons.remove_circle,
                            size: 30,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox();
              }
            }),
            Obx(() => controller.imagePrice.value == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: InkWell(
                      onTap: () {
                        _onCameraClick(context, controller);
                      },
                      child: Image.asset(
                        'assets/images/parcel_add_image.png',
                        height: 100,
                        width: 100,
                      ),
                    ),
                  )
                : const SizedBox()),
          ],
        ),
      ),
    );
  }

  _onCameraClick(BuildContext context, WalletController controller) {
    final action = CupertinoActionSheet(
      // message: Text(
      //   'Add your parcel image.'.tr,
      //   style: const TextStyle(fontSize: 15.0),
      // ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          onPressed: () async {
            Get.back();
            await ImagePicker()
                .pickImage(source: ImageSource.gallery)
                .then((value) {
              if (value != null) {
                controller.imagePrice.value = value;
              }
            });
          },
          child: Text('Choose image from gallery'.tr),
        ),
        CupertinoActionSheetAction(
          onPressed: () async {
            Get.back();
            var photo =
                await ImagePicker().pickImage(source: ImageSource.camera);
            if (photo != null) {
              controller.imagePrice.value = photo;
            }
          },
          child: Text('Take a picture'.tr),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Get.back();
        },
        child: Text('Cancel'.tr),
      ),
    );

    showCupertinoModalPopup(context: context, builder: (context) => action);
  }
}
