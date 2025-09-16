import 'dart:developer';

import 'package:bottom_picker/bottom_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/intercity_controller.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/model/place_picker_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/ui/intercity_screen/pacel_details_screen.dart';
import 'package:driver/widget/osm_map_search_place.dart'
    hide GoogleMapSearchPlacesApi;
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/google_map_search_place.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NewOrderInterCityScreen extends StatelessWidget {
  const NewOrderInterCityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<IntercityController>(
        init: IntercityController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: AppColors.primary,
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                SizedBox(
                  height: Responsive.width(8, context),
                  width: Responsive.width(100, context),
                ),
                Expanded(
                  child: Container(
                    height: Responsive.height(100, context),
                    width: Responsive.width(100, context),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25))),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () async {
                                  Get.to(const GoogleMapSearchPlacesApi())
                                      ?.then((value) {
                                    if (value != null) {
                                      PlaceDetailsModel placeDetailsModel =
                                          value;
                                      controller
                                              .sourceCityController.value.text =
                                          placeDetailsModel.result!.vicinity
                                              .toString();
                                    }
                                  });
                                },
                                child: TextFieldThem.buildTextFiled(
                                  context,
                                  hintText: 'From'.tr,
                                  controller:
                                      controller.sourceCityController.value,
                                  enable: false,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // اختيار المدينة الوجهة (To) - Google Map فقط
                              InkWell(
                                onTap: () async {
                                  Get.to(const GoogleMapSearchPlacesApi())
                                      ?.then((value) {
                                    if (value != null) {
                                      PlaceDetailsModel placeDetailsModel =
                                          value;
                                      controller.destinationCityController.value
                                              .text =
                                          placeDetailsModel.result!.vicinity
                                              .toString();
                                    }
                                  });
                                },
                                child: TextFieldThem.buildTextFiled(
                                  context,
                                  hintText: 'To'.tr,
                                  controller: controller
                                      .destinationCityController.value,
                                  enable: false,
                                ),
                              ),

                              const SizedBox(
                                height: 10,
                              ),
                              InkWell(
                                  onTap: () async {
                                    BottomPicker.date(
                                      onSubmit: (index) {
                                        controller.dateAndTime = index;
                                        DateFormat dateFormat =
                                            DateFormat("EEE, dd MMMM");
                                        String string =
                                            dateFormat.format(index);

                                        controller.whenController.value.text =
                                            string;
                                      },
                                      minDateTime: DateTime.now(),
                                      buttonAlignment: MainAxisAlignment.center,
                                      displaySubmitButton: true,
                                      buttonSingleColor: AppColors.primary,
                                      pickerTitle: const Text(''),
                                    ).show(context);
                                  },
                                  child: TextFieldThem
                                      .buildTextFiledWithSuffixIcon(
                                    context,
                                    hintText: 'Select date'.tr,
                                    controller: controller.whenController.value,
                                    enable: false,
                                    suffixIcon: const Icon(
                                      Icons.calendar_month,
                                      color: Colors.grey,
                                    ),
                                  )),
                              const SizedBox(
                                height: 10,
                              ),
                              ButtonThem.buildButton(
                                context,
                                title: "Search".tr,
                                onPress: controller.isLoading.value
                                    ? () {}
                                    : () {
                                        controller.getOrder();
                                      },
                              ),
                              const SizedBox(height: 10),
                              _buildOrderList(context, controller, themeChange),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  _buildOrderList(BuildContext context, IntercityController controller,
      DarkThemeProvider themeChange) {
    return controller.isLoading.value
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Constant.loader(context),
          )
        : controller.intercityServiceOrder.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text("No Rides found".tr),
                ),
              )
            : ListView.builder(
                itemCount: controller.intercityServiceOrder.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  InterCityOrderModel orderModel =
                      controller.intercityServiceOrder[index];
                  String amount;
                  if (Constant.distanceType == "Km") {
                    amount = Constant.amountCalculate(
                            orderModel.intercityService!.kmCharge.toString(),
                            orderModel.distance.toString())
                        .toStringAsFixed(
                            Constant.currencyModel!.decimalDigits!);
                  } else {
                    amount = Constant.amountCalculate(
                            orderModel.intercityService!.kmCharge.toString(),
                            orderModel.distance.toString())
                        .toStringAsFixed(
                            Constant.currencyModel!.decimalDigits!);
                  }
                  return InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeChange.getThem()
                              ? AppColors.darkContainerBackground
                              : AppColors.containerBackground,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
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
                                      0,
                                      2,
                                    ),
                                  ),
                                ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          child: Column(
                            children: [
                              UserView(
                                userId: orderModel.userId,
                                amount: orderModel.offerRate,
                                distance: orderModel.distance,
                                distanceType: orderModel.distanceType,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  (orderModel.intercityServiceId ==
                                              "647f350983ba2" ||
                                          orderModel.intercityServiceId ==
                                              "Kn2VEnPI3ikF58uK8YqY")
                                      ? const SizedBox()
                                      : Text(
                                          "${"Person".tr} ${orderModel.numberOfPassenger} "
                                              .tr,
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                  Text(
                                      "${"For".tr} ${Constant.amountShow(amount: orderModel.offerRate.toString())} ",
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18)),
                                ],
                              ),

                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.grey.withOpacity(0.30),
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(5),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            child: Text(orderModel.paymentType
                                                        .toString() ==
                                                    "Wallet"
                                                ? "wallet".tr
                                                : "Cash".tr),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.30),
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(5),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            child: Text(
                                              Constant.localizationName(
                                                orderModel
                                                    .intercityService!.name,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Visibility(
                                    visible: orderModel.intercityServiceId ==
                                        "647f350983ba2",
                                    child: InkWell(
                                        onTap: () {
                                          Get.to(const ParcelDetailsScreen(),
                                              arguments: {
                                                "orderModel": orderModel,
                                              });
                                        },
                                        child: Text(
                                          "View details".tr,
                                          style: GoogleFonts.poppins(),
                                        )),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              if ((orderModel.comments ?? '').trim().isNotEmpty)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.sticky_note_2_outlined,
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        (orderModel.comments ?? '')
                                            .toString()
                                            .tr,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if ((orderModel.numberOfPassenger ?? '')
                                  .trim()
                                  .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.people, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        (orderModel.numberOfPassenger ?? '')
                                            .trim(),
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(
                                height: 10,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: themeChange.getThem()
                                        ? AppColors.darkGray
                                        : AppColors.gray,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Arabic label for date and time
                                          Text(
                                            'الموعد والتاريخ',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Date and time in the same row
                                          Row(
                                            children: [
                                              // Date with calendar icon
                                              const Icon(Icons.calendar_month,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Builder(
                                                builder: (_) {
                                                  String raw = orderModel
                                                          .whenDates
                                                          ?.toString() ??
                                                      '';
                                                  String formatted = raw;
                                                  DateTime? dt;
                                                  // Try ISO parse first
                                                  try {
                                                    dt = DateTime.tryParse(raw);
                                                  } catch (_) {}
                                                  // Build variants to improve parsing robustness (handle dashes and lowercase months)
                                                  final variants = <String>{
                                                    raw,
                                                    raw.replaceAll('-', ' '),
                                                    raw.replaceAll('-', '/'),
                                                  };
                                                  if (raw.isNotEmpty) {
                                                    final capFirst =
                                                        raw[0].toUpperCase() +
                                                            raw.substring(1);
                                                    variants.add(capFirst);
                                                    variants.add(capFirst
                                                        .replaceAll('-', ' '));
                                                    variants.add(capFirst
                                                        .replaceAll('-', '/'));
                                                  }
                                                  // Common patterns we might receive
                                                  final patterns = <String>[
                                                    'EEE, dd MMMM',
                                                    'dd/MM/yyyy',
                                                    'MM/dd/yyyy',
                                                    'yyyy-MM-dd',
                                                    'dd MMM yyyy',
                                                    'd MMM yyyy',
                                                    'MMM-dd-yyyy',
                                                    'dd-MMM-yyyy',
                                                    'd-MMM-yyyy',
                                                    'MMM yyyy dd',
                                                    'MMM-yyyy-dd',
                                                    'yyyy-MMM-dd',
                                                    'MMM d, yyyy',
                                                  ];
                                                  if (dt == null) {
                                                    'use intl'
                                                        .toString(); // no-op to avoid empty block lint
                                                    bool found = false;
                                                    for (final v in variants) {
                                                      for (final p
                                                          in patterns) {
                                                        try {
                                                          dt = DateFormat(p)
                                                              .parse(v);
                                                          found = true;
                                                          break;
                                                        } catch (_) {}
                                                      }
                                                      if (found) break;
                                                    }
                                                  }
                                                  if (dt != null) {
                                                    formatted =
                                                        DateFormat('dd/MM/yyyy')
                                                            .format(dt!);
                                                  }
                                                  return Text(
                                                    formatted,
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 20),
                                              // Time with clock icon
                                              const Icon(Icons.access_time,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                orderModel.whenTime.toString(),
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )),
                                ),
                              ),
                              LocationView(
                                sourceLocation:
                                    orderModel.sourceLocationName.toString(),
                                destinationLocation: orderModel
                                    .destinationLocationName
                                    .toString(),
                              ),
                              Column(
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: Container(
                                      width: Responsive.width(100, context),
                                      decoration: BoxDecoration(
                                        color: themeChange.getThem()
                                            ? AppColors.darkGray
                                            : AppColors.gray,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
                                        child: Center(
                                          child: Builder(
                                            builder: (_) {
                                              String dur = orderModel.duration
                                                  .toString();
                                              String unit =
                                                  orderModel.distanceType ?? '';
                                              if (Get.locale?.languageCode ==
                                                  'ar') {
                                                // Try to parse hours and minutes and rebuild Arabic phrase
                                                final String raw = orderModel
                                                    .duration
                                                    .toString();
                                                int? h;
                                                int? m;
                                                final hMatch = RegExp(
                                                        r'(\d+)\s*(h|hr|hrs|hour|hours)',
                                                        caseSensitive: false)
                                                    .firstMatch(raw);
                                                if (hMatch != null) {
                                                  h = int.tryParse(
                                                      hMatch.group(1)!);
                                                }
                                                final mMatch = RegExp(
                                                        r'(\d+)\s*(m|min|mins|minute|minutes)\.?',
                                                        caseSensitive: false)
                                                    .firstMatch(raw);
                                                if (mMatch != null) {
                                                  m = int.tryParse(
                                                      mMatch.group(1)!);
                                                }
                                                if (h != null || m != null) {
                                                  final parts = <String>[];
                                                  if (h != null && h > 0)
                                                    parts.add('$h ساعة');
                                                  if (m != null && m > 0)
                                                    parts.add('$m دقيقة');
                                                  if (parts.isNotEmpty) {
                                                    dur = parts.join(' ');
                                                  }
                                                } else {
                                                  // Fallback simple replacement
                                                  dur = raw
                                                      .replaceAll(
                                                          RegExp(
                                                              r'\\bhours?\\b',
                                                              caseSensitive:
                                                                  false),
                                                          'ساعة')
                                                      .replaceAll(
                                                          RegExp(
                                                              r'min(?:ute)?s?\\.?',
                                                              caseSensitive:
                                                                  false),
                                                          'دقيقة');
                                                }
                                                if (unit.toLowerCase() == 'km')
                                                  unit = 'كم';
                                                if (unit.toLowerCase() ==
                                                    'miles') unit = 'ميل';
                                              }
                                              final dist = double.parse(
                                                      orderModel.distance
                                                          .toString())
                                                  .toStringAsFixed(Constant
                                                      .currencyModel!
                                                      .decimalDigits!);
                                              return Text(
                                                '${'Approx time'.tr} $dur. ${"Approx distanc".tr} $dist $unit',
                                                // ${"Recommended Price is".tr} ${Constant.amountShow(amount: amount.toString())}.
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),

                              // bid button

                              ButtonThem.buildButton(
                                context,
                                title: "addOffer".tr,
                                customColor: AppColors.darkModePrimary,
                                onPress: () {
                                  if (orderModel.acceptedDriverId != null &&
                                      orderModel.acceptedDriverId!.contains(
                                          FireStoreUtils.getCurrentUid())) {
                                    ShowToastDialog.showToast(
                                        "Ride already accepted".tr);
                                  } else {
                                    controller.newAmount.value =
                                        orderModel.offerRate.toString();
                                    controller.enterOfferRateController.value
                                        .text = orderModel.offerRate.toString();
                                    DateTime start = DateFormat("HH:mm")
                                        .parse(orderModel.whenTime.toString());
                                    controller.suggestedTime = start;
                                    controller.suggestedTimeController.value
                                            .text =
                                        DateFormat("hh:mm aa")
                                            .format(controller.suggestedTime!);
                                    offerAcceptDialog(
                                        context, controller, orderModel);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
  }

  offerAcceptDialog(BuildContext context, IntercityController controller,
      InterCityOrderModel orderModel) {
    return showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    topLeft: Radius.circular(15))),
            child: StatefulBuilder(builder: (context, setState) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
                child: Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UserView(
                          userId: orderModel.userId,
                          amount: orderModel.offerRate,
                          distance: orderModel.distance,
                          distanceType: orderModel.distanceType,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 5),
                          child: Divider(),
                        ),
                        LocationView(
                          sourceLocation:
                              orderModel.sourceLocationName.toString(),
                          destinationLocation:
                              orderModel.destinationLocationName.toString(),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Visibility(
                          visible:
                              orderModel.intercityService!.offerRate == true,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (double.parse(
                                            controller.newAmount.value) >=
                                        10) {
                                      controller
                                          .newAmount.value = (double.parse(
                                                  controller.newAmount.value) -
                                              10)
                                          .toString();

                                      controller.enterOfferRateController.value
                                          .text = controller.newAmount.value;
                                    } else {
                                      controller.newAmount.value = "0";
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.textFieldBorder),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(30))),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 10),
                                      child: Text(
                                        "- 10",
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Text(
                                    Constant.amountShow(
                                        amount:
                                            controller.newAmount.toString()),
                                    style: GoogleFonts.poppins()),
                                const SizedBox(
                                  width: 20,
                                ),
                                ButtonThem.roundButton(
                                  context,
                                  title: "+ 10",
                                  btnWidthRatio: 0.22,
                                  onPress: () {
                                    controller.newAmount.value = (double.parse(
                                                controller.newAmount.value) +
                                            10)
                                        .toStringAsFixed(Constant
                                            .currencyModel!.decimalDigits!);
                                    controller.enterOfferRateController.value
                                        .text = controller.newAmount.value;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Visibility(
                          visible:
                              orderModel.intercityService!.offerRate == true,
                          child: TextFieldThem.buildTextFiledWithPrefixIcon(
                            context,
                            hintText: "Enter Fare rate".tr,
                            controller:
                                controller.enterOfferRateController.value,
                            keyBoardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: false),
                            onChanged: (value) {
                              if (value.isEmpty) {
                                controller.newAmount.value = "0.0";
                              } else {
                                controller.newAmount.value = value;
                              }
                            },
                            prefix: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                  Constant.currencyModel!.symbol.toString()),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        InkWell(
                            onTap: () {
                              BottomPicker.time(
                                onSubmit: (index) {
                                  controller.suggestedTime = index;
                                  DateFormat dateFormat =
                                      DateFormat("hh:mm aa");
                                  String string = dateFormat.format(index);

                                  controller.suggestedTimeController.value
                                      .text = string;
                                },
                                initialTime: Time.now(),
                                buttonAlignment: MainAxisAlignment.center,
                                pickerTitle: const Text(''),
                                displaySubmitButton: true,
                                buttonSingleColor: AppColors.darkModePrimary,
                              ).show(context);
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.access_time),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: TextFieldThem.buildTextFiled(
                                    context,
                                    enable: false,
                                    hintText: "Enter Fare rate".tr,
                                    controller: controller
                                        .suggestedTimeController.value,
                                    keyBoardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true, signed: false),
                                  ),
                                )
                              ],
                            )),
                        const SizedBox(
                          height: 10,
                        ),
                        ButtonThem.buildButton(
                          context,
                          title:
                              "${"Accept fare on".tr} ${Constant.amountShow(amount: controller.newAmount.value)}"
                                  .tr,
                          onPress: () async {
                            String amount;
                            if (Constant.distanceType == "Km") {
                              amount = Constant.amountCalculate(
                                      orderModel.intercityService!.kmCharge
                                          .toString(),
                                      orderModel.distance.toString())
                                  .toStringAsFixed(
                                      Constant.currencyModel!.decimalDigits!);
                            } else {
                              amount = Constant.amountCalculate(
                                      orderModel.intercityService!.kmCharge
                                          .toString(),
                                      orderModel.distance.toString())
                                  .toStringAsFixed(
                                      Constant.currencyModel!.decimalDigits!);
                            }
                            double offerAmount = Constant.getAmountShow(
                                amount: controller.newAmount.value);
                            // double suggestAmount =
                            //     Constant.getAmountShow(amount: amount);
                            // double halfPrice = suggestAmount / 2;
                            // double minPrice = suggestAmount - halfPrice;
                            // double maxPrice = suggestAmount + halfPrice;

                            if (offerAmount < 1000) {
                              ShowToastDialog.showToast("priceOffer".tr);
                              return;
                            }

                            // check if order not canceled yet
                            ShowToastDialog.showLoader("Please wait".tr);
                            await controller.getSelectedOrder(orderModel.id!);
                            ShowToastDialog.closeLoader();
                            if (controller
                                        .selectedIntercityServiceOrder.value !=
                                    null &&
                                controller.selectedIntercityServiceOrder.value!
                                        .status !=
                                    null &&
                                controller.selectedIntercityServiceOrder.value!
                                        .status ==
                                    Constant.rideCanceled) {
                              ShowToastDialog.showToast(
                                  "Ride has been canceled".tr);
                              Get.back();
                              return;
                            }
                            if (double.parse(controller
                                    .driverModel.value.walletAmount
                                    .toString()) >=
                                double.parse(
                                    Constant.minimumDepositToRideAccept)) {
                              ShowToastDialog.showLoader("Please wait".tr);
                              List<dynamic> newAcceptedDriverId = [];
                              if (orderModel.acceptedDriverId != null) {
                                newAcceptedDriverId =
                                    orderModel.acceptedDriverId!;
                              } else {
                                newAcceptedDriverId = [];
                              }
                              newAcceptedDriverId
                                  .add(FireStoreUtils.getCurrentUid());
                              orderModel.acceptedDriverId = newAcceptedDriverId;
                              await FireStoreUtils.setInterCityOrder(
                                  orderModel);

                              DriverIdAcceptReject driverIdAcceptReject =
                                  DriverIdAcceptReject(
                                      driverId: FireStoreUtils.getCurrentUid(),
                                      acceptedRejectTime: Timestamp.now(),
                                      offerAmount: controller.newAmount.value,
                                      suggestedDate: orderModel.whenDates,
                                      suggestedTime: DateFormat("HH:mm")
                                          .format(controller.suggestedTime!));
                              await FireStoreUtils.getCustomer(
                                      orderModel.userId.toString())
                                  .then((value) async {
                                if (value != null) {
                                  await SendNotification.sendOneNotification(
                                      token: value.fcmToken.toString(),
                                      title: 'New Bids'.tr,
                                      body: 'Driver requested your ride.'.tr,
                                      payload: {});
                                }
                              });

                              await FireStoreUtils.acceptInterCityRide(
                                      orderModel, driverIdAcceptReject)
                                  .then((value) {
                                ShowToastDialog.closeLoader();
                                ShowToastDialog.showToast("Ride Accepted".tr);
                                Get.back();
                                controller.homeController.selectedIndex.value =
                                    1;
                              });
                            } else {
                              ShowToastDialog.showToast(
                                  "${"You have to minimum".tr} ${Constant.amountShow(amount: Constant.minimumDepositToRideAccept)} ${"wallet amount to Accept Order and place a bid".tr}"
                                      .tr);
                            }
                          },
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        });
  }
}
