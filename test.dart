// import 'dart:async';
// import 'dart:developer';
// import 'dart:math' as math;

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:customer/constant/collection_name.dart';
// import 'package:customer/constant/constant.dart';
// import 'package:customer/constant/show_toast_dialog.dart';
// import 'package:customer/controller/dash_board_controller.dart';
// import 'package:customer/controller/home_controller.dart';
// import 'package:customer/controller/timer_controller.dart';
// import 'package:customer/model/driver_user_model.dart';
// import 'package:customer/model/order_model.dart';
// import 'package:customer/model/sos_model.dart';
// import 'package:customer/model/user_model.dart';
// import 'package:customer/themes/app_colors.dart';
// import 'package:customer/themes/button_them.dart';
// import 'package:customer/themes/responsive.dart';
// import 'package:customer/ui/chat_screen/chat_screen.dart';
// import 'package:customer/ui/chat_screen/inbox_screen.dart';
// import 'package:customer/ui/contact_us/contact_us_screen.dart';
// import 'package:customer/ui/faq/faq_screen.dart';
// import 'package:customer/ui/home_screens/home_screen.dart';
// import 'package:customer/ui/hold_timer/hold_timer_screen.dart';
// import 'package:customer/ui/interCity/interCity_screen.dart';
// import 'package:customer/ui/intercityOrders/intercity_order_screen.dart';
// import 'package:customer/ui/orders/complete_order_screen.dart';
// import 'package:customer/ui/orders/live_tracking_screen.dart';
// import 'package:customer/ui/orders/order_details_screen.dart';
// import 'package:customer/ui/orders/payment_order_screen.dart';
// import 'package:customer/ui/profile_screen/profile_screen.dart';
// import 'package:customer/ui/referral_screen/referral_screen.dart';
// import 'package:customer/ui/review/review_screen.dart';
// import 'package:customer/ui/settings_screen/setting_screen.dart';
// import 'package:customer/ui/wallet/wallet_screen.dart';
// import 'package:customer/utils/DarkThemeProvider.dart';
// import 'package:customer/utils/fire_store_utils.dart';
// import 'package:customer/utils/utils.dart';
// import 'package:customer/widget/driver_view.dart';
// import 'package:customer/widget/location_view.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../model/banner_model.dart';
// import '../../model/referral_model.dart';
// import '../../utils/ride_utils.dart';
// import '../auth_screen/login_screen.dart';
// import '../home_screens/ride_details_screen.dart';
// import '../dashboard_screen.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class OrderScreen extends StatefulWidget {
//   final bool showDrawer;
//   final int initialTabIndex;

//   const OrderScreen(
//       {super.key, this.showDrawer = true, this.initialTabIndex = 0});

//   @override
//   State<OrderScreen> createState() => _OrderScreenState();
// }

// class _OrderScreenState extends State<OrderScreen> {
//   final PageController pageController = PageController();
//   var bannerList = <OtherBannerModel>[];
//   Timer? _timer;
//   final Map<String, Widget> _mapWidgetCache = {};
//   Timer? _cacheCleanupTimer;
//   DateTime? _lastMapCreation;

//   // Drawer functionality
//   RxInt selectedDrawerIndex = 2.obs; // Set to 2 since we're on Rides
//   RxList<dynamic> drawerItems = [
//     {'title': 'City'.tr, 'icon': "assets/icons/ic_city.svg"},
//     {'title': 'OutStation'.tr, 'icon': "assets/icons/ic_intercity.svg"},
//     {'title': 'Rides'.tr, 'icon': "assets/icons/ic_order.svg"},
//     {'title': 'OutStation Rides'.tr, 'icon': "assets/icons/ic_order.svg"},
//     {'title': 'My Wallet'.tr, 'icon': "assets/icons/ic_wallet.svg"},
//     {'title': 'Settings'.tr, 'icon': "assets/icons/ic_settings.svg"},
//     {'title': 'Referral a friends'.tr, 'icon': "assets/icons/ic_referral.svg"},
//     {'title': 'Inbox'.tr, 'icon': "assets/icons/ic_inbox.svg"},
//     {'title': 'Profile'.tr, 'icon': "assets/icons/ic_profile.svg"},
//     {'title': 'Contact us'.tr, 'icon': "assets/icons/ic_contact_us.svg"},
//     {'title': 'FAQs'.tr, 'icon': "assets/icons/ic_faq.svg"},
//     {'title': 'Log out'.tr, 'icon': "assets/icons/ic_logout.svg"},
//   ].obs;

//   @override
//   void initState() {
//     getBanners();
//     super.initState();
//   }

//   void startAutoScroll() {
//     _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       try {
//         if (pageController.hasClients && bannerList.isNotEmpty && mounted) {
//           // Check if pageController is still valid and has only one attached PageView
//           if (!pageController.hasClients ||
//               pageController.positions.length != 1) return;

//           // Safely get the current page with null check
//           final currentPage = pageController.page;
//           if (currentPage == null) return;

//           int nextPage = currentPage.round() + 1;
//           if (nextPage >= bannerList.length) {
//             nextPage = 0;
//           }
//           pageController.animateToPage(
//             nextPage,
//             duration: const Duration(milliseconds: 500),
//             curve: Curves.easeInOut,
//           );
//         }
//       } catch (e) {
//         print('Banner auto-scroll error: $e');
//         _timer?.cancel();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     try {
//       _timer?.cancel();
//       _cacheCleanupTimer?.cancel();
//       _mapWidgetCache.clear();
//       _lastMapCreation = null;
//       if (pageController.hasClients) {
//         pageController.dispose();
//       }
//     } catch (e) {
//       print('OrderScreen dispose error: $e');
//     }
//     super.dispose();
//   }

//   void getBanners() async {
//     await FireStoreUtils.getBannerOrder().then((value) {
//       if (mounted) {
//         setState(() {
//           bannerList = value;
//         });
//         startAutoScroll();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     return Scaffold(
//       backgroundColor: AppColors.primary,
//       drawer: widget.showDrawer ? buildAppDrawer(context) : null,
//       appBar: widget.showDrawer
//           ? AppBar(
//               backgroundColor: AppColors.primary,
//               elevation: 0,
//               leading: Builder(
//                 builder: (context) {
//                   return StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection(CollectionName.orders)
//                         .where("userId",
//                             isEqualTo: FireStoreUtils.getCurrentUid())
//                         .where("status", whereIn: [
//                           Constant.ridePlaced,
//                           Constant.rideInProgress,
//                           Constant.rideActive,
//                           Constant.rideHoldAccepted,
//                           Constant.rideHold,
//                         ])
//                         .where("paymentStatus", isEqualTo: false)
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       // Show drawer icon only when there are no active rides
//                       bool shouldShowDrawer = true;

//                       if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
//                         // Hide drawer when there are any active rides
//                         shouldShowDrawer = false;

//                         print(
//                             '🔍 Drawer Icon Debug: hasActiveRides=true, shouldShowDrawer=$shouldShowDrawer, activeRidesCount=${snapshot.data!.docs.length}');
//                       }

//                       return shouldShowDrawer
//                           ? InkWell(
//                               onTap: () {
//                                 Scaffold.of(context).openDrawer();
//                               },
//                               child: Padding(
//                                 padding: const EdgeInsets.only(
//                                     left: 10, right: 20, top: 20, bottom: 20),
//                                 child: SvgPicture.asset(
//                                     'assets/icons/ic_humber.svg'),
//                               ),
//                             )
//                           : const SizedBox.shrink(); // Hide drawer icon
//                     },
//                   );
//                 },
//               ),
//               title: Text(
//                 "Rides".tr,
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               centerTitle: true,
//             )
//           : null,
//       body: Column(
//         children: [
//           if (widget.showDrawer)
//             Container(
//               height: Responsive.width(10, context),
//               width: Responsive.width(100, context),
//               color: AppColors.primary,
//             ),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.surface,
//                   borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(25),
//                       topRight: Radius.circular(25))),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 10),
//                   child: DefaultTabController(
//                     length: 3,
//                     initialIndex: widget.initialTabIndex,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TabBar(
//                           indicatorColor: AppColors.darkModePrimary,
//                           tabs: [
//                             Tab(
//                                 child: Text(
//                               "Active Rides".tr,
//                               textAlign: TextAlign.center,
//                               style: GoogleFonts.poppins(),
//                             )),
//                             Tab(
//                                 child: Text(
//                               "Completed Rides".tr,
//                               textAlign: TextAlign.center,
//                               style: GoogleFonts.poppins(),
//                             )),
//                             Tab(
//                                 child: Text(
//                               "Canceled Rides".tr,
//                               textAlign: TextAlign.center,
//                               style: GoogleFonts.poppins(),
//                             )),
//                           ],
//                         ),
//                         Expanded(
//                           child: TabBarView(
//                             physics:
//                                 const ClampingScrollPhysics(), // Prevent interference with PageView
//                             children: [
//                               StreamBuilder<QuerySnapshot>(
//                                 stream: FirebaseFirestore.instance
//                                     .collection(CollectionName.orders)
//                                     .where("userId",
//                                         isEqualTo:
//                                             FireStoreUtils.getCurrentUid())
//                                     .where("status", whereIn: [
//                                       Constant.ridePlaced,
//                                       Constant.rideInProgress,
//                                       Constant.rideComplete,
//                                       Constant.rideActive,
//                                       Constant.rideHoldAccepted,
//                                       Constant.rideHold,
//                                     ])
//                                     .where("paymentStatus", isEqualTo: false)
//                                     .orderBy("createdDate", descending: true)
//                                     .snapshots(),
//                                 builder: (BuildContext context,
//                                     AsyncSnapshot<QuerySnapshot> snapshot) {
//                                   if (snapshot.hasError) {
//                                     return Center(
//                                         child: Text('Something went wrong'.tr));
//                                   }
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return Constant.loader();
//                                   }

//                                   // Add a small delay to prevent rapid rebuilds
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.active) {
//                                     // Ensure we have stable data before rebuilding
//                                     if (snapshot.data == null) {
//                                       return Constant.loader();
//                                     }
//                                   }

//                                   return snapshot.data!.docs.isEmpty
//                                       ? Center(
//                                           child:
//                                               Text("No active rides found".tr),
//                                         )
//                                       : SingleChildScrollView(
//                                           key: ValueKey(
//                                               'active_rides_${snapshot.data!.docs.length}'),
//                                           child: Column(
//                                             children: List.generate(
//                                               snapshot.data!.docs.length,
//                                               (index) {
//                                                 OrderModel orderModel =
//                                                     OrderModel.fromJson(snapshot
//                                                             .data!.docs[index]
//                                                             .data()
//                                                         as Map<String,
//                                                             dynamic>);

//                                                 Widget? mapWidget;
//                                                 final srcLat = orderModel
//                                                     .sourceLocationLAtLng
//                                                     ?.latitude;
//                                                 final srcLng = orderModel
//                                                     .sourceLocationLAtLng
//                                                     ?.longitude;
//                                                 final dstLat = orderModel
//                                                     .destinationLocationLAtLng
//                                                     ?.latitude;
//                                                 final dstLng = orderModel
//                                                     .destinationLocationLAtLng
//                                                     ?.longitude;

//                                                 // Progressive map logic based on ride status
//                                                 bool hasDriver =
//                                                     orderModel.driverId !=
//                                                             null &&
//                                                         orderModel.driverId!
//                                                             .isNotEmpty;
//                                                 bool isRideActive =
//                                                     orderModel.status ==
//                                                         Constant.rideActive;
//                                                 bool isRideInProgress =
//                                                     orderModel.status ==
//                                                         Constant.rideInProgress;

//                                                 // Check if driver has actually picked up the passenger
//                                                 // If ride is active but driver hasn't reached pickup yet, treat as in progress
//                                                 bool driverHasPickedUp = false;
//                                                 if (isRideActive && hasDriver) {
//                                                   // You might need to add a field to track if pickup is completed
//                                                   // For now, we'll assume if status is rideActive, driver has picked up
//                                                   driverHasPickedUp = true;
//                                                 }

//                                                 print(
//                                                     '🔍 Ride Status Analysis: status=${orderModel.status}, isRideActive=$isRideActive, isRideInProgress=$isRideInProgress, driverHasPickedUp=$driverHasPickedUp');

//                                                 print(
//                                                     '🔍 Order Debug: status=${orderModel.status}, isRideActive=$isRideActive, isRideInProgress=$isRideInProgress, hasDriver=$hasDriver');
//                                                 bool isDriverAccepted =
//                                                     orderModel.status ==
//                                                             Constant
//                                                                 .ridePlaced &&
//                                                         hasDriver;

//                                                 if (srcLat == null ||
//                                                     srcLng == null) {
//                                                   print(
//                                                       '🔍 Error: Source coordinates missing for order ${orderModel.id}');
//                                                   return SizedBox(
//                                                     height: Responsive.height(
//                                                         28, context),
//                                                     child: Center(
//                                                         child: Text(
//                                                             'Invalid source location'
//                                                                 .tr)),
//                                                   );
//                                                 }

//                                                 if (isRideActive &&
//                                                     (dstLat == null ||
//                                                         dstLng == null)) {
//                                                   print(
//                                                       '🔍 Error: Destination coordinates missing for order ${orderModel.id} in rideActive');
//                                                   return SizedBox(
//                                                     height: Responsive.height(
//                                                         28, context),
//                                                     child: Center(
//                                                         child: Text(
//                                                             'Invalid destination location'
//                                                                 .tr)),
//                                                   );
//                                                 }

//                                                 print(
//                                                     '🔍 Order Debug: status=${orderModel.status}, isRideActive=$isRideActive, isRideInProgress=$isRideInProgress, hasDriver=$hasDriver, srcLat=$srcLat, srcLng=$srcLng, dstLat=$dstLat, dstLng=$dstLng, driverId=${orderModel.driverId}');
//                                                 print(
//                                                     '📍 Pickup Location: LatLng($srcLat, $srcLng)');
//                                                 print(
//                                                     '📍 Dropoff Location: LatLng($dstLat, $dstLng)');

//                                                 if (hasDriver) {
//                                                   // Use a FutureBuilder to fetch driver location and rotation
//                                                   mapWidget = FutureBuilder<
//                                                       DriverUserModel?>(
//                                                     future: FireStoreUtils
//                                                         .getDriver(orderModel
//                                                             .driverId!),
//                                                     builder: (context,
//                                                         driverSnapshot) {
//                                                       if (driverSnapshot
//                                                               .connectionState ==
//                                                           ConnectionState
//                                                               .waiting) {
//                                                         return SizedBox(
//                                                           height:
//                                                               Responsive.height(
//                                                                   28, context),
//                                                           child: Center(
//                                                               child:
//                                                                   CircularProgressIndicator()),
//                                                         );
//                                                       }
//                                                       if (!driverSnapshot
//                                                               .hasData ||
//                                                           driverSnapshot.data ==
//                                                               null ||
//                                                           driverSnapshot
//                                                               .hasError) {
//                                                         // fallback to pickup location map
//                                                         return SizedBox(
//                                                           height:
//                                                               Responsive.height(
//                                                                   28, context),
//                                                           width:
//                                                               double.infinity,
//                                                           child:
//                                                               _createCachedMapWidget(
//                                                             cacheKey:
//                                                                 'no_driver_${orderModel.id}',
//                                                             source: LatLng(
//                                                                 srcLat, srcLng),
//                                                             showRoute: false,
//                                                           ),
//                                                         );
//                                                       }
//                                                       final driver =
//                                                           driverSnapshot.data!;
//                                                       final driverLoc =
//                                                           driver.location;
//                                                       print(
//                                                           '🚗 Driver Location: LatLng(${driverLoc?.latitude}, ${driverLoc?.longitude})');
//                                                       if (driverLoc == null) {
//                                                         // fallback to pickup location map
//                                                         return SizedBox(
//                                                           height:
//                                                               Responsive.height(
//                                                                   28, context),
//                                                           width:
//                                                               double.infinity,
//                                                           child:
//                                                               _createCachedMapWidget(
//                                                             cacheKey:
//                                                                 'pickup_fallback_${orderModel.id}',
//                                                             source: LatLng(
//                                                                 srcLat, srcLng),
//                                                             showRoute: false,
//                                                           ),
//                                                         );
//                                                       }
//                                                       // Determine if driver should go to pickup or dropoff
//                                                       bool shouldGoToPickup =
//                                                           isRideActive; // Driver accepted, heading to pickup
//                                                       bool shouldGoToDropoff =
//                                                           isRideInProgress; // Ride started, heading to dropoff

//                                                       final calculatedDestination =
//                                                           shouldGoToPickup
//                                                               ? LatLng(srcLat,
//                                                                   srcLng) // Route to pickup
//                                                               : (shouldGoToDropoff &&
//                                                                       dstLat !=
//                                                                           null &&
//                                                                       dstLng !=
//                                                                           null
//                                                                   ? LatLng(
//                                                                       dstLat,
//                                                                       dstLng) // Route to dropoff
//                                                                   : null);

//                                                       print(
//                                                           '🎯 Route Decision: shouldGoToPickup=$shouldGoToPickup, shouldGoToDropoff=$shouldGoToDropoff');

//                                                       print(
//                                                           '🔍 RouteMapWidget Debug: isRideActive=$isRideActive, isRideInProgress=$isRideInProgress, isDriverAccepted=$isDriverAccepted');
//                                                       print(
//                                                           '🎯 Calculated Destination: $calculatedDestination');
//                                                       print(
//                                                           '📍 Expected Route: ${shouldGoToPickup ? "Driver → Pickup" : "Driver → Dropoff"}');
//                                                       return SizedBox(
//                                                         height:
//                                                             Responsive.height(
//                                                                 28, context),
//                                                         child:
//                                                             _createCachedMapWidget(
//                                                           cacheKey:
//                                                               'live_tracking_${orderModel.id}',
//                                                           source: LatLng(
//                                                               srcLat, srcLng),
//                                                           destination:
//                                                               calculatedDestination,
//                                                           driverLocation: LatLng(
//                                                               driverLoc
//                                                                   .latitude!,
//                                                               driverLoc
//                                                                   .longitude!),
//                                                           carRotation:
//                                                               driver.rotation ??
//                                                                   0.0,
//                                                           showLiveTracking:
//                                                               isRideActive ||
//                                                                   isRideInProgress,
//                                                           showRoute:
//                                                               isDriverAccepted ||
//                                                                   isRideInProgress ||
//                                                                   isRideActive,
//                                                         ),
//                                                       );
//                                                     },
//                                                   );
//                                                 } else {
//                                                   // No driver yet - show pickup location with animated marker
//                                                   mapWidget = Padding(
//                                                     padding: const EdgeInsets
//                                                         .symmetric(
//                                                         vertical: 10),
//                                                     child: SizedBox(
//                                                       height: Responsive.height(
//                                                           28, context),
//                                                       width: double.infinity,
//                                                       child:
//                                                           _createCachedMapWidget(
//                                                         cacheKey:
//                                                             'no_driver_${orderModel.id}',
//                                                         source: LatLng(
//                                                             srcLat, srcLng),
//                                                         showRoute: false,
//                                                         showLiveTracking: false,
//                                                       ),
//                                                     ),
//                                                   );
//                                                 }

//                                                 return Column(
//                                                   children: [
//                                                     mapWidget, // Map always at the top
//                                                     InkWell(
//                                                       child: Padding(
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .all(10),
//                                                         child: Container(
//                                                           decoration:
//                                                               BoxDecoration(
//                                                             color: themeChange
//                                                                     .getThem()
//                                                                 ? AppColors
//                                                                     .darkContainerBackground
//                                                                 : AppColors
//                                                                     .containerBackground,
//                                                             borderRadius:
//                                                                 const BorderRadius
//                                                                     .all(Radius
//                                                                         .circular(
//                                                                             10)),
//                                                             border: Border.all(
//                                                                 color: themeChange
//                                                                         .getThem()
//                                                                     ? AppColors
//                                                                         .darkContainerBorder
//                                                                     : AppColors
//                                                                         .containerBorder,
//                                                                 width: 0.5),
//                                                             boxShadow:
//                                                                 themeChange
//                                                                         .getThem()
//                                                                     ? null
//                                                                     : [
//                                                                         BoxShadow(
//                                                                           color: Colors
//                                                                               .black
//                                                                               .withOpacity(0.10),
//                                                                           blurRadius:
//                                                                               5,
//                                                                           offset: const Offset(
//                                                                               0,
//                                                                               4), // changes position of shadow
//                                                                         ),
//                                                                       ],
//                                                           ),
//                                                           child: Padding(
//                                                             padding:
//                                                                 const EdgeInsets
//                                                                     .all(12.0),
//                                                             child: Column(
//                                                               crossAxisAlignment:
//                                                                   CrossAxisAlignment
//                                                                       .start,
//                                                               children: [
//                                                                 orderModel.status ==
//                                                                             Constant
//                                                                                 .rideComplete ||
//                                                                         orderModel.status ==
//                                                                             Constant.rideActive
//                                                                     ? const SizedBox()
//                                                                     : Row(
//                                                                         children: [
//                                                                           Expanded(
//                                                                             child:
//                                                                                 Text(
//                                                                               orderModel.status.toString().tr,
//                                                                               style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
//                                                                             ),
//                                                                           ),
//                                                                           Text(
//                                                                             orderModel.status == Constant.ridePlaced
//                                                                                 ? Constant.amountShow(amount: (orderModel.offerRate == null || orderModel.offerRate.toString() == 'null' || orderModel.offerRate.toString().isEmpty) ? '0.0' : double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!))
//                                                                                 : Constant.amountShow(amount: (orderModel.finalRate == null || orderModel.finalRate.toString() == 'null' || orderModel.finalRate.toString().isEmpty) ? '0.0' : double.parse(orderModel.finalRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)),
//                                                                             style:
//                                                                                 GoogleFonts.poppins(fontWeight: FontWeight.bold),
//                                                                           ),
//                                                                         ],
//                                                                       ),
//                                                                 orderModel.status ==
//                                                                             Constant
//                                                                                 .rideComplete ||
//                                                                         orderModel.status ==
//                                                                             Constant.rideActive
//                                                                     ? Padding(
//                                                                         padding: const EdgeInsets
//                                                                             .symmetric(
//                                                                             vertical:
//                                                                                 10),
//                                                                         child:
//                                                                             DriverView(
//                                                                           driverId: orderModel
//                                                                               .driverId
//                                                                               .toString(),
//                                                                           amount: orderModel.status == Constant.ridePlaced
//                                                                               ? (orderModel.offerRate == null || orderModel.offerRate.toString() == 'null' || orderModel.offerRate.toString().isEmpty ? '0.0' : double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!))
//                                                                               : (orderModel.finalRate == null || orderModel.finalRate.toString() == 'null' || orderModel.finalRate.toString().isEmpty ? '0.0' : double.parse(orderModel.finalRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)),
//                                                                         ),
//                                                                       )
//                                                                     : Container(),
//                                                                 const SizedBox(
//                                                                   height: 10,
//                                                                 ),
//                                                                 LocationView(
//                                                                   sourceLocation:
//                                                                       orderModel
//                                                                           .sourceLocationName
//                                                                           .toString(),
//                                                                   destinationLocation:
//                                                                       orderModel
//                                                                           .destinationLocationName
//                                                                           .toString(),
//                                                                 ),
//                                                                 const SizedBox(
//                                                                   height: 5,
//                                                                 ),
//                                                                 orderModel.someOneElse !=
//                                                                         null
//                                                                     ? Container(
//                                                                         decoration: BoxDecoration(
//                                                                             color: themeChange.getThem()
//                                                                                 ? AppColors.darkGray
//                                                                                 : AppColors.gray,
//                                                                             borderRadius: const BorderRadius.all(Radius.circular(10))),
//                                                                         child: Padding(
//                                                                             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//                                                                             child: Row(
//                                                                               mainAxisAlignment: MainAxisAlignment.center,
//                                                                               crossAxisAlignment: CrossAxisAlignment.center,
//                                                                               children: [
//                                                                                 Expanded(
//                                                                                   child: Row(
//                                                                                     children: [
//                                                                                       Text(orderModel.someOneElse!.fullName.toString().tr, style: GoogleFonts.poppins()),
//                                                                                       Text(orderModel.someOneElse!.contactNumber.toString().tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
//                                                                                     ],
//                                                                                   ),
//                                                                                 ),
//                                                                                 InkWell(
//                                                                                     onTap: () async {
//                                                                                       await Share.share(
//                                                                                         subject: 'Ride Booked'.tr,
//                                                                                         "${'The verification code is'.tr}: ${orderModel.otp}",
//                                                                                       );
//                                                                                     },
//                                                                                     child: const Icon(Icons.share))
//                                                                               ],
//                                                                             )),
//                                                                       )
//                                                                     : const SizedBox(),
//                                                                 if (orderModel
//                                                                             .acceptHoldTime !=
//                                                                         null &&
//                                                                     orderModel
//                                                                             .status ==
//                                                                         Constant
//                                                                             .rideHoldAccepted)
//                                                                   HoldTimerWidget(
//                                                                     acceptHoldTime:
//                                                                         orderModel
//                                                                             .acceptHoldTime!,
//                                                                     holdingMinuteCharge: orderModel
//                                                                         .service!
//                                                                         .holdingMinuteCharge
//                                                                         .toString(),
//                                                                     holdingMinute: orderModel
//                                                                         .service!
//                                                                         .holdingMinute
//                                                                         .toString(),
//                                                                     orderId:
//                                                                         orderModel
//                                                                             .id!,
//                                                                     orderModel:
//                                                                         orderModel,
//                                                                   ),
//                                                                 Padding(
//                                                                   padding: const EdgeInsets
//                                                                       .symmetric(
//                                                                       vertical:
//                                                                           10),
//                                                                   child:
//                                                                       Container(
//                                                                     decoration: BoxDecoration(
//                                                                         color: themeChange.getThem()
//                                                                             ? AppColors
//                                                                                 .darkGray
//                                                                             : AppColors
//                                                                                 .gray,
//                                                                         borderRadius: const BorderRadius
//                                                                             .all(
//                                                                             Radius.circular(10))),
//                                                                     child: Padding(
//                                                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//                                                                         child: Row(
//                                                                           mainAxisAlignment:
//                                                                               MainAxisAlignment.center,
//                                                                           crossAxisAlignment:
//                                                                               CrossAxisAlignment.center,
//                                                                           children: [
//                                                                             Expanded(
//                                                                               child: orderModel.status == Constant.rideInProgress || orderModel.status == Constant.ridePlaced || orderModel.status == Constant.rideComplete
//                                                                                   ? Text(orderModel.status.toString().tr)
//                                                                                   : Row(
//                                                                                       children: [
//                                                                                         Text("OTP".tr, style: GoogleFonts.poppins()),
//                                                                                         Text(" : ${orderModel.otp}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
//                                                                                       ],
//                                                                                     ),
//                                                                             ),
//                                                                             Text(Constant().formatTimestamp(orderModel.createdDate),
//                                                                                 style: GoogleFonts.poppins(fontSize: 12)),
//                                                                           ],
//                                                                         )),
//                                                                   ),
//                                                                 ),
//                                                                 Visibility(
//                                                                     visible: orderModel
//                                                                             .status ==
//                                                                         Constant
//                                                                             .ridePlaced,
//                                                                     child: ButtonThem
//                                                                         .buildButton(
//                                                                       context,
//                                                                       title:
//                                                                           "${"View bids".tr} (${orderModel.acceptedDriverId != null ? orderModel.acceptedDriverId!.length.toString() : "0"})"
//                                                                               .tr,
//                                                                       btnHeight:
//                                                                           44,
//                                                                       onPress:
//                                                                           () async {
//                                                                         Get.to(
//                                                                             const OrderDetailsScreen(),
//                                                                             arguments: {
//                                                                               "orderModel": orderModel,
//                                                                             });
//                                                                         // paymentMethodDialog(context, controller, orderModel);
//                                                                       },
//                                                                     )),
//                                                                 const SizedBox(
//                                                                     height: 10),
//                                                                 // loader
//                                                                 Visibility(
//                                                                   visible: orderModel
//                                                                           .status ==
//                                                                       Constant
//                                                                           .ridePlaced,
//                                                                   child:
//                                                                       LinearProgressIndicator(),
//                                                                 ),
//                                                                 Visibility(
//                                                                     visible: orderModel.status == Constant.rideInProgress ||
//                                                                         orderModel.status ==
//                                                                             Constant
//                                                                                 .rideHold ||
//                                                                         orderModel.status ==
//                                                                             Constant
//                                                                                 .rideHoldAccepted,
//                                                                     child: ButtonThem
//                                                                         .buildButton(
//                                                                       context,
//                                                                       title: "SOS"
//                                                                           .tr,
//                                                                       btnHeight:
//                                                                           44,
//                                                                       onPress:
//                                                                           () async {
//                                                                         await FireStoreUtils.getSOS(orderModel.id.toString())
//                                                                             .then((value) {
//                                                                           if (value !=
//                                                                               null) {
//                                                                             ShowToastDialog.showToast("Your request is".tr);
//                                                                           } else {
//                                                                             SosModel
//                                                                                 sosModel =
//                                                                                 SosModel();
//                                                                             sosModel.id =
//                                                                                 Constant.getUuid();
//                                                                             sosModel.orderId =
//                                                                                 orderModel.id;
//                                                                             sosModel.status =
//                                                                                 "Initiated";
//                                                                             sosModel.orderType =
//                                                                                 "city";
//                                                                             FireStoreUtils.setSOS(sosModel);
//                                                                           }
//                                                                         });
//                                                                       },
//                                                                     )),
//                                                                 const SizedBox(
//                                                                     height: 10),
//                                                                 Visibility(
//                                                                     visible: orderModel
//                                                                                 .status !=
//                                                                             Constant
//                                                                                 .ridePlaced &&
//                                                                         orderModel.driverId !=
//                                                                             null &&
//                                                                         orderModel
//                                                                             .driverId!
//                                                                             .isNotEmpty,
//                                                                     child: Row(
//                                                                       children: [
//                                                                         Expanded(
//                                                                           child:
//                                                                               InkWell(
//                                                                             onTap:
//                                                                                 () async {
//                                                                               UserModel? customer = await FireStoreUtils.getUserProfile(orderModel.userId.toString());
//                                                                               DriverUserModel? driver = await FireStoreUtils.getDriver(orderModel.driverId.toString());

//                                                                               Get.to(ChatScreens(
//                                                                                 driverId: driver!.id,
//                                                                                 customerId: customer!.id,
//                                                                                 customerName: customer.fullName,
//                                                                                 customerProfileImage: customer.profilePic,
//                                                                                 driverName: driver.fullName,
//                                                                                 driverProfileImage: driver.profilePic,
//                                                                                 orderId: orderModel.id,
//                                                                                 token: driver.fcmToken,
//                                                                               ));
//                                                                             },
//                                                                             child:
//                                                                                 Container(
//                                                                               height: 44,
//                                                                               decoration: BoxDecoration(color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary, borderRadius: BorderRadius.circular(5)),
//                                                                               child: Icon(Icons.chat, color: themeChange.getThem() ? Colors.black : Colors.white),
//                                                                             ),
//                                                                           ),
//                                                                         ),
//                                                                         const SizedBox(
//                                                                           width:
//                                                                               10,
//                                                                         ),
//                                                                         Expanded(
//                                                                           child:
//                                                                               InkWell(
//                                                                             onTap:
//                                                                                 () async {
//                                                                               if (orderModel.status == Constant.rideActive) {
//                                                                                 DriverUserModel? driver = await FireStoreUtils.getDriver(orderModel.driverId.toString());
//                                                                                 Constant.makePhoneCall("${driver!.countryCode}${driver.phoneNumber}");
//                                                                               } else {
//                                                                                 String phone = await FireStoreUtils.getEmergencyPhoneNumber();
//                                                                                 Constant.makePhoneCall(phone);
//                                                                               }
//                                                                             },
//                                                                             child:
//                                                                                 Container(
//                                                                               height: 44,
//                                                                               decoration: BoxDecoration(color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary, borderRadius: BorderRadius.circular(5)),
//                                                                               child: Icon(Icons.call, color: themeChange.getThem() ? Colors.black : Colors.white),
//                                                                             ),
//                                                                           ),
//                                                                         ),
//                                                                         const SizedBox(
//                                                                           width:
//                                                                               10,
//                                                                         ),
//                                                                         Expanded(
//                                                                           child:
//                                                                               InkWell(
//                                                                             onTap:
//                                                                                 () async {
//                                                                               // Navigate to LiveTrackingScreen with order data
//                                                                               Get.to(
//                                                                                 const LiveTrackingScreen(),
//                                                                                 arguments: {
//                                                                                   "orderModel": orderModel,
//                                                                                   "type": "orderModel",
//                                                                                 },
//                                                                               );
//                                                                             },
//                                                                             child:
//                                                                                 Container(
//                                                                               height: 44,
//                                                                               decoration: BoxDecoration(color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary, borderRadius: BorderRadius.circular(5)),
//                                                                               child: Icon(Icons.map, color: themeChange.getThem() ? Colors.black : Colors.white),
//                                                                             ),
//                                                                           ),
//                                                                         ),
//                                                                       ],
//                                                                     )),
//                                                                 const SizedBox(
//                                                                     height: 10),
//                                                                 Visibility(
//                                                                     visible: orderModel.status == Constant.rideInProgress ||
//                                                                         orderModel.status ==
//                                                                             Constant
//                                                                                 .rideHold ||
//                                                                         orderModel.status ==
//                                                                             Constant
//                                                                                 .rideHoldAccepted,
//                                                                     child: ButtonThem
//                                                                         .buildButton(
//                                                                       context,
//                                                                       title:
//                                                                           "whatsapp"
//                                                                               .tr,
//                                                                       btnHeight:
//                                                                           44,
//                                                                       onPress:
//                                                                           () async {
//                                                                         var phone =
//                                                                             await FireStoreUtils.getWhatsAppNumber();
//                                                                         String
//                                                                             message =
//                                                                             "wdniWhatsapp".tr;
//                                                                         final Uri
//                                                                             whatsappUrl =
//                                                                             Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
//                                                                         try {
//                                                                           await launchUrl(
//                                                                             whatsappUrl,
//                                                                             mode:
//                                                                                 LaunchMode.externalApplication,
//                                                                           );
//                                                                         } catch (e) {
//                                                                           log("Error: ${e.toString()}");
//                                                                           ShowToastDialog.showToast(
//                                                                               "Could not launch".tr);
//                                                                         }
//                                                                       },
//                                                                     )),
//                                                                 orderModel.status ==
//                                                                         Constant
//                                                                             .rideInProgress
//                                                                     ? const SizedBox(
//                                                                         height:
//                                                                             10,
//                                                                       )
//                                                                     : SizedBox
//                                                                         .shrink(),
//                                                                 Visibility(
//                                                                     visible: orderModel.status ==
//                                                                             Constant
//                                                                                 .rideComplete &&
//                                                                         (orderModel.paymentStatus ==
//                                                                                 null ||
//                                                                             orderModel.paymentStatus ==
//                                                                                 false),
//                                                                     child: ButtonThem
//                                                                         .buildButton(
//                                                                       context,
//                                                                       title: "Pay"
//                                                                           .tr,
//                                                                       btnHeight:
//                                                                           44,
//                                                                       onPress:
//                                                                           () async {
//                                                                         Get.to(
//                                                                             const PaymentOrderScreen(),
//                                                                             arguments: {
//                                                                               "orderModel": orderModel,
//                                                                             });
//                                                                         // paymentMethodDialog(context, controller, orderModel);
//                                                                       },
//                                                                     )),

//                                                                 // cancel button
//                                                                 Visibility(
//                                                                   visible: orderModel
//                                                                               .status ==
//                                                                           Constant
//                                                                               .ridePlaced ||
//                                                                       orderModel
//                                                                               .status ==
//                                                                           Constant
//                                                                               .rideActive,
//                                                                   child: ButtonThem
//                                                                       .buildBorderButton(
//                                                                     context,
//                                                                     title:
//                                                                         "Cancel"
//                                                                             .tr,
//                                                                     color: Colors
//                                                                         .red,
//                                                                     btnHeight:
//                                                                         44,
//                                                                     onPress: () =>
//                                                                         RideUtils()
//                                                                             .showCancelationBottomsheet(
//                                                                       context,
//                                                                       orderModel:
//                                                                           orderModel,
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                         );
//                                 },
//                               ),
//                               StreamBuilder<QuerySnapshot>(
//                                 stream: FirebaseFirestore.instance
//                                     .collection(CollectionName.orders)
//                                     .where("userId",
//                                         isEqualTo:
//                                             FireStoreUtils.getCurrentUid())
//                                     .where("status",
//                                         isEqualTo: Constant.rideComplete)
//                                     .where("paymentStatus", isEqualTo: true)
//                                     .orderBy("createdDate", descending: true)
//                                     .snapshots(),
//                                 builder: (BuildContext context,
//                                     AsyncSnapshot<QuerySnapshot> snapshot) {
//                                   if (snapshot.hasError) {
//                                     return Center(
//                                         child: Text('Something went wrong'.tr));
//                                   }
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return Constant.loader();
//                                   }
//                                   return snapshot.data!.docs.isEmpty
//                                       ? Center(
//                                           child: Text(
//                                               "No completed rides found".tr),
//                                         )
//                                       : ListView.builder(
//                                           itemCount: snapshot.data!.docs.length,
//                                           scrollDirection: Axis.vertical,
//                                           shrinkWrap: true,
//                                           itemBuilder: (context, index) {
//                                             OrderModel orderModel =
//                                                 OrderModel.fromJson(snapshot
//                                                         .data!.docs[index]
//                                                         .data()
//                                                     as Map<String, dynamic>);
//                                             return Padding(
//                                               padding: const EdgeInsets.all(10),
//                                               child: Container(
//                                                 decoration: BoxDecoration(
//                                                   color: themeChange.getThem()
//                                                       ? AppColors
//                                                           .darkContainerBackground
//                                                       : AppColors
//                                                           .containerBackground,
//                                                   borderRadius:
//                                                       const BorderRadius.all(
//                                                           Radius.circular(10)),
//                                                   border: Border.all(
//                                                       color: themeChange
//                                                               .getThem()
//                                                           ? AppColors
//                                                               .darkContainerBorder
//                                                           : AppColors
//                                                               .containerBorder,
//                                                       width: 0.5),
//                                                   boxShadow: themeChange
//                                                           .getThem()
//                                                       ? null
//                                                       : [
//                                                           BoxShadow(
//                                                             color: Colors.black
//                                                                 .withOpacity(
//                                                                     0.10),
//                                                             blurRadius: 5,
//                                                             offset: const Offset(
//                                                                 0,
//                                                                 4), // changes position of shadow
//                                                           ),
//                                                         ],
//                                                 ),
//                                                 child: InkWell(
//                                                     onTap: () {
//                                                       Get.to(
//                                                           const CompleteOrderScreen(),
//                                                           arguments: {
//                                                             "orderModel":
//                                                                 orderModel,
//                                                           });
//                                                     },
//                                                     child: Padding(
//                                                       padding:
//                                                           const EdgeInsets.all(
//                                                               12.0),
//                                                       child: Column(
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .start,
//                                                         children: [
//                                                           DriverView(
//                                                             driverId: orderModel
//                                                                 .driverId
//                                                                 .toString(),
//                                                             amount: orderModel
//                                                                         .status ==
//                                                                     Constant
//                                                                         .ridePlaced
//                                                                 ? (orderModel.offerRate == null ||
//                                                                         orderModel.offerRate.toString() ==
//                                                                             'null' ||
//                                                                         orderModel
//                                                                             .offerRate
//                                                                             .toString()
//                                                                             .isEmpty
//                                                                     ? '0.0'
//                                                                     : double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant
//                                                                         .currencyModel!
//                                                                         .decimalDigits!))
//                                                                 : (orderModel.finalRate == null ||
//                                                                         orderModel.finalRate.toString() ==
//                                                                             'null' ||
//                                                                         orderModel
//                                                                             .finalRate
//                                                                             .toString()
//                                                                             .isEmpty
//                                                                     ? '0.0'
//                                                                     : double.parse(orderModel.finalRate.toString())
//                                                                         .toStringAsFixed(Constant.currencyModel!.decimalDigits!)),
//                                                           ),
//                                                           const Padding(
//                                                             padding: EdgeInsets
//                                                                 .symmetric(
//                                                                     vertical:
//                                                                         4),
//                                                             child: Divider(
//                                                               thickness: 1,
//                                                             ),
//                                                           ),
//                                                           LocationView(
//                                                             sourceLocation:
//                                                                 orderModel
//                                                                     .sourceLocationName
//                                                                     .toString(),
//                                                             destinationLocation:
//                                                                 orderModel
//                                                                     .destinationLocationName
//                                                                     .toString(),
//                                                           ),
//                                                           Padding(
//                                                             padding:
//                                                                 const EdgeInsets
//                                                                     .symmetric(
//                                                                     vertical:
//                                                                         14),
//                                                             child: Container(
//                                                               decoration: BoxDecoration(
//                                                                   color: themeChange.getThem()
//                                                                       ? AppColors
//                                                                           .darkGray
//                                                                       : AppColors
//                                                                           .gray,
//                                                                   borderRadius:
//                                                                       const BorderRadius
//                                                                           .all(
//                                                                           Radius.circular(
//                                                                               10))),
//                                                               child: Padding(
//                                                                   padding: const EdgeInsets
//                                                                       .symmetric(
//                                                                       horizontal:
//                                                                           10,
//                                                                       vertical:
//                                                                           12),
//                                                                   child: Center(
//                                                                     child: Row(
//                                                                       children: [
//                                                                         Expanded(
//                                                                             child:
//                                                                                 Text(orderModel.status.toString().tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
//                                                                         Text(
//                                                                             Constant().formatTimestamp(orderModel
//                                                                                 .createdDate),
//                                                                             style:
//                                                                                 GoogleFonts.poppins()),
//                                                                       ],
//                                                                     ),
//                                                                   )),
//                                                             ),
//                                                           ),
//                                                           Row(
//                                                             children: [
//                                                               Expanded(
//                                                                   child: ButtonThem
//                                                                       .buildButton(
//                                                                 context,
//                                                                 title:
//                                                                     "Review".tr,
//                                                                 btnHeight: 44,
//                                                                 onPress:
//                                                                     () async {
//                                                                   Get.to(
//                                                                       const ReviewScreen(),
//                                                                       arguments: {
//                                                                         "type":
//                                                                             "orderModel",
//                                                                         "orderModel":
//                                                                             orderModel,
//                                                                       });
//                                                                 },
//                                                               )),
//                                                             ],
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     )),
//                                               ),
//                                             );
//                                           });
//                                 },
//                               ),
//                               StreamBuilder<QuerySnapshot>(
//                                 stream: FirebaseFirestore.instance
//                                     .collection(CollectionName.orders)
//                                     .where("userId",
//                                         isEqualTo:
//                                             FireStoreUtils.getCurrentUid())
//                                     .where("status",
//                                         isEqualTo: Constant.rideCanceled)
//                                     .orderBy("createdDate", descending: true)
//                                     .snapshots(),
//                                 builder: (BuildContext context,
//                                     AsyncSnapshot<QuerySnapshot> snapshot) {
//                                   if (snapshot.hasError) {
//                                     return Center(
//                                         child: Text('Something went wrong'.tr));
//                                   }
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return Constant.loader();
//                                   }
//                                   return snapshot.data!.docs.isEmpty
//                                       ? Center(
//                                           child: Text(
//                                               "No completed rides found".tr),
//                                         )
//                                       : ListView.builder(
//                                           itemCount: snapshot.data!.docs.length,
//                                           scrollDirection: Axis.vertical,
//                                           shrinkWrap: true,
//                                           itemBuilder: (context, index) {
//                                             OrderModel orderModel =
//                                                 OrderModel.fromJson(snapshot
//                                                         .data!.docs[index]
//                                                         .data()
//                                                     as Map<String, dynamic>);
//                                             return Padding(
//                                               padding: const EdgeInsets.all(10),
//                                               child: Container(
//                                                 decoration: BoxDecoration(
//                                                   color: themeChange.getThem()
//                                                       ? AppColors
//                                                           .darkContainerBackground
//                                                       : AppColors
//                                                           .containerBackground,
//                                                   borderRadius:
//                                                       const BorderRadius.all(
//                                                           Radius.circular(10)),
//                                                   border: Border.all(
//                                                       color: themeChange
//                                                               .getThem()
//                                                           ? AppColors
//                                                               .darkContainerBorder
//                                                           : AppColors
//                                                               .containerBorder,
//                                                       width: 0.5),
//                                                   boxShadow: themeChange
//                                                           .getThem()
//                                                       ? null
//                                                       : [
//                                                           BoxShadow(
//                                                             color: Colors.black
//                                                                 .withOpacity(
//                                                                     0.10),
//                                                             blurRadius: 5,
//                                                             offset: const Offset(
//                                                                 0,
//                                                                 4), // changes position of shadow
//                                                           ),
//                                                         ],
//                                                 ),
//                                                 child: Padding(
//                                                   padding: const EdgeInsets.all(
//                                                       12.0),
//                                                   child: Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment
//                                                             .start,
//                                                     children: [
//                                                       orderModel.status ==
//                                                                   Constant
//                                                                       .rideComplete ||
//                                                               orderModel
//                                                                       .status ==
//                                                                   Constant
//                                                                       .rideActive
//                                                           ? const SizedBox()
//                                                           : Row(
//                                                               children: [
//                                                                 Expanded(
//                                                                   child: Text(
//                                                                     orderModel
//                                                                         .status
//                                                                         .toString()
//                                                                         .tr,
//                                                                     style: GoogleFonts.poppins(
//                                                                         fontWeight:
//                                                                             FontWeight.w500),
//                                                                   ),
//                                                                 ),
//                                                                 Text(
//                                                                   Constant.amountShow(
//                                                                       amount: (orderModel.offerRate == null ||
//                                                                               orderModel.offerRate.toString() == 'null' ||
//                                                                               orderModel.offerRate.toString().isEmpty
//                                                                           ? '0.0'
//                                                                           : double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!))),
//                                                                   style: GoogleFonts.poppins(
//                                                                       fontWeight:
//                                                                           FontWeight
//                                                                               .bold),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                       const SizedBox(
//                                                         height: 10,
//                                                       ),
//                                                       LocationView(
//                                                         sourceLocation: orderModel
//                                                             .sourceLocationName
//                                                             .toString(),
//                                                         destinationLocation:
//                                                             orderModel
//                                                                 .destinationLocationName
//                                                                 .toString(),
//                                                       ),
//                                                       Padding(
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .symmetric(
//                                                                 vertical: 14),
//                                                         child: Container(
//                                                           decoration: BoxDecoration(
//                                                               color: themeChange
//                                                                       .getThem()
//                                                                   ? AppColors
//                                                                       .darkGray
//                                                                   : AppColors
//                                                                       .gray,
//                                                               borderRadius:
//                                                                   const BorderRadius
//                                                                       .all(
//                                                                       Radius.circular(
//                                                                           10))),
//                                                           child: Padding(
//                                                               padding:
//                                                                   const EdgeInsets
//                                                                       .symmetric(
//                                                                       horizontal:
//                                                                           10,
//                                                                       vertical:
//                                                                           10),
//                                                               child: Row(
//                                                                 mainAxisAlignment:
//                                                                     MainAxisAlignment
//                                                                         .center,
//                                                                 crossAxisAlignment:
//                                                                     CrossAxisAlignment
//                                                                         .center,
//                                                                 children: [
//                                                                   Expanded(
//                                                                       child: Text(orderModel
//                                                                           .status
//                                                                           .toString()
//                                                                           .tr)),
//                                                                   Text(
//                                                                       Constant().formatTimestamp(
//                                                                           orderModel
//                                                                               .createdDate),
//                                                                       style: GoogleFonts.poppins(
//                                                                           fontSize:
//                                                                               12)),
//                                                                 ],
//                                                               )),
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ),
//                                             );
//                                           });
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                         // Banner section at the bottom
//                         _buildBanner(context),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBanner(BuildContext context) {
//     return Visibility(
//       visible: bannerList.isNotEmpty,
//       child: SizedBox(
//           height: MediaQuery.of(context).size.height * 0.25,
//           child: PageView.builder(
//               padEnds: true,
//               allowImplicitScrolling: true,
//               itemCount: bannerList.length,
//               scrollDirection: Axis.horizontal,
//               controller: pageController,
//               itemBuilder: (context, index) {
//                 OtherBannerModel bannerModel = bannerList[index];
//                 return Padding(
//                   padding:
//                       const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
//                   child: CachedNetworkImage(
//                     imageUrl: bannerModel.image.toString(),
//                     imageBuilder: (context, imageProvider) => Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         image: DecorationImage(
//                             image: imageProvider, fit: BoxFit.cover),
//                       ),
//                     ),
//                     color: Colors.black.withOpacity(0.5),
//                     placeholder: (context, url) =>
//                         const Center(child: CircularProgressIndicator()),
//                     fit: BoxFit.cover,
//                   ),
//                 );
//               })),
//     );
//   }

//   // Create cached map widget to prevent rapid creation/destruction
//   Widget _createCachedMapWidget({
//     required String cacheKey,
//     required LatLng source,
//     LatLng? destination,
//     LatLng? driverLocation,
//     double? carRotation,
//     bool showLiveTracking = false,
//     bool showRoute = false,
//   }) {
//     try {
//       if (_mapWidgetCache.containsKey(cacheKey)) {
//         return _mapWidgetCache[cacheKey]!;
//       }

//       // Add a small delay to ensure Google Maps is ready
//       if (!mounted) {
//         return Container(
//           height: Responsive.height(28, context),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             color: Colors.grey[200],
//           ),
//           child: const Center(
//             child: Text('Map loading...'),
//           ),
//         );
//       }

//       // Add unique identifier to prevent platform view conflicts
//       final uniqueKey = '${cacheKey}_${DateTime.now().millisecondsSinceEpoch}';

//       // Prevent rapid platform view creation
//       final now = DateTime.now();
//       if (_lastMapCreation != null &&
//           now.difference(_lastMapCreation!).inMilliseconds < 500) {
//         return Container(
//           height: Responsive.height(28, context),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             color: Colors.grey[200],
//           ),
//           child: const Center(
//             child: Text('Map loading...'),
//           ),
//         );
//       }
//       _lastMapCreation = now;

//       final mapWidget = RouteMapWidget(
//         source: source,
//         destination: destination,
//         driverLocation: driverLocation,
//         carRotation: carRotation,
//         showLiveTracking: showLiveTracking,
//         showRoute: showRoute,
//         key: ValueKey(uniqueKey),
//       );

//       _mapWidgetCache[cacheKey] = mapWidget;

//       // Cleanup cache after 5 seconds to prevent memory leaks
//       _cacheCleanupTimer?.cancel();
//       _cacheCleanupTimer = Timer(const Duration(seconds: 5), () {
//         if (mounted) {
//           _mapWidgetCache.clear();
//         }
//       });

//       return mapWidget;
//     } catch (e) {
//       print('Map widget creation error: $e');
//       return Container(
//         height: Responsive.height(28, context),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           color: Colors.grey[200],
//         ),
//         child: const Center(
//           child: Text('Map temporarily unavailable'),
//         ),
//       );
//     }
//   }

//   // Calculate distance between two points in kilometers
//   double _calculateDistance(
//       double lat1, double lng1, double lat2, double lng2) {
//     const double earthRadius = 6371; // Earth's radius in kilometers

//     double dLat = (lat2 - lat1) * (math.pi / 180);
//     double dLng = (lng2 - lng1) * (math.pi / 180);

//     double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(lat1 * (math.pi / 180)) *
//             math.cos(lat2 * (math.pi / 180)) *
//             math.sin(dLng / 2) *
//             math.sin(dLng / 2);

//     double c = 2 * math.atan(math.sqrt(a) / math.sqrt(1 - a));

//     return earthRadius * c;
//   }

//   // Drawer navigation method
//   void onSelectDrawerItem(int index) async {
//     if (index == 11) {
//       // Logout
//       await FirebaseAuth.instance.signOut();
//       Get.offAll(const LoginScreen());
//     } else {
//       selectedDrawerIndex.value = index;
//       // Navigate to appropriate screen
//       switch (index) {
//         case 0:
//           Get.offAll(const DashBoardScreen());
//           break;
//         case 1:
//           Get.offAll(const DashBoardScreen());
//           // ✅ CRITICAL FIX: Safely access DashBoardController
//           try {
//             Get.find<DashBoardController>().selectedDrawerIndex.value = 1;
//           } catch (e) {
//             print(
//                 'DashBoardController not found, will be created by DashBoardScreen');
//           }
//           break;
//         case 2:
//           // Already on rides screen
//           break;
//         case 3:
//           Get.offAll(const DashBoardScreen());
//           // ✅ CRITICAL FIX: Safely access DashBoardController
//           try {
//             Get.find<DashBoardController>().selectedDrawerIndex.value = 3;
//           } catch (e) {
//             print(
//                 'DashBoardController not found, will be created by DashBoardScreen');
//           }
//           break;
//         case 4:
//           Get.offAll(const DashBoardScreen());
//           // ✅ CRITICAL FIX: Safely access DashBoardController
//           try {
//             Get.find<DashBoardController>().selectedDrawerIndex.value = 4;
//           } catch (e) {
//             print(
//                 'DashBoardController not found, will be created by DashBoardScreen');
//           }
//           break;
//         case 5:
//           Get.offAll(const DashBoardScreen());
//           // ✅ CRITICAL FIX: Safely access DashBoardController
//           try {
//             Get.find<DashBoardController>().selectedDrawerIndex.value = 5;
//           } catch (e) {
//             print(
//                 'DashBoardController not found, will be created by DashBoardScreen');
//           }
//           break;
//         case 6:
//           Get.offAll(const DashBoardScreen());
//           // ✅ CRITICAL FIX: Safely access DashBoardController
//           try {
//             Get.find<DashBoardController>().selectedDrawerIndex.value = 6;
//           } catch (e) {
//             print(
//                 'DashBoardController not found, will be created by DashBoardScreen');
//           }
//           break;
//         case 7:
//           Get.offAll(const DashBoardScreen());
//           // ✅ CRITICAL FIX: Safely access DashBoardController
//           try {
//             Get.find<DashBoardController>().selectedDrawerIndex.value = 7;
//           } catch (e) {
//             print(
//                 'DashBoardController not found, will be created by DashBoardScreen');
//           }
//           break;
//         case 8:
//           Get.offAll(const DashBoardScreen());
//           // ✅ CRITICAL FIX: Safely access DashBoardController
//           try {
//             Get.find<DashBoardController>().selectedDrawerIndex.value = 8;
//           } catch (e) {
//             print(
//                 'DashBoardController not found, will be created by DashBoardScreen');
//           }
//           break;
//         case 9:
//           Get.offAll(const DashBoardScreen());
//           // ✅ CRITICAL FIX: Safely access DashBoardController
//           try {
//             Get.find<DashBoardController>().selectedDrawerIndex.value = 9;
//           } catch (e) {
//             print(
//                 'DashBoardController not found, will be created by DashBoardScreen');
//           }
//           break;
//         case 10:
//           Get.offAll(const DashBoardScreen());
//           // ✅ CRITICAL FIX: Safely access DashBoardController
//           try {
//             Get.find<DashBoardController>().selectedDrawerIndex.value = 10;
//           } catch (e) {
//             print(
//                 'DashBoardController not found, will be created by DashBoardScreen');
//           }
//           break;
//       }
//     }
//     Get.back(); // Close drawer
//   }

//   // Build drawer widget
//   Widget buildAppDrawer(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     var drawerOptions = <Widget>[];

//     for (var i = 0; i < drawerItems.length; i++) {
//       var d = drawerItems[i];
//       drawerOptions.add(InkWell(
//         onTap: () {
//           onSelectDrawerItem(i);
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Container(
//             decoration: BoxDecoration(
//                 color: i == selectedDrawerIndex.value
//                     ? Theme.of(context).colorScheme.primary
//                     : Colors.transparent,
//                 borderRadius: const BorderRadius.all(Radius.circular(10))),
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 SvgPicture.asset(
//                   d['icon'],
//                   width: 20,
//                   color: i == selectedDrawerIndex.value
//                       ? themeChange.getThem()
//                           ? Colors.black
//                           : Colors.white
//                       : themeChange.getThem()
//                           ? Colors.white
//                           : AppColors.drawerIcon,
//                 ),
//                 const SizedBox(
//                   width: 20,
//                 ),
//                 Text(
//                   d['title'],
//                   style: GoogleFonts.poppins(
//                       color: i == selectedDrawerIndex.value
//                           ? themeChange.getThem()
//                               ? Colors.black
//                               : Colors.white
//                           : themeChange.getThem()
//                               ? Colors.white
//                               : Colors.black,
//                       fontWeight: FontWeight.w500),
//                 )
//               ],
//             ),
//           ),
//         ),
//       ));
//     }

//     return Drawer(
//       backgroundColor: Theme.of(context).colorScheme.surface,
//       child: ListView(
//         children: [
//           DrawerHeader(
//             child: FutureBuilder<UserModel?>(
//               future:
//                   FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Constant.loader();
//                 } else if (snapshot.hasError) {
//                   return Text(snapshot.error.toString());
//                 } else if (!snapshot.hasData || snapshot.data == null) {
//                   return Icon(Icons.account_circle, size: 36);
//                 } else {
//                   UserModel userModel = snapshot.data!;
//                   return SingleChildScrollView(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(60),
//                           child: CachedNetworkImage(
//                             height: Responsive.width(20, context),
//                             width: Responsive.width(20, context),
//                             imageUrl: userModel.profilePic ??
//                                 Constant.userPlaceHolder,
//                             fit: BoxFit.cover,
//                             placeholder: (context, url) => Constant.loader(),
//                             errorWidget: (context, url, error) =>
//                                 Image.network(Constant.userPlaceHolder),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.only(top: 10),
//                           child: Text(userModel.fullName.toString(),
//                               style: GoogleFonts.poppins(
//                                   fontWeight: FontWeight.w500)),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.only(top: 2),
//                           child: Text(
//                             userModel.email.toString(),
//                             style: GoogleFonts.poppins(),
//                           ),
//                         )
//                       ],
//                     ),
//                   );
//                 }
//               },
//             ),
//           ),
//           Column(children: drawerOptions),
//         ],
//       ),
//     );
//   }
// }
