import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/model/intercity_order_model.dart';
import 'package:driver/model/order/driverId_accept_reject.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/intercity_screen/pacel_details_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../controller/home_controller.dart';
import '../../controller/home_intercity_controller.dart';
import '../../model/banner_model.dart';
import '../../themes/button_them.dart';
import '../../utils/ride_utils.dart';

class AcceptedIntercityOrders extends StatefulWidget {
  const AcceptedIntercityOrders({Key? key}) : super(key: key);

  @override
  State<AcceptedIntercityOrders> createState() =>
      _AcceptedIntercityOrdersState();
}

class _AcceptedIntercityOrdersState extends State<AcceptedIntercityOrders> {
  bool hasData = false;
  bool wasShowingOrder = false;
  bool navigatedAway = false;

  final PageController pageController = PageController();
  var bannerList = <OtherBannerModel>[];
  Timer? _timer;

  @override
  void initState() {
    getBanners();
    super.initState();
  }

  void startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (pageController.hasClients && bannerList.isNotEmpty) {
        int nextPage = pageController.page!.round() + 1;

        if (nextPage >= bannerList.length) {
          nextPage = 0;
        }

        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void getBanners() async {
    await FireStoreUtils.getBannerOrder().then((value) {
      if (!mounted) return;
      setState(() {
        bannerList = value;
      });
      if (mounted) startAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(CollectionName.ordersIntercity)
                      .where('acceptedDriverId',
                          arrayContains: FireStoreUtils.getCurrentUid())
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return Text('Something went wrong'.tr);
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Constant.loader(context);
                    }
                    hasData = snapshot.data!.docs.isEmpty;
                    log(hasData.toString());
                    log(wasShowingOrder.toString());
                    log(navigatedAway.toString());
                    // Removed navigation logic that was preventing the empty state message from being displayed.

                    List<InterCityOrderModel> filteredOrders = snapshot.data!.docs.map((doc) => InterCityOrderModel.fromJson(doc.data() as Map<String, dynamic>)).where((orderModel) {
                      // Filter out canceled and completed orders
                      if (orderModel.status == Constant.rideCanceled ||
                          orderModel.status == Constant.rideComplete) {
                        print("🚫 Filtering out order ${orderModel.id} - status: ${orderModel.status}");
                        return false;
                      }

                      // Filter out orders where another driver was selected
                      if (orderModel.driverId != null &&
                          orderModel.driverId!.isNotEmpty &&
                          orderModel.driverId != FireStoreUtils.getCurrentUid()) {
                        print("🚫 Filtering out order ${orderModel.id} - another driver selected: ${orderModel.driverId}");
                        return false;
                      }
                      print("✅ Showing accepted order ${orderModel.id} - status: ${orderModel.status}, driverId: ${orderModel.driverId}");
                      return true;
                    }).toList();

                    return filteredOrders.isEmpty
                        ? Center(
                            child: Text("لم يتم العثور على رحلة مقبولة".tr),
                          )
                        : ListView.builder(
                            itemCount: filteredOrders.length,
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              InterCityOrderModel orderModel = filteredOrders[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: themeChange.getThem()
                                            ? AppColors.darkContainerBackground
                                            : AppColors.containerBackground,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        border: Border.all(
                                            color: themeChange.getThem()
                                                ? AppColors.darkContainerBorder
                                                : AppColors.containerBorder,
                                            width: 0.5),
                                        boxShadow: themeChange.getThem()
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.5),
                                                  blurRadius: 8,
                                                  offset: const Offset(0,
                                                      2), // changes position of shadow
                                                ),
                                              ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 10),
                                        child: Column(
                                          children: [
                                            UserView(
                                              userId: orderModel.userId,
                                              amount: orderModel.offerRate,
                                              distance: orderModel.distance,
                                              distanceType:
                                                  orderModel.distanceType,
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                FutureBuilder<
                                                        DriverIdAcceptReject?>(
                                                    future: FireStoreUtils
                                                        .getInterCItyAcceptedOrders(
                                                            orderModel.id
                                                                .toString(),
                                                            FireStoreUtils
                                                                .getCurrentUid()),
                                                    builder:
                                                        (context, snapshot) {
                                                      switch (snapshot
                                                          .connectionState) {
                                                        case ConnectionState
                                                            .waiting:
                                                          return Constant
                                                              .loader(context);
                                                        case ConnectionState
                                                            .done:
                                                          if (snapshot
                                                              .hasError) {
                                                            return Text(snapshot
                                                                .error
                                                                .toString());
                                                          } else {
                                                            DriverIdAcceptReject
                                                                driverIdAcceptReject =
                                                                snapshot.data!;
                                                            return Row(
                                                              children: [
                                                                orderModel.intercityServiceId ==
                                                                        "647f350983ba2"
                                                                    ? const SizedBox()
                                                                    : Text(
                                                                        " ${"Person".tr} ${orderModel.numberOfPassenger} "
                                                                            .tr,
                                                                        style: GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize: 18)),
                                                                Text(
                                                                    "${"For".tr} ${Constant.amountShow(amount: driverIdAcceptReject.offerAmount.toString())}",
                                                                    style: GoogleFonts.poppins(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        fontSize:
                                                                            18)),
                                                              ],
                                                            );
                                                          }
                                                        default:
                                                          return Text(
                                                              'Error'.tr);
                                                      }
                                                    }),
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
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.30),
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            5))),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 4),
                                                          child: Text(orderModel
                                                                      .paymentType
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
                                                            color: AppColors
                                                                .primary
                                                                .withOpacity(
                                                                    0.30),
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            5))),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 4),
                                                          child: Text(Constant
                                                              .localizationName(
                                                                  orderModel
                                                                      .intercityService!
                                                                      .name)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Visibility(
                                                  visible: orderModel
                                                          .intercityServiceId ==
                                                      "647f350983ba2",
                                                  child: InkWell(
                                                      onTap: () {
                                                        Get.to(
                                                            const ParcelDetailsScreen(),
                                                            arguments: {
                                                              "orderModel":
                                                                  orderModel,
                                                            });
                                                      },
                                                      child: Text(
                                                        "View details".tr,
                                                        style: GoogleFonts
                                                            .poppins(),
                                                      )),
                                                )
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            LocationView(
                                              sourceLocation: orderModel
                                                  .sourceLocationName
                                                  .toString(),
                                              destinationLocation: orderModel
                                                  .destinationLocationName
                                                  .toString(),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            // cancel button
                                            ButtonThem.buildBorderButton(
                                              context,
                                              color: Colors.red,
                                              title: "Cancel".tr,
                                              btnHeight: 44,
                                              onPress: () => RideUtils()
                                                  .showCancelationBottomsheet(
                                                context,
                                                interCityOrderModel: orderModel,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (index == snapshot.data!.docs.length - 1)
                                      _buildBanner(context),
                                  ],
                                ),
                              );
                            });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Visibility(
      visible: bannerList.isNotEmpty,
      child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.2,
          child: PageView.builder(
              padEnds: true,
              allowImplicitScrolling: true,
              itemCount: bannerList.length,
              scrollDirection: Axis.horizontal,
              controller: pageController,
              itemBuilder: (context, index) {
                OtherBannerModel bannerModel = bannerList[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: CachedNetworkImage(
                    imageUrl: bannerModel.image.toString(),
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                            image: imageProvider, fit: BoxFit.cover),
                      ),
                    ),
                    color: Colors.black.withOpacity(0.5),
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    fit: BoxFit.cover,
                  ),
                );
              })),
    );
  }
}
