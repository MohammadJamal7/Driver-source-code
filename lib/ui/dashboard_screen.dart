import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/dash_board_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/banner_model.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  late final Stream<bool> _ordersStream;

  Stream<bool> mergedOrdersStreamForDriver() {
    final controller = StreamController<bool>.broadcast();
    final driverId = FireStoreUtils.getCurrentUid();

    final ordersStream = FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('status', whereIn: [
      Constant.rideInProgress,
      Constant.rideActive,
      Constant.ridePlaced
    ]).snapshots();

    final intercityOrdersStream = FirebaseFirestore.instance
        .collection(CollectionName.ordersIntercity)
        .where('status', whereIn: [
      Constant.rideInProgress,
      Constant.rideActive,
      Constant.ridePlaced
    ]).snapshots();

    StreamSubscription? ordersSub;
    StreamSubscription? intercitySub;

    Future<bool> hasValidOrders(
        List<QueryDocumentSnapshot> docs, String collection) async {
      for (final doc in docs) {
        final acceptedDriverSnap = await FirebaseFirestore.instance
            .collection(collection)
            .doc(doc.id)
            .collection("acceptedDriver")
            .doc(driverId)
            .get();

        final orderSnap = await FirebaseFirestore.instance
            .collection(collection)
            .doc(doc.id)
            .get();

        if (acceptedDriverSnap.exists &&
            orderSnap.exists &&
            (orderSnap.data()?["driverId"] == driverId)) {
          return true;
        }
      }
      return false;
    }

    void evaluateOrders(List<QueryDocumentSnapshot> cityDocs,
        List<QueryDocumentSnapshot> intercityDocs) async {
      final cityHas = await hasValidOrders(cityDocs, CollectionName.orders);
      final intercityHas =
          await hasValidOrders(intercityDocs, CollectionName.ordersIntercity);
      controller.add(cityHas || intercityHas);
    }

    List<QueryDocumentSnapshot> cityDocs = [];
    List<QueryDocumentSnapshot> intercityDocs = [];

    ordersSub = ordersStream.listen((snapshot) {
      cityDocs = snapshot.docs;
      evaluateOrders(cityDocs, intercityDocs);
    });

    intercitySub = intercityOrdersStream.listen((snapshot) {
      intercityDocs = snapshot.docs;
      evaluateOrders(cityDocs, intercityDocs);
    });

    controller.onCancel = () {
      ordersSub?.cancel();
      intercitySub?.cancel();
    };

    return controller.stream;
  }

  Future<bool> cityHasActiveOrder(String driverId) async {
    final cityOrdersSnap = await FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('status', whereIn: [
      Constant.rideInProgress,
      Constant.rideActive,
      Constant.ridePlaced
    ]).get();

    for (final doc in cityOrdersSnap.docs) {
      final acceptedDriverSnap = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(doc.id)
          .collection("acceptedDriver")
          .doc(driverId)
          .get();

      final orderSnap = await FirebaseFirestore.instance
          .collection(CollectionName.orders)
          .doc(doc.id)
          .get();

      if (acceptedDriverSnap.exists &&
          orderSnap.exists &&
          (orderSnap.data()?["driverId"] == driverId)) {
        return true;
      }
    }
    return false;
  }

  Future<bool> intercityHasActiveOrder(String driverId) async {
    final intercityOrdersSnap = await FirebaseFirestore.instance
        .collection(CollectionName.ordersIntercity)
        .where('status', whereIn: [
      Constant.rideInProgress,
      Constant.rideActive,
      Constant.ridePlaced
    ]).get();

    for (final doc in intercityOrdersSnap.docs) {
      final acceptedDriverSnap = await FirebaseFirestore.instance
          .collection(CollectionName.ordersIntercity)
          .doc(doc.id)
          .collection("acceptedDriver")
          .doc(driverId)
          .get();

      final orderSnap = await FirebaseFirestore.instance
          .collection(CollectionName.ordersIntercity)
          .doc(doc.id)
          .get();

      if (acceptedDriverSnap.exists &&
          orderSnap.exists &&
          (orderSnap.data()?["driverId"] == driverId)) {
        return true;
      }
    }
    return false;
  }

  void checkDriverActiveOrdersAndNavigate() async {
    final driverId = FireStoreUtils.getCurrentUid();
    final hasCityOrder = await cityHasActiveOrder(driverId);
    final hasIntercityOrder = await intercityHasActiveOrder(driverId);

    // Get the DashBoardController to set the correct drawer index
    final controller = Get.find<DashBoardController>();

    if (hasCityOrder) {
      // Stay on DashBoardScreen but show HomeScreen (drawer index 0)
      controller.selectedDrawerIndex.value = 0;
    } else if (hasIntercityOrder) {
      // Stay on DashBoardScreen but show HomeIntercityScreen (drawer index 1)
      controller.selectedDrawerIndex.value = 1;
    }
  }

  @override
  void initState() {
    super.initState();
    checkDriverActiveOrdersAndNavigate();
    _ordersStream = mergedOrdersStreamForDriver().asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<DashBoardController>(
        init: DashBoardController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: controller.selectedDrawerIndex.value == 0
                  ? Constant.isGuestUser
                      ? Text("Guest User".tr)
                      : StreamBuilder(
                          stream: FireStoreUtils.fireStore
                              .collection(CollectionName.driverUsers)
                              .doc(FireStoreUtils.getCurrentUid())
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Something went wrong'.tr);
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Constant.loader(context);
                            }

                            if (!snapshot.hasData ||
                                snapshot.data == null ||
                                snapshot.data!.data() == null) {
                              return Text("Guest User".tr);
                            }

                            DriverUserModel driverModel =
                                DriverUserModel.fromJson(
                                    snapshot.data!.data()!);

                            return Container(
                              width: Responsive.width(50, context),
                              height: Responsive.height(5.5, context),
                              decoration: const BoxDecoration(
                                color: AppColors.darkBackground,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50.0)),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedAlign(
                                    alignment: Alignment(
                                        driverModel.isOnline == true ? -1 : 1,
                                        0),
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      width: Responsive.width(26, context),
                                      height: Responsive.height(8, context),
                                      decoration: const BoxDecoration(
                                        color: AppColors.darkModePrimary,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(50.0)),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      ShowToastDialog.showLoader(
                                          "Please wait".tr);
                                      if (driverModel.documentVerification ==
                                          false) {
                                        ShowToastDialog.closeLoader();
                                        _showAlertDialog(context, "document");
                                      } else if (driverModel
                                                  .vehicleInformation ==
                                              null ||
                                          driverModel.serviceId == null) {
                                        ShowToastDialog.closeLoader();
                                        _showAlertDialog(
                                            context, "vehicleInformation");
                                      } else {
                                        log("333");
                                        driverModel.isOnline = true;
                                        print(
                                            'before documentVerification:->>${driverModel.toJson()}');
                                        driverModel.documentVerification = true;
                                        print(
                                            'After documentVerification->> ${driverModel.toJson()}');

                                        await FireStoreUtils.updateDriverUser(
                                            driverModel);
                                        ShowToastDialog.closeLoader();
                                      }
                                    },
                                    child: Align(
                                      alignment: const Alignment(-1, 0),
                                      child: Container(
                                        width: Responsive.width(26, context),
                                        color: Colors.transparent,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Online'.tr,
                                          style: GoogleFonts.poppins(
                                              color:
                                                  driverModel.isOnline == true
                                                      ? Colors.black
                                                      : Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      ShowToastDialog.showLoader(
                                          "Please wait".tr);
                                      driverModel.isOnline = false;
                                      await FireStoreUtils.updateDriverUser(
                                          driverModel);
                                      ShowToastDialog.closeLoader();
                                    },
                                    child: Align(
                                      alignment: const Alignment(1, 0),
                                      child: Container(
                                        width: Responsive.width(26, context),
                                        color: Colors.transparent,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Offline'.tr,
                                          style: GoogleFonts.poppins(
                                              color:
                                                  driverModel.isOnline == false
                                                      ? Colors.black
                                                      : Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                  : Text(
                      controller
                          .drawerItems[controller.selectedDrawerIndex.value]
                          .title
                          .tr,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
              centerTitle: true,
              leading: StreamBuilder<bool>(
                stream: _ordersStream,
                builder: (context, snapshot) {
                  if (snapshot.data == false) {
                    return Builder(builder: (context) {
                      return InkWell(
                        onTap: () {
                          final scaffoldState = Scaffold.maybeOf(context);
                          final drawer = scaffoldState?.widget.drawer;
                          if (drawer != null && drawer is! SizedBox) {
                            scaffoldState?.openDrawer();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 20, top: 20, bottom: 20),
                          child: SvgPicture.asset('assets/icons/ic_humber.svg'),
                        ),
                      );
                    });
                  } else {
                    return SizedBox();
                  }
                },
              ),
              actions: [
                controller.selectedDrawerIndex.value == 3
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: InkWell(
                          overlayColor: WidgetStatePropertyAll(Colors.black),
                          onTap: () async {
                            String message =
                                "السلام عليكم, عندى استفسار بخصوص المحفظة فى تطبيق السائق";
                            final Uri url = Uri.parse(
                                "https://wa.me/${Constant.phone.toString()}?text=${Uri.encodeComponent(message)}");
                            if (!await launchUrl(url)) {
                              throw Exception(
                                  'Could not launch ${Constant.supportURL.toString()}'
                                      .tr);
                            }
                          },
                          child: SvgPicture.asset('assets/icons/ic_support.svg',
                              width: 24),
                        ),
                      )
                    : Container(),
              ],
            ),
            drawer: StreamBuilder<bool>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                log("Snap: ${snapshot.data}");
                if (!snapshot.hasData)
                  return buildAppDrawer(context, controller);
                return snapshot.data!
                    ? SizedBox()
                    : buildAppDrawer(context, controller);
              },
            ),
            drawerEnableOpenDragGesture: false,
            body: WillPopScope(
                onWillPop: controller.onWillPop,
                child: Column(
                  children: [
                    // _buildBanner(context, controller),
                    Expanded(
                      child: controller.getDrawerItemWidget(
                          controller.selectedDrawerIndex.value),
                    ),
                  ],
                )),
          );
        });
  }

  Future<void> _showAlertDialog(BuildContext context, String type) async {
    final controllerDashBoard = Get.put(DashBoardController());

    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          // <-- SEE HERE
          title: Text('Information'.tr),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'To start earning with GoRide you need to fill in your personal information'
                        .tr),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('No'.tr),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: Text('Yes'.tr),
              onPressed: () {
                if (type == "document") {
                  if (Constant.isVerifyDocument == true) {
                    controllerDashBoard.onSelectItem(7);
                  } else {
                    controllerDashBoard.onSelectItem(6);
                  }
                } else {
                  if (Constant.isVerifyDocument == true) {
                    controllerDashBoard.onSelectItem(8);
                  } else {
                    controllerDashBoard.onSelectItem(7);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  buildAppDrawer(BuildContext context, DashBoardController controller) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    List<DrawerItem> drawerItems = [];
    if (Constant.isSubscriptionModelApplied == true) {
      drawerItems = [
        DrawerItem('City'.tr, "assets/icons/ic_city.svg"),
        // DrawerItem('Rides'.tr, "assets/icons/ic_order.svg"),
        DrawerItem('OutStation'.tr, "assets/icons/ic_intercity.svg"),
        // DrawerItem('OutStation Rides'.tr, "assets/icons/ic_order.svg"),
        DrawerItem('Freight'.tr, "assets/icons/ic_freight.svg"),
        DrawerItem('My Wallet'.tr, "assets/icons/ic_wallet.svg"),
        DrawerItem('Bank Details'.tr, "assets/icons/ic_profile.svg"),
        DrawerItem('Inbox'.tr, "assets/icons/ic_inbox.svg"),
        DrawerItem('Profile'.tr, "assets/icons/ic_profile.svg"),
        if (Constant.isVerifyDocument == true)
          DrawerItem('Online Registration'.tr, "assets/icons/ic_document.svg"),
        DrawerItem('Vehicle Information'.tr, "assets/icons/ic_city.svg"),
        DrawerItem('Settings'.tr, "assets/icons/ic_settings.svg"),
        // DrawerItem('Subscription'.tr, "assets/icons/ic_subscription.svg"),
        // DrawerItem('Subscription History'.tr,
        //     "assets/icons/ic_subscription_history.svg"),
        DrawerItem('Log out'.tr, "assets/icons/ic_logout.svg"),
      ];
    } else {
      drawerItems = [
        DrawerItem('City'.tr, "assets/icons/ic_city.svg"),
        // DrawerItem('Rides'.tr, "assets/icons/ic_order.svg"),
        DrawerItem('OutStation'.tr, "assets/icons/ic_intercity.svg"),
        // DrawerItem('OutStation Rides'.tr, "assets/icons/ic_order.svg"),
        DrawerItem('Freight'.tr, "assets/icons/ic_freight.svg"),
        DrawerItem('My Wallet'.tr, "assets/icons/ic_wallet.svg"),
        DrawerItem('Bank Details'.tr, "assets/icons/ic_profile.svg"),
        DrawerItem('Inbox'.tr, "assets/icons/ic_inbox.svg"),
        DrawerItem('Profile'.tr, "assets/icons/ic_profile.svg"),
        if (Constant.isVerifyDocument == true)
          DrawerItem('Online Registration'.tr, "assets/icons/ic_document.svg"),
        DrawerItem('Vehicle Information'.tr, "assets/icons/ic_city.svg"),
        DrawerItem('Settings'.tr, "assets/icons/ic_settings.svg"),
        // DrawerItem('Subscription History'.tr,
        //     "assets/icons/ic_subscription_history.svg"),
        DrawerItem('Log out'.tr, "assets/icons/ic_logout.svg"),
      ];
    }
    var drawerOptions = <Widget>[];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      // Guest-mode gating: allow only Home (0), Profile (6), Settings, and Log out
      final settingsIndex = Constant.isVerifyDocument == true ? 9 : 8;
      final logoutIndex = Constant.isVerifyDocument == true ? 10 : 9;
      final allowed = {0, 6, settingsIndex, logoutIndex};
      final isDisabled = Constant.isGuestUser && !allowed.contains(i);

      final bool isSelected = i == controller.selectedDrawerIndex.value;
      final Color selectedBg = Theme.of(context).colorScheme.primary;
      final Color enabledIconColor = isSelected
          ? (themeChange.getThem() ? Colors.black : Colors.white)
          : (themeChange.getThem() ? Colors.white : AppColors.drawerIcon);
      final Color enabledTextColor = isSelected
          ? (themeChange.getThem() ? Colors.black : Colors.white)
          : (themeChange.getThem() ? Colors.white : Colors.black);
      final Color iconColor =
          isDisabled ? Colors.grey.withOpacity(0.5) : enabledIconColor;
      final Color textColor =
          isDisabled ? Colors.grey.withOpacity(0.6) : enabledTextColor;

      drawerOptions.add(Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  controller.onSelectItem(i);
                },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                  color: isSelected ? selectedBg : Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(10))),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    d.icon,
                    width: 20,
                    color: iconColor,
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Text(
                    d.title,
                    style: GoogleFonts.poppins(
                        color: textColor, fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
          ),
        ),
      ));
    }
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: FutureBuilder<DriverUserModel?>(
              future: FireStoreUtils.getDriverProfile(
                  FireStoreUtils.getCurrentUid()),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Constant.loader(context);
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  NetworkImage(Constant.userPlaceHolder),
                            ),
                            SizedBox(height: 10),
                            Text(
                                Constant.isGuestUser
                                    ? "السائق الضيف"
                                    : "Guest User".tr,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500)),
                            Text(Constant.isGuestUser ? "guest@wdni.com" : "-",
                                style: GoogleFonts.poppins()),
                          ],
                        ),
                      );
                    } else {
                      DriverUserModel driverModel = snapshot.data!;
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: CachedNetworkImage(
                                height: Responsive.width(20, context),
                                width: Responsive.width(20, context),
                                imageUrl: driverModel.profilePic.toString(),
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Constant.loader(context),
                                errorWidget: (context, url, error) =>
                                    Image.network(Constant.userPlaceHolder),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(driverModel.fullName.toString(),
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500)),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                driverModel.email.toString(),
                                style: GoogleFonts.poppins(),
                              ),
                            )
                          ],
                        ),
                      );
                    }
                  default:
                    return Text('Error'.tr);
                }
              },
            ),
          ),
          Column(children: drawerOptions),
        ],
      ),
    );
  }
}
