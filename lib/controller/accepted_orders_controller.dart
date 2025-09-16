import 'package:get/get.dart';

import 'home_controller.dart';

class AcceptedOrdersController extends GetxController {
  HomeController homeController = Get.put(HomeController());

  void setIndex() {
    homeController.selectedIndex.value = 2;
  }
}
