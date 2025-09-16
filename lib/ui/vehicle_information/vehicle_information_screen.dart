import 'package:cached_network_image/cached_network_image.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/vehicle_information_controller.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/vehicle_type_year.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

class VehicleInformationScreen extends StatefulWidget {
  VehicleInformationScreen({super.key});

  @override
  State<VehicleInformationScreen> createState() => _VehicleInformationScreenState();
}

class _VehicleInformationScreenState extends State<VehicleInformationScreen> with WidgetsBindingObserver {
  SuperTooltip? tooltip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Add a delayed refresh to ensure controller is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (Get.isRegistered<VehicleInformationController>()) {
          await Get.find<VehicleInformationController>().refreshServiceCards();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh service cards when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      if (Get.isRegistered<VehicleInformationController>()) {
        Get.find<VehicleInformationController>().refreshServiceCards();
      }
    }
  }

  final Map<String, String> serviceTooltips = {
    'تاكسي':
        'تختار هذة الخدمة إذا عندك تاكسي عدد المقاعد من ٤ إلى ٧ مقعد وتبغى تشتغل داخل المدينة والمدن القريبة',
    'توك توك': 'تختار هذة الخدمة إذا عندك توك توك للمشاوير داخل المدينة',
    'باص':
        'تختار هذة الخدمة إذا عندك باص عدد المقاعد من ١٥ إلى ٣٠ مقعد وتبغى تشتغل داخل المدينة والمدن القريبة',
    'دراجة نارية':
        'تختار هذة الخدمة إذا عندك دراجة نارية وتبغى تشتغل داخل المدينة للأماكن القريبة',
    'خدمة توصيل':
    'تختار هذة الخدمة أذا عندك سيارة أو دراجة نارية  وتبغى تشتغل في توصيل الطرود أو الأغراض الخفيفة',
    'رحلة مجدولة':
       'تختار هذة الخدمة إذا عندك سيارة عدد ركابها من ٤ إلى ٣٠ راكب وتبغى تشتغل للحجوزات المسبقة في موعد وتاريخ معين داخل المدينة والمدن الأخرى',
    'مشتركة مع ركاب':
        'تختار هذة الخدمة إذا عندك سيارة وتبغى تشتغل بنظام الفرزات تحميل ركاب للمشاوير بين المدن والخطوط الطويلة.',
    'الشحن والنقل':
    'تختار هذة الخدمة إذا عندك سيارة شحن ربع نقل أو نص نقل أو تروسيكل لنقل الأثاث أو العفش أو البضاعة داخل المدينة أو خارجها',
  };

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<VehicleInformationController>(
      init: VehicleInformationController(),
      builder: (controller) {
        final colorItems = controller.carColorList.toSet().toList();

        final yearItems = controller.vehicleYearList.toSet().toList();
        final selectedValue =
            colorItems.contains(controller.selectedColor.value)
                ? controller.selectedColor.value
                : null;
        final selectedYear = controller.selectedYear.value.year != null &&
                yearItems.any((item) => item.year == controller.selectedYear.value.year)
            ? controller.selectedYear.value
            : null;
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              SizedBox(
                height: Responsive.width(10, context),
                width: Responsive.width(100, context),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25))),
                  child: controller.isLoading.value
                      ? Constant.loader(context)
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  height: Responsive.height(22, context),
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  child: Obx(() {
                                    return ListView.builder(
                                      itemCount: controller.serviceList.length,
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) {
                                        ServiceModel serviceModel =
                                            controller.serviceList[index];
                                        return Obx(
                                          () => InkWell(
                                            onTap: controller.isCoreFieldsLocked
                                                ? null
                                                : () async {
                                                    // Refresh service cards state before selection
                                                    await controller.refreshServiceCards();
                                                    
                                                    // Handle service selection
                                                    controller
                                                        .selectedServiceType
                                                        .value = serviceModel;
                                                    // Add calculation logic if needed
                                                  },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              child: Container(
                                                width: Responsive.width(
                                                    28, context),
                                                decoration: BoxDecoration(
                                                  color: controller
                                                              .selectedServiceType
                                                              .value
                                                              .id ==
                                                          serviceModel.id
                                                      ? AppColors
                                                          .darkModePrimary
                                                      : themeChange.getThem()
                                                          ? AppColors
                                                              .darkContainerBackground
                                                          : const Color(
                                                              0xFFF5F5F5),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(20),
                                                  ),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const SizedBox(
                                                            height: 6),
                                                        Center(
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl:
                                                                serviceModel
                                                                    .image
                                                                    .toString(),
                                                            fit: BoxFit.contain,
                                                            height: Responsive
                                                                .height(10,
                                                                    context),
                                                            width: Responsive
                                                                .width(18,
                                                                    context),
                                                            placeholder: (context,
                                                                    url) =>
                                                                Constant.loader(
                                                                    context),
                                                            errorWidget: (context,
                                                                    url,
                                                                    error) =>
                                                                Image.network(
                                                                    Constant
                                                                        .userPlaceHolder),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Flexible(
                                                          child: Text(
                                                            Constant
                                                                .localizationTitle(
                                                                    serviceModel
                                                                        .title),
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: Responsive
                                                                  .width(3,
                                                                      context),
                                                              color: controller
                                                                          .selectedServiceType
                                                                          .value
                                                                          .id ==
                                                                      serviceModel
                                                                          .id
                                                                  ? Colors.black
                                                                  : themeChange
                                                                          .getThem()
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black87,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                      ],
                                                    ),
                                                    // Info icon with tooltip - only show when selected
                                                    if (serviceTooltips.containsKey(
                                                            Constant.localizationTitle(
                                                                    serviceModel
                                                                        .title)
                                                                .trim()) &&
                                                        controller
                                                                .selectedServiceType
                                                                .value
                                                                .id ==
                                                            serviceModel.id)
                                                      Positioned(
                                                        top: 4,
                                                        left: 10,
                                                        child: Builder(
                                                          builder: (context) {
                                                            final key = GlobalKey();
                                                            return GestureDetector(
                                                              key: key,
                                                              onTap: () {
                                                                final serviceName = Constant
                                                                    .localizationTitle(
                                                                        serviceModel
                                                                            .title);
                                                                String? message =
                                                                    serviceTooltips[
                                                                        serviceName];
                                                                if (message == null)
                                                                  return;
                                                                showTooltip(context,
                                                                    message);
                                                              },
                                                              child: const Icon(
                                                                Icons.info_outline,
                                                                color: Colors.white,
                                                                size: 18,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Opacity(
                                  opacity:
                                      controller.isCoreFieldsLocked ? 0.7 : 1.0,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      disabledColor:
                                          Theme.of(context).hintColor,
                                      hintColor: Theme.of(context).hintColor,
                                    ),
                                    child: AbsorbPointer(
                                      absorbing: controller.isCoreFieldsLocked,
                                      child: TextFieldThem.buildTextFiled(
                                        context,
                                        hintText: 'Vehicle Number'.tr,
                                        controller: controller
                                            .vehicleNumberController.value,
                                        enable: !controller.isCoreFieldsLocked,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Opacity(
                                  opacity:
                                      controller.isCoreFieldsLocked ? 0.7 : 1.0,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      disabledColor:
                                          Theme.of(context).hintColor,
                                      hintColor: Theme.of(context).hintColor,
                                    ),
                                    child: AbsorbPointer(
                                      absorbing: controller.isCoreFieldsLocked,
                                      child: InkWell(
                                        onTap: () async {
                                          final value =
                                              await Constant.selectDate(
                                                  context);
                                          if (value != null) {
                                            controller.selectedDate.value =
                                                value;
                                            controller
                                                    .registrationDateController
                                                    .value
                                                    .text =
                                                DateFormat("dd-MM-yyyy")
                                                    .format(value);
                                          }
                                        },
                                        child: TextFieldThem.buildTextFiled(
                                          context,
                                          hintText: 'Registration Date'.tr,
                                          controller: controller
                                              .registrationDateController.value,
                                          enable: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                DropdownButtonFormField<VehicleTypeModel>(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: themeChange.getThem()
                                          ? AppColors.darkTextField
                                          : AppColors.textField,
                                      contentPadding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null ? 'field required' : null,
                                    value:
                                        controller.selectedVehicle.value.id ==
                                                null
                                            ? null
                                            : controller.selectedVehicle.value,
                                    onChanged: !controller.isCoreFieldsLocked
                                        ? (value) {
                                            controller.selectedVehicle.value =
                                                value!;
                                          }
                                        : null,
                                    hint: Text("Select vehicle type".tr),
                                    items: controller.vehicleList.map((item) {
                                      return DropdownMenuItem(
                                        value: item,
                                        child: Text(Constant.localizationName(
                                            item.name)),
                                      );
                                    }).toList()),
                                const SizedBox(
                                  height: 10,
                                ),
                                DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: themeChange.getThem()
                                          ? AppColors.darkTextField
                                          : AppColors.textField,
                                      contentPadding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null ? 'field required' : null,
                                    value: selectedValue,
                                    onChanged: !controller.isCoreFieldsLocked
                                        ? (value) {
                                            controller.selectedColor.value =
                                                value!;
                                          }
                                        : null,
                                    hint: Text("Select vehicle color".tr),
                                    items: colorItems.map((item) {
                                      return DropdownMenuItem(
                                        value: item,
                                        child: Text(item.tr),
                                      );
                                    }).toList()),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<VehicleYearModel>(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: themeChange.getThem()
                                          ? AppColors.darkTextField
                                          : AppColors.textField,
                                      contentPadding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(4)),
                                        borderSide: BorderSide(
                                            color: themeChange.getThem()
                                                ? AppColors.darkTextFieldBorder
                                                : AppColors.textFieldBorder,
                                            width: 1),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null ? 'field required' : null,
                                    value: selectedYear,
                                    onChanged: !controller.isCoreFieldsLocked
                                        ? (value) {
                                            controller.selectedYear.value =
                                                value!;
                                            controller.selectedCarModel.value =
                                                value.year.toString();
                                          }
                                        : null,
                                    hint: Text("Select car model".tr),
                                    items: controller.vehicleYearList
                                        .toSet()
                                        .map((item) {
                                      return DropdownMenuItem(
                                        value: item,
                                        child: Text('${item.year}'),
                                      );
                                    }).toList()),

                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: themeChange.getThem()
                                        ? AppColors.darkTextField
                                        : AppColors.textField,
                                    contentPadding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(4)),
                                      borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null ? 'field required' : null,
                                  value: controller.whereWork.contains(
                                          controller.selectedWhereWork)
                                      ? controller.selectedWhereWork
                                      : null,
                                  onChanged: !controller.isCoreFieldsLocked
                                      ? (value) {
                                          controller.selectedWhereWork = value!;
                                        }
                                      : null,
                                  hint: Text("Select where work".tr),
                                  items:
                                      controller.whereWork.toSet().map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item == "داخل المدينة"
                                          ? "inCity".tr
                                          : "outCity".tr),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 10),
                                Opacity(
                                  opacity:
                                      controller.isCoreFieldsLocked ? 0.7 : 1.0,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      disabledColor:
                                          Theme.of(context).hintColor,
                                      hintColor: Theme.of(context).hintColor,
                                    ),
                                    child: AbsorbPointer(
                                      absorbing: controller.isCoreFieldsLocked,
                                      child: TextFieldThem.buildTextFiled(
                                        context,
                                        hintText: 'How Many Seats'.tr,
                                        controller:
                                            controller.seatsController.value,
                                        keyBoardType: TextInputType.number,
                                        enable: !controller.isCoreFieldsLocked,
                                      ),
                                    ),
                                  ),
                                ),
                                // DropdownButtonFormField<String>(
                                //     decoration: InputDecoration(
                                //       filled: true,
                                //       fillColor: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
                                //       contentPadding: const EdgeInsets.only(left: 10, right: 10),
                                //       disabledBorder: OutlineInputBorder(
                                //         borderRadius: const BorderRadius.all(Radius.circular(4)),
                                //         borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                //       ),
                                //       focusedBorder: OutlineInputBorder(
                                //         borderRadius: const BorderRadius.all(Radius.circular(4)),
                                //         borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                //       ),
                                //       enabledBorder: OutlineInputBorder(
                                //         borderRadius: const BorderRadius.all(Radius.circular(4)),
                                //         borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                //       ),
                                //       errorBorder: OutlineInputBorder(
                                //         borderRadius: const BorderRadius.all(Radius.circular(4)),
                                //         borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                //       ),
                                //       border: OutlineInputBorder(
                                //         borderRadius: const BorderRadius.all(Radius.circular(4)),
                                //         borderSide: BorderSide(color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder, width: 1),
                                //       ),
                                //     ),
                                //     validator: (value) => value == null ? 'field required' : null,
                                //     value: controller.seatsController.value.text.isEmpty ? null : controller.seatsController.value.text,
                                //     onChanged: (value) {
                                //       controller.seatsController.value.text = value!;
                                //     },
                                //     hint: Text("How Many Seats".tr),
                                //     items: controller.sheetList.map((item) {
                                //       return DropdownMenuItem(
                                //         value: item,
                                //         child: Text(item.toString()),
                                //       );
                                //     }).toList()),

                                const SizedBox(
                                  height: 10,
                                ),
                                InkWell(
                                  onTap: () {
                                    zoneDialog(context, controller);
                                  },
                                  child: TextFieldThem.buildTextFiled(
                                    context,
                                    hintText: 'Select Zone'.tr,
                                    controller:
                                        controller.zoneNameController.value,
                                    enable: false,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Obx(() => CheckboxListTile(
                                      title: Text(
                                        'hasAC'.tr,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      value: controller.hasAcFeature.value,
                                      checkColor: themeChange.getThem()
                                          ? AppColors.darkModePrimary
                                          : AppColors.primary,
                                      onChanged: (value) {
                                        controller.hasAcFeature.value =
                                            value ?? false;

                                        controller
                                            .driverModel
                                            .value
                                            .vehicleInformation
                                            ?.is_AC = value ?? false;
                                      },
                                    )),

                                // Obx(() => controller.hasAcFeature.value
                                //     ?
                                //     Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                                //       Text("A/C Per Km Rate".tr,
                                //           style: GoogleFonts.poppins(
                                //               fontSize: 16,
                                //               fontWeight: FontWeight.w600,),),
                                //       const SizedBox(
                                //         height: 10,
                                //       ),
                                //       TextFieldThem
                                //           .buildTextFiledWithPrefixIcon(
                                //         context,
                                //         hintText: 'A/C Per Km Rate'.tr,
                                //         keyBoardType:
                                //         TextInputType.numberWithOptions(
                                //             decimal: true),
                                //         controller: controller.acPerKmRate.value,
                                //         prefix: Padding(
                                //           padding: const EdgeInsets.only(
                                //               right: 10),
                                //           child: Text(Constant
                                //               .currencyModel!.symbol
                                //               .toString()),
                                //         ),
                                //       ),
                                //     ],):SizedBox.shrink(),),

                                // Column(
                                //   crossAxisAlignment:
                                //   CrossAxisAlignment.start,
                                //   children: [
                                //     Text("Per Km Rate".tr,
                                //         style: GoogleFonts.poppins(
                                //             fontSize: 16,
                                //             fontWeight: FontWeight.w600)),
                                //     TextFieldThem
                                //         .buildTextFiledWithPrefixIcon(
                                //       context,
                                //       hintText: 'Per Km Rate'.tr,
                                //       controller: controller
                                //           .acNonAcWithoutPerKmRate.value,
                                //       keyBoardType:
                                //       TextInputType.numberWithOptions(
                                //           decimal: true),
                                //       prefix: Padding(
                                //         padding: const EdgeInsets.only(
                                //             right: 10),
                                //         child: Text(Constant
                                //             .currencyModel!.symbol
                                //             .toString()),
                                //       ),
                                //     ),
                                //     SizedBox(
                                //       height: 10,
                                //     )
                                //   ],
                                // ),
                                Text("Select Your Rules".tr,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16)),
                                ListBody(
                                  children: controller.driverRulesList
                                      .map((item) => CheckboxListTile(
                                            checkColor: themeChange.getThem()
                                                ? AppColors.darkModePrimary
                                                : AppColors.primary,
                                            value: controller
                                                        .selectedDriverRulesList
                                                        .indexWhere((element) =>
                                                            element.id ==
                                                            item.id) ==
                                                    -1
                                                ? false
                                                : true,
                                            title: Text(
                                                Constant.localizationName(
                                                    item.name),
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w400)),
                                            onChanged: (value) {
                                              if (value == true) {
                                                controller
                                                    .selectedDriverRulesList
                                                    .add(item);
                                              } else {
                                                controller
                                                    .selectedDriverRulesList
                                                    .removeAt(controller
                                                        .selectedDriverRulesList
                                                        .indexWhere((element) =>
                                                            element.id ==
                                                            item.id));
                                              }
                                            },
                                          ))
                                      .toList(),
                                ),

                                const SizedBox(
                                  height: 20,
                                ),
                                Align(
                                    alignment: Alignment.center,
                                    child: ButtonThem.buildButton(
                                      context,
                                      title: "Save".tr,
                                      onPress: () async {
                                        ShowToastDialog.showLoader(
                                            "Please wait".tr);

                                        if (controller.selectedServiceType.value
                                                    .id ==
                                                null ||
                                            controller.selectedServiceType.value
                                                .id!.isEmpty) {
                                          ShowToastDialog.showToast(
                                              "Please select service".tr);
                                          return;
                                        }

                                        if (controller.vehicleNumberController
                                            .value.text.isEmpty) {
                                          ShowToastDialog.showToast(
                                            "Please enter Vehicle number".tr,
                                          );
                                        } else if (controller
                                            .registrationDateController
                                            .value
                                            .text
                                            .isEmpty) {
                                          ShowToastDialog.showToast(
                                            "Please select registration date"
                                                .tr,
                                          );
                                        } else if (controller
                                                    .selectedVehicle.value.id ==
                                                null ||
                                            controller.selectedVehicle.value.id!
                                                .isEmpty) {
                                          ShowToastDialog.showToast(
                                            "Please enter Vehicle type".tr,
                                          );
                                        } else if (controller
                                            .selectedColor.value.isEmpty) {
                                          ShowToastDialog.showToast(
                                            "Please enter Vehicle color".tr,
                                          );
                                        } else if (controller.seatsController
                                            .value.text.isEmpty) {
                                          ShowToastDialog.showToast(
                                            "Please enter seats".tr,
                                          );
                                        } else if (controller
                                            .selectedZone.isEmpty) {
                                          ShowToastDialog.showToast(
                                            "Please select Zone".tr,
                                          );
                                        } else if (controller
                                                    .selectedWhereWork ==
                                                "" ||
                                            controller.selectedWhereWork ==
                                                null) {
                                          ShowToastDialog.showToast(
                                            "Please select place work".tr,
                                          );
                                        } else if (controller
                                                .selectedServiceType
                                                .value
                                                .isAcNonAc ==
                                            true) {
                                          if (controller
                                              .acPerKmRate.value.text.isEmpty) {
                                            ShowToastDialog.showToast(
                                              "Please enter A/C Per Km Rate".tr,
                                            );
                                            return;
                                          } else if (double.parse(controller
                                                  .selectedServiceType
                                                  .value
                                                  .acCharge
                                                  .toString()) <
                                              double.parse(controller
                                                  .acPerKmRate.value.text)) {
                                            ShowToastDialog.showToast(
                                              "${"Maximum allowed value is".tr} ${controller.selectedServiceType.value.acCharge.toString()} ${"Please enter a lower A/c value.".tr}"
                                                  .tr,
                                            );
                                            return;
                                          } else if (controller.nonAcPerKmRate
                                              .value.text.isEmpty) {
                                            ShowToastDialog.showToast(
                                              "Please enter Non A/C Per Km Rate"
                                                  .tr,
                                            );
                                            return;
                                          } else if (double.parse(controller
                                                  .selectedServiceType
                                                  .value
                                                  .nonAcCharge
                                                  .toString()) <
                                              double.parse(controller
                                                  .nonAcPerKmRate.value.text)) {
                                            ShowToastDialog.showToast(
                                              "${"Maximum allowed value is".tr} ${controller.selectedServiceType.value.nonAcCharge.toString()} ${"Please enter a lower Non A/c value.".tr}"
                                                  .tr,
                                            );
                                            return;
                                          } else {
                                            controller.saveDetails();
                                          }
                                        } else if (controller
                                                .selectedServiceType
                                                .value
                                                .isAcNonAc ==
                                            false) {
                                          if (controller.acNonAcWithoutPerKmRate
                                              .value.text.isEmpty) {
                                            ShowToastDialog.showToast(
                                              "Please enter  Per Km Rate".tr,
                                            );
                                            return;
                                          } else if (double.parse(controller
                                                  .selectedServiceType
                                                  .value
                                                  .kmCharge
                                                  .toString()) <
                                              double.parse(controller
                                                  .acNonAcWithoutPerKmRate
                                                  .value
                                                  .text)) {
                                            ShowToastDialog.showToast(
                                              "${"Maximum allowed value is".tr} ${controller.selectedServiceType.value.kmCharge.toString()} ${"Please enter a lower price.".tr}"
                                                  .tr,
                                            );
                                            return;
                                          } else {
                                            controller.saveDetails();
                                          }
                                        } else {
                                          controller.saveDetails();
                                        }
                                      },
                                    )),
                                const SizedBox(
                                  height: 20,
                                ),
                                Text(
                                    "You can not change once you select one service type if you want to change please contact to administrator"
                                        .tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins()),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  zoneDialog(BuildContext context, VehicleInformationController controller) {
    Widget cancelButton = TextButton(
      child: Text(
        "Cancel".tr,
        style: TextStyle(color: AppColors.primary),
      ),
      onPressed: () {
        Get.back();
      },
    );
    Widget continueButton = TextButton(
      child: Text("Continue".tr),
      onPressed: () {
        if (controller.selectedZone.isEmpty) {
          ShowToastDialog.showToast("Please select zone".tr);
        } else {
          String nameValue = "";
          for (var element in controller.selectedZone) {
            List<ZoneModel> list =
                controller.zoneList.where((p0) => p0.id == element).toList();
            if (list.isNotEmpty) {
              nameValue =
                  "$nameValue${nameValue.isEmpty ? "" : ","} ${Constant.localizationName(list.first.name)}";
            }
          }
          controller.zoneNameController.value.text = nameValue;
          Get.back();
        }
      },
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Zone list'.tr),
            content: SizedBox(
              width: Responsive.width(90, context),
              // Change as per your requirement
              child: controller.zoneList.isEmpty
                  ? Container()
                  : Obx(
                      () => ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.zoneList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Obx(
                            () => CheckboxListTile(
                              value: controller.selectedZone
                                  .contains(controller.zoneList[index].id),
                              onChanged: (value) {
                                if (controller.selectedZone
                                    .contains(controller.zoneList[index].id)) {
                                  controller.selectedZone.remove(controller
                                      .zoneList[index].id); // unselect
                                } else {
                                  controller.selectedZone.add(
                                      controller.zoneList[index].id); // select
                                }
                              },
                              activeColor: AppColors.primary,
                              title: Text(Constant.localizationName(
                                  controller.zoneList[index].name)),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            actions: [
              cancelButton,
              continueButton,
            ],
          );
        });
  }

  void showTooltip(BuildContext context, String message) {
    final themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
    if (tooltip?.isOpen ?? false) return;

    tooltip = SuperTooltip(
      popupDirection: TooltipDirection.up,
      arrowTipDistance: 8.0,
      arrowBaseWidth: 20.0,
      arrowLength: 10.0,
      borderRadius: 12.0,
      hasShadow: true,
      touchThroughAreaShape: ClipAreaShape.rectangle,
      content: Text(
        message,
        style: TextStyle(
            color: themeChange.getThem() ? Colors.black : Colors.white,
            fontSize: 13),
        textAlign: TextAlign.right,
      ),
      backgroundColor:
          themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
    );

    tooltip!.show(context);
  }
}
