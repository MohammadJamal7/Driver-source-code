import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/controller/home_intercity_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:badges/badges.dart' as badges;

import '../../constant/collection_name.dart';
import '../../constant/constant.dart';

class HomeIntercityScreen extends StatefulWidget {
  const HomeIntercityScreen({Key? key}) : super(key: key);

  @override
  State<HomeIntercityScreen> createState() => _HomeIntercityScreenState();
}

class _HomeIntercityScreenState extends State<HomeIntercityScreen> {

  void navigateToTap(String status, HomeIntercityController controller) {
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

  Future<bool> intercityActiveOrder(HomeIntercityController controller) async {
    final driverId = FireStoreUtils.getCurrentUid();
    final intercityOrdersSnap = await FirebaseFirestore.instance
        .collection(CollectionName.ordersIntercity)
        .where('status',
            whereIn: [Constant.rideInProgress, Constant.rideActive, Constant.ridePlaced]).get();

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
        navigateToTap(orderSnap.data()?["status"], controller);
        return true;
      }
    }
    return false;
  }

  final HomeIntercityController controller = Get.put(HomeIntercityController());

  @override
  void initState() {
    intercityActiveOrder(controller);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<HomeIntercityController>(
        init: HomeIntercityController(),
        dispose: (state) {
          FireStoreUtils().closeStream();
        },
        builder: (controller) {
          return controller.selectedService.value.intercityType ?? false
              ? Scaffold(
                  body: controller.widgetOptions
                      .elementAt(controller.selectedIndex.value),
                  bottomNavigationBar: BottomNavigationBar(
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
                        icon: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Image.asset("assets/icons/ic_active.png",
                              width: 18,
                              color: controller.selectedIndex.value == 2
                                  ? AppColors.darkModePrimary
                                  : Colors.white),
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
                    elevation: 5,
                    onTap: controller.onItemTapped,
                  ),
                )
              : Scaffold(
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
                              topRight: Radius.circular(25),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${"Intercity/Outstation feature is disable for".tr} ${Constant.localizationTitle(controller.selectedService.value.title)}"
                                      .tr,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
        });
  }
}
