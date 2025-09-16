import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../constant/constant.dart';
import '../constant/send_notification.dart';
import '../model/cancellation_reason_model.dart';
import '../model/intercity_order_model.dart';
import '../model/order_model.dart';
import '../themes/app_colors.dart';
import '../widget/custom_dialog.dart';
import 'DarkThemeProvider.dart';
import 'fire_store_utils.dart';

class RideUtils {
  showCancelationBottomsheet(
    BuildContext context, {
    InterCityOrderModel? interCityOrderModel,
    OrderModel? orderModel,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context_) {
        return CustomDangerDialog(
          title: 'إلغاء الرحلة'.tr,
          desc: "متأكد أنك تريد إلغاء هذه الرحلة؟".tr,
          onPositivePressed: () async {
            // Handle positive action
            Navigator.of(context_).pop();
            // check if it's just a bid
            if(orderModel!=null && orderModel.status == Constant.ridePlaced){
              await FireStoreUtils.removeOrderBid(orderModel);
              return;

            }
            if(interCityOrderModel!=null && interCityOrderModel.status == Constant.ridePlaced){
              await FireStoreUtils.removeInterCityOrderBid(interCityOrderModel);
              return;
            }

            // show cancellation reason bottomsheet
            showModalBottomSheet(
              backgroundColor: Theme.of(context).colorScheme.background,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15)),
              ),
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              builder: (context1) {
                final themeChange = Provider.of<DarkThemeProvider>(context1);

                return FractionallySizedBox(
                  heightFactor: 0.75,
                  child: StatefulBuilder(
                    builder: (context1, setState) {
                      return Container(
                        constraints: BoxConstraints(
                          maxHeight: 90,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 10,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Why are you cancelling this trip?".tr,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  "Select a reason for cancellation from the list to help us improve your experience on the platform."
                                      .tr,
                                  style: GoogleFonts.poppins(),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                _cancellationList(context1, themeChange,
                                    orderModel: orderModel,
                                    interCityOrderModel: interCityOrderModel),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          onNegativePressed: () {
            // Handle negative action
            Navigator.of(context_).pop();
          },
          positiveText: "تأكيد".tr,
          negativeText: 'لا'.tr,
        );
      },
    );
  }

  Widget _cancellationList(
    BuildContext context,
    DarkThemeProvider themeChange, {
    InterCityOrderModel? interCityOrderModel,
    OrderModel? orderModel,
  }) {
    return FutureBuilder<List<CancellationReasonModel>>(
      future: FireStoreUtils.getCancellationReasons(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Constant.loader(context);
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Text(
                snapshot.error.toString(),
              );
            } else {
              List<CancellationReasonModel> reasons = snapshot.requireData;

              return ListView.builder(
                itemCount: reasons.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  CancellationReasonModel reasonModel = reasons[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: InkWell(
                      onTap: () {
                        if (orderModel != null) {
                          onConfirmCancellation(
                              context, orderModel, reasonModel);
                        } else if (interCityOrderModel != null) {
                          onConfirmInterCityCancellation(
                              context, interCityOrderModel, reasonModel);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                          border: Border.all(
                            color: AppColors.textFieldBorder,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  Constant.localizationName(
                                    reasonModel.name,
                                  ),
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                              Radio(
                                value: false,
                                groupValue: true,
                                activeColor: themeChange.getThem()
                                    ? AppColors.darkModePrimary
                                    : AppColors.primary,
                                onChanged: (value) {
                                  if (orderModel != null) {
                                    onConfirmCancellation(
                                        context, orderModel, reasonModel);
                                  } else if (interCityOrderModel != null) {
                                    onConfirmInterCityCancellation(context,
                                        interCityOrderModel, reasonModel);
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          default:
            return Text('Error'.tr);
        }
      },
    );
  }

  void onConfirmCancellation(BuildContext context, OrderModel orderModel,
      CancellationReasonModel cancellationReason) async {
    Navigator.pop(context);

    // current driverId
    final String? customerId = orderModel.userId;

    // update order
    List<dynamic> acceptDriverId = [];
    orderModel.status = Constant.rideCanceled;
    orderModel.acceptedDriverId = acceptDriverId;
    orderModel.driverId = '';
    orderModel.cancellationReasonId = cancellationReason.id!;
    orderModel.cancellationReason = Constant.localizationName(
      cancellationReason.name,
    );
    await FireStoreUtils.setOrder(orderModel);

    // send cancellation alert to user
    if (customerId != null && customerId.isNotEmpty) {
      await FireStoreUtils.getCustomer(customerId).then((value) async {
        if (value == null ||
            value.fcmToken == null ||
            value.fcmToken!.isEmpty) {
          return;
        }
        await SendNotification.sendOneNotification(
          token: value.fcmToken.toString(),
          title: 'Ride Canceled'.tr,
          body:
              'The driver has canceled the ride. No action is required from your end'.tr
                  .tr,
          payload: {},
        );
      });
    }
  }

  void onConfirmInterCityCancellation(
      BuildContext context,
      InterCityOrderModel orderModel,
      CancellationReasonModel cancellationReason) async {
    Navigator.pop(context);


    // current driverId
    final String? customerId = orderModel.userId;

    // update order
    List<dynamic> acceptDriverId = [];
    orderModel.status = Constant.rideCanceled;
    orderModel.acceptedDriverId = acceptDriverId;
    orderModel.driverId = '';
    orderModel.cancellationReasonId = cancellationReason.id!;
    orderModel.cancellationReason = Constant.localizationName(
      cancellationReason.name,
    );
    await FireStoreUtils.setInterCityOrder(orderModel);

    // send cancellation alert to user
    if (customerId != null && customerId.isNotEmpty) {
      await FireStoreUtils.getCustomer(customerId).then((value) async {
        if (value == null ||
            value.fcmToken == null ||
            value.fcmToken!.isEmpty) {
          return;
        }
        await SendNotification.sendOneNotification(
          token: value.fcmToken.toString(),
          title: 'Ride Canceled'.tr,
          body:
          'The driver has canceled the ride. No action is required from your end'.tr,
          payload: {},
        );
      });
    }
  }
}
