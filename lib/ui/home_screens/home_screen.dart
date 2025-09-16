import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/home_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;

import '../../constant/collection_name.dart';
import '../../constant/send_notification.dart';
import '../../model/banner_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void navigateToTap(String status, HomeController controller) {
    switch (status) {
      case Constant.rideHoldAccepted:
        controller.selectedIndex.value = 1;
        break;
      case Constant.rideActive:
        controller.selectedIndex.value = 2;
        break;
      case Constant.ridePlaced:
        controller.selectedIndex.value = 1;
        break;
      case Constant.rideInProgress:
        controller.selectedIndex.value = 2;
        break;
      case Constant.rideComplete:
        controller.selectedIndex.value = 3;
        break;
      default:
        controller.selectedIndex.value = 0;
        break;
    }
  }

  Future<bool> intercityActiveOrder(HomeController controller) async {
    final driverId = FireStoreUtils.getCurrentUid();
    final intercityOrdersSnap = await FirebaseFirestore.instance
        .collection(CollectionName.orders)
        .where('status', whereIn: [
      Constant.rideInProgress,
      Constant.rideActive,
      Constant.ridePlaced
    ]).get();

    for (final doc in intercityOrdersSnap.docs) {
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
        navigateToTap(orderSnap.data()?["status"], controller);
        return true;
      }
    }
    return false;
  }

  final HomeController controller = Get.put(HomeController());

  @override
  void initState() {
    intercityActiveOrder(controller);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<HomeController>(dispose: (state) {
      FireStoreUtils().closeStream();
    }, builder: (controller) {
      // Ensure controller is properly initialized
      double walletAmount = controller.driverModel.value.walletAmount == null
          ? 0.0
          : double.parse(controller.driverModel.value.walletAmount.toString());
      double minimumDepositToRideAccept =
          double.parse(Constant.minimumDepositToRideAccept);

      // Debug logging
      print(
          "🔍 HomeScreen Debug: selectedIndex = ${controller.selectedIndex.value}");
      print("🔍 HomeScreen Debug: isLoading = ${controller.isLoading.value}");

      return Container(
        color: AppColors.primary,
        child: controller.isLoading.value
            ? Constant.loader(context)
            : Column(
                children: [
                  if (controller.selectedIndex.value == 0)
                    _buildBanner(context, controller),
                  walletAmount >= minimumDepositToRideAccept
                      ? SizedBox(
                          height: Responsive.width(8, context),
                          width: Responsive.width(100, context),
                        )
                      : SizedBox(
                          height: Responsive.width(18, context),
                          width: Responsive.width(100, context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Text(
                                "${"You have to limit".tr} ${Constant.amountShow(amount: Constant.minimumDepositToRideAccept.toString())} ${"priceWallet".tr}"
                                    .tr,
                                style:
                                    GoogleFonts.poppins(color: Colors.white)),
                          ),
                        ),
                  Expanded(
                    child: Container(
                      height: Responsive.height(100, context),
                      width: Responsive.width(100, context),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25))),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: controller.widgetOptions
                            .elementAt(controller.selectedIndex.value),
                      ),
                    ),
                  ),
                  // Hide bottom banner on Active tab (index 2) to keep the UI map-centric
                  if (controller.selectedIndex.value != 0 &&
                      controller.selectedIndex.value != 2)
                    _buildBannerLow(context, controller),
                  // Bottom Navigation Bar as part of the content
                  BottomNavigationBar(
                      items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset("assets/icons/ic_new.png",
                                width: 18,
                                color: controller.selectedIndex.value == 0
                                    ? AppColors.darkModePrimary
                                    : Colors.white),
                          ),
                          label: 'New'.tr,
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset("assets/icons/ic_accepted.png",
                                width: 18,
                                color: controller.selectedIndex.value == 1
                                    ? AppColors.darkModePrimary
                                    : Colors.white),
                          ),
                          label: 'Accepted'.tr,
                        ),
                        BottomNavigationBarItem(
                          icon: badges.Badge(
                            badgeContent:
                                Text(controller.isActiveValue.value.toString()),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Image.asset("assets/icons/ic_active.png",
                                  width: 18,
                                  color: controller.selectedIndex.value == 2
                                      ? AppColors.darkModePrimary
                                      : Colors.white),
                            ),
                          ),
                          label: 'Active'.tr,
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset("assets/icons/ic_completed.png",
                                width: 18,
                                color: controller.selectedIndex.value == 3
                                    ? AppColors.darkModePrimary
                                    : Colors.white),
                          ),
                          label: 'Completed'.tr,
                        ),
                      ],
                      backgroundColor: AppColors.primary,
                      type: BottomNavigationBarType.fixed,
                      currentIndex: controller.selectedIndex.value,
                      selectedItemColor: AppColors.darkModePrimary,
                      unselectedItemColor: Colors.white,
                      selectedFontSize: 12,
                      unselectedFontSize: 12,
                      onTap: controller.onItemTapped),
                ],
              ),
      );
    });
  }

  Widget _buildBanner(BuildContext context, HomeController controller) {
    return Visibility(
      visible: controller.bannerList.isNotEmpty,
      child: Container(
          height: MediaQuery.of(context).size.height * 0.2,
          color: Colors.black,
          child: PageView.builder(
              padEnds: true,
              itemCount: controller.bannerList.length,
              scrollDirection: Axis.horizontal,
              controller: controller.pageController,
              itemBuilder: (context, index) {
                BannerModel bannerModel = controller.bannerList[index];
                return Padding(
                  padding: const EdgeInsets.all(10),
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

  Widget _buildBannerLow(BuildContext context, HomeController controller) {
    return Visibility(
      visible: controller.bannerListLow.isNotEmpty,
      child: Container(
          height: MediaQuery.of(context).size.height * 0.2,
          color: Colors.black,
          child: PageView.builder(
              padEnds: true,
              itemCount: controller.bannerListLow.length,
              scrollDirection: Axis.horizontal,
              controller: controller.pageControllerLow,
              itemBuilder: (context, index) {
                OtherBannerModel bannerModel = controller.bannerListLow[index];
                return Padding(
                  padding: const EdgeInsets.all(10),
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
