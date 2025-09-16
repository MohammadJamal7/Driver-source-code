import 'dart:developer' as dev;
import 'dart:math';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/active_order_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/order_model.dart';
import 'package:driver/model/user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/ui/chat_screen/chat_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/widget/location_view.dart';
import 'package:driver/widget/user_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../utils/ride_utils.dart';
 

class ActiveOrderScreen extends StatelessWidget {
  const ActiveOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetBuilder<ActiveOrderController>(
        init: ActiveOrderController(),
        builder: (controller) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(CollectionName.orders)
                .where('driverId', isEqualTo: FireStoreUtils.getCurrentUid())
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                dev.log('❌ StreamBuilder Error: ${snapshot.error}');
                return Text('Something went wrong'.tr);
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Constant.loader(context);
              }
              if (snapshot.data == null) {
                dev.log('⚠️ Snapshot data is null');
                return Center(child: Text("No active rides Found".tr));
              }
              
              // Filter documents by status in app code
              final activeOrders = snapshot.data!.docs.where((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'];
                  dev.log('📋 Order ${doc.id} has status: $status');
                  return status == Constant.rideInProgress || status == Constant.rideActive;
                } catch (e) {
                  dev.log('❌ Error processing document ${doc.id}: $e');
                  return false;
                }
              }).toList();
              
              dev.log('📊 Found ${activeOrders.length} active orders out of ${snapshot.data!.docs.length} total orders');
              
              return activeOrders.isEmpty
                  ? Center(
                      child: Text("No active rides Found".tr),
                    )
                  : ListView.builder(
                      itemCount: activeOrders.length,
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        OrderModel orderModel = OrderModel.fromJson(
                            activeOrders[index].data()
                                as Map<String, dynamic>);

                        // Debug: Track order status changes
                        dev.log(
                            "📋 StreamBuilder received order: ${orderModel.id} with status: ${orderModel.status}");
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8), // Reduced from 10 to 8
                              child: Column(
                                children: [
                                  UserView(
                                    userId: orderModel.userId,
                                    amount: orderModel.finalRate,
                                    distance: orderModel.distance,
                                    distanceType: orderModel.distanceType,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 5),
                                    child: Divider(),
                                  ),
                                  LocationView(
                                    sourceLocation: orderModel
                                        .sourceLocationName
                                        .toString(),
                                    destinationLocation: orderModel
                                        .destinationLocationName
                                        .toString(),
                                  ),
                                  MapPreviewWidget(
                                    key: ValueKey(
                                        'map_${orderModel.id}_${orderModel.status}'),
                                    controller: controller,
                                    orderModel: orderModel,
                                  ),
                                  const SizedBox(
                                    height:
                                        8, // Reduced from 10 to 8 to fix overflow
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: orderModel.status ==
                                                Constant.rideInProgress
                                            ? ButtonThem.buildBorderButton(
                                                context,
                                                title: "Complete Ride".tr,
                                                btnHeight: 44,
                                                iconVisibility: false,
                                                
                                                onPress: () async {
                                                  orderModel.status =
                                                      Constant.rideComplete;
                                                  dev.log("1");
                                                  await FireStoreUtils
                                                          .getCustomer(
                                                              orderModel.userId
                                                                  .toString())
                                                      .then((value) async {
                                                    if (value != null) {
                                                      if (value.fcmToken !=
                                                          null) {
                                                        Map<String, dynamic>
                                                            playLoad =
                                                            <String, dynamic>{
                                                          "type":
                                                              "city_order_complete",
                                                          "orderId":
                                                              orderModel.id
                                                        };
                                                        await SendNotification
                                                            .sendOneNotification(
                                                                token: value.fcmToken
                                                                    .toString(),
                                                                title:
                                                                    'Ride complete!'
                                                                        .tr,
                                                                body:
                                                                    'Please complete your payment.'
                                                                        .tr,
                                                                payload:
                                                                    playLoad);
                                                      }
                                                    }
                                                  });
                                                  await FireStoreUtils.setOrder(
                                                          orderModel)
                                                      .then((value) {
                                                    if (value == true) {
                                                      ShowToastDialog.showToast(
                                                          "Ride Complete successfully"
                                                              .tr);
                                                      // Use the old working approach - change tab directly
                                                      dev.log(
                                                          "🔍 Before tab change: selectedIndex = ${controller.homeController.selectedIndex.value}");
                                                      controller
                                                          .homeController
                                                          .selectedIndex
                                                          .value = 3;
                                                      dev.log(
                                                          "✅ Changed to Completed Orders tab (index 3)");
                                                      dev.log(
                                                          "🔍 After tab change: selectedIndex = ${controller.homeController.selectedIndex.value}");

                                                      // Force UI update
                                                      controller.homeController
                                                          .update();
                                                    }
                                                  });
                                                  // Remove duplicate navigation call
                                                },
                                              )
                                            : ButtonThem.buildBorderButton(
                                                context,
                                                title: "Pickup Customer".tr,
                                                btnHeight: 44,
                                                iconVisibility: false,
                                                
                                                onPress: () async {
                                                  // Ensure controller is still valid before showing dialog
                                                  if (controller
                                                          .otpController !=
                                                      null) {
                                                    controller.otpController!
                                                        .clear();
                                                    showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                                context) =>
                                                            otpDialog(
                                                                context,
                                                                controller,
                                                                orderModel));
                                                  } else {
                                                    dev.log(
                                                        "❌ OTP Controller is null, reinitializing...");
                                                    controller.otpController =
                                                        TextEditingController();
                                                    showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                                context) =>
                                                            otpDialog(
                                                                context,
                                                                controller,
                                                                orderModel));
                                                  }
                                                },
                                              ),
                                      ),
                                      const SizedBox(
                                        width:
                                            6, // Reduced from 8 to 6 to fix overflow
                                      ),
                                      // Action buttons container
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth:
                                              96, // Reduced from 100 to 96
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () async {
                                                UserModel? customer =
                                                    await FireStoreUtils
                                                        .getCustomer(orderModel
                                                            .userId
                                                            .toString());
                                                DriverUserModel? driver =
                                                    await FireStoreUtils
                                                        .getDriverProfile(
                                                            orderModel.driverId
                                                                .toString());

                                                Get.to(ChatScreens(
                                                  driverId: driver!.id,
                                                  customerId: customer!.id,
                                                  customerName:
                                                      customer.fullName,
                                                  customerProfileImage:
                                                      customer.profilePic,
                                                  driverName: driver.fullName,
                                                  driverProfileImage:
                                                      driver.profilePic,
                                                  orderId: orderModel.id,
                                                  token: customer.fcmToken,
                                                ));
                                              },
                                              child: Container(
                                                height: 44,
                                                width: 44,
                                                decoration: BoxDecoration(
                                                    color: AppColors.darkModePrimary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                child: Icon(
                                                  Icons.chat,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 6, // Reduced from 8 to 6
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                UserModel? customer =
                                                    await FireStoreUtils
                                                        .getCustomer(orderModel
                                                            .userId
                                                            .toString());
                                                Constant.makePhoneCall(
                                                    "${customer!.countryCode}${customer.phoneNumber}");
                                              },
                                              child: Container(
                                                height: 44,
                                                width: 44,
                                                decoration: BoxDecoration(
                                                    color: AppColors.darkModePrimary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                child: Icon(
                                                  Icons.call,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  // Hide external directions button per requirement
                                  const SizedBox.shrink(),

                                  SizedBox(
                                    height: 10,
                                  ),

                                  // cancel button
                                  if (orderModel.status == Constant.rideActive)
                                    ButtonThem.buildBorderButton(
                                      context,
                                      color: Colors.red,
                                      title: "Cancel".tr,
                                      btnHeight: 44,
                                      onPress: () => RideUtils()
                                          .showCancelationBottomsheet(
                                        context,
                                        orderModel: orderModel,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      });
            },
          );
        });
  }

  otpDialog(BuildContext context, ActiveOrderController controller,
      OrderModel orderModel) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: OtpDialogWidget(
        controller: controller,
        orderModel: orderModel,
      ),
    );
  }
}

// Separate StatefulWidget for OTP Dialog to properly manage TextEditingController
class OtpDialogWidget extends StatefulWidget {
  final ActiveOrderController controller;
  final OrderModel orderModel;

  const OtpDialogWidget({
    super.key,
    required this.controller,
    required this.orderModel,
  });

  @override
  State<OtpDialogWidget> createState() => _OtpDialogWidgetState();
}

class _OtpDialogWidgetState extends State<OtpDialogWidget> {
  late TextEditingController localOtpController;

  @override
  void initState() {
    super.initState();
    localOtpController = TextEditingController();
    dev.log("🔧 Created local OTP controller for dialog");
  }

  @override
  void dispose() {
    try {
      if (mounted) {
        localOtpController.dispose();
        dev.log("✅ Local OTP controller disposed safely");
      }
    } catch (e) {
      dev.log("⚠️ Error disposing local OTP controller: $e");
      // Continue with disposal even if controller disposal fails
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 10,
          ),
          Text("OTP verify from customer".tr,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: PinCodeTextField(
              length: 6,
              appContext: context,
              keyboardType: TextInputType.phone,
              pinTheme: PinTheme(
                fieldHeight: 40,
                fieldWidth: 40,
                activeColor: themeChange.getThem()
                    ? AppColors.darkTextFieldBorder
                    : AppColors.textFieldBorder,
                selectedColor: themeChange.getThem()
                    ? AppColors.darkTextFieldBorder
                    : AppColors.textFieldBorder,
                inactiveColor: themeChange.getThem()
                    ? AppColors.darkTextFieldBorder
                    : AppColors.textFieldBorder,
                activeFillColor: themeChange.getThem()
                    ? AppColors.darkTextField
                    : AppColors.textField,
                inactiveFillColor: themeChange.getThem()
                    ? AppColors.darkTextField
                    : AppColors.textField,
                selectedFillColor: themeChange.getThem()
                    ? AppColors.darkTextField
                    : AppColors.textField,
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
              ),
              enableActiveFill: true,
              cursorColor: AppColors.primary,
              controller: localOtpController, // Use local controller
              onCompleted: (v) async {
                dev.log("🔢 OTP completed: $v");
              },
              onChanged: (value) {
                dev.log("🔢 OTP changed: $value");
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          ButtonThem.buildButton(context, title: "OTP verify".tr, textColor: Colors.black,
              onPress: () async {
            // Safely get OTP text from local controller
            String enteredOtp = "";
            try {
              enteredOtp = localOtpController.text;
              dev.log("🔢 Retrieved OTP from local controller: $enteredOtp");
            } catch (e) {
              dev.log("❌ Error accessing local OTP controller: $e");
              ShowToastDialog.showToast("Error accessing OTP field".tr);
              return;
            }

            if (widget.orderModel.otp.toString() == enteredOtp) {
              // Don't manually dispose here - let the widget's dispose() method handle it
              dev.log(
                  "✅ OTP verified! Closing dialog and letting widget dispose controller naturally");

              Get.back();
              ShowToastDialog.showLoader("Please wait".tr);

              // Debug: Log status change
              dev.log(
                  "🔄 OTP verified! Changing status from ${widget.orderModel.status} to ${Constant.rideInProgress}");
              widget.orderModel.status = Constant.rideInProgress;

              await FireStoreUtils.getCustomer(
                      widget.orderModel.userId.toString())
                  .then((value) async {
                if (value != null) {
                  await SendNotification.sendOneNotification(
                      token: value.fcmToken.toString(),
                      title: 'Ride Started'.tr,
                      body:
                          'The ride has officially started. Please follow the designated route to the destination.'
                              .tr,
                      payload: {});
                }
              });

              await FireStoreUtils.setOrder(widget.orderModel).then((value) {
                if (value == true) {
                  ShowToastDialog.closeLoader();
                  ShowToastDialog.showToast("Customer pickup successfully".tr);

                  // Debug: Confirm Firestore update
                  dev.log(
                      "✅ Order status successfully updated in Firestore to: ${widget.orderModel.status}");
                  dev.log(
                      "🔄 StreamBuilder should receive updated data and rebuild MapPreviewWidget");
                } else {
                  dev.log("❌ Failed to update order status in Firestore");
                }
              });
            } else {
              ShowToastDialog.showToast(
                "OTP Invalid".tr,
              );
              // Don't dispose controller here - user might try again
              dev.log("❌ Invalid OTP entered, keeping dialog open");
            }
          }),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}

// Separate StatefulWidget for map preview
class MapPreviewWidget extends StatefulWidget {
  final OrderModel orderModel;
  final ActiveOrderController controller;

  const MapPreviewWidget({
    super.key,
    required this.orderModel,
    required this.controller,
  });

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

// MapViewMode removed; map is always maximized now

class _MapPreviewWidgetState extends State<MapPreviewWidget>
    with WidgetsBindingObserver {
  Set<Polyline> polylines = {};
  bool isLoadingPolyline = false;
  GoogleMapController? mapController;
  Key _mapKey = UniqueKey();
  bool _mapReady = false;
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
  DriverUserModel? _driverModel;
  // Use dynamic to be compatible with connectivity_plus streams (single or list)
  StreamSubscription<dynamic>? _connSub;
  Set<Marker> markers = {};
  // Track previous and current driver positions for bearing calculation
  LatLng? _prevDriverLatLng;
  LatLng? _currDriverLatLng;
  
  // Controls visibility state
  bool _controlsVisible = true;
  
  // Auto-centering (follow mode) state
  bool _isFollowingDriver = true; // Start with follow mode enabled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Start listening to driver location updates
    _setupDriverLocationListener();
    
    // Listen to connectivity to recover when coming back online
    _connSub = Connectivity().onConnectivityChanged.listen((_) {
      if (mounted) {
        // When connectivity changes, try to rebuild the map and route
        setState(() {
          _mapKey = UniqueKey();
          _mapReady = false;
        });
        // Recreate route and camera after rebuild
        Future.delayed(const Duration(milliseconds: 300), () {
          _initializeRoute();
        });
      }
    });
    dev.log("🚀 MapPreviewWidget initState - Starting route creation");
    dev.log("📋 Order Status: ${widget.orderModel.status}");
    dev.log(
        "📍 Driver Location Available: ${Constant.currentLocation != null}");
    dev.log(
        "📍 Source Location Available: ${widget.orderModel.sourceLocationLAtLng != null}");
    dev.log(
        "📍 Destination Location Available: ${widget.orderModel.destinationLocationLAtLng != null}");

    _initializeRoute();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Force rebuild of GoogleMap after app resumes to avoid blank map/offline tile
      if (mounted) {
        setState(() {
          _mapKey = UniqueKey();
          _mapReady = false;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          _initializeRoute();
          _updateCameraBounds();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    _driverLocationSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the order status has changed
    if (oldWidget.orderModel.status != widget.orderModel.status) {
      dev.log(
          "🔄 Order status changed from ${oldWidget.orderModel.status} to ${widget.orderModel.status}");
      dev.log("🗺️ Updating map route for new status");

      // Update the route when status changes
      _initializeRoute();
    }
  }

  // Set up real-time driver location listener
  void _setupDriverLocationListener() {
    if (widget.orderModel.driverId == null) {
      dev.log("⚠️ No driver ID available for location tracking");
      return;
    }
    
    dev.log("🔄 Setting up real-time driver location listener");
    _driverLocationSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.driverUsers)
        .doc(widget.orderModel.driverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final newDriverModel = DriverUserModel.fromJson(snapshot.data()!);
        
        // Check if location actually changed to avoid unnecessary updates
        if (_driverModel == null || 
            _driverModel!.location?.latitude != newDriverModel.location?.latitude ||
            _driverModel!.location?.longitude != newDriverModel.location?.longitude) {
          final LatLng? newLatLng = (newDriverModel.location?.latitude != null &&
                  newDriverModel.location?.longitude != null)
              ? LatLng(newDriverModel.location!.latitude!.toDouble(),
                  newDriverModel.location!.longitude!.toDouble())
              : null;

          setState(() {
            _prevDriverLatLng = _currDriverLatLng;
            _currDriverLatLng = newLatLng;
            _driverModel = newDriverModel;
          });
          
          dev.log("🚗 Driver location updated: ${_driverModel?.location?.latitude}, ${_driverModel?.location?.longitude}");
          
          // Update route with new driver location
          _createRoutePolyline();
          
          // If map is already showing and follow mode is enabled, update camera to follow driver
          if (mapController != null && _mapReady) {
            if (_isFollowingDriver) {
              _centerOnDriver(); // Center directly on driver if in follow mode
            } else {
              _updateCameraBounds(); // Otherwise just update the bounds
            }
          }
        }
      }
    }, onError: (error) {
      dev.log("❌ Error in driver location listener: $error");
    });
  }

  // Calculate compass bearing from point A to B in degrees
  double _calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * pi / 180.0;
    final double lon1 = from.longitude * pi / 180.0;
    final double lat2 = to.latitude * pi / 180.0;
    final double lon2 = to.longitude * pi / 180.0;
    final double dLon = lon2 - lon1;

    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double brng = atan2(y, x);
    brng = brng * 180.0 / pi;
    return (brng + 360.0) % 360.0;
  }

  void _initializeRoute() {
    // Create a simple fallback route immediately
    _createSimpleRoute();
    // Then try to create the detailed route
    _createRoutePolyline();

    // Update camera bounds after a short delay to ensure polylines are created
    Future.delayed(const Duration(milliseconds: 1000), () {
      _updateCameraBounds();
    });
  }

  void _updateCameraBounds() {
    // Enhanced safety checks to prevent platform channel errors
    if (mapController == null || !mounted) {
      dev.log(
          "⚠️ Skipping camera update - controller null or widget not mounted");
      return;
    }

    try {
      // Calculate new bounds based on current status
      LatLng? driverLocation;
      // Use real-time driver location from Firestore if available, otherwise fall back to Constant
      if (_driverModel?.location != null) {
        driverLocation = LatLng(
          _driverModel!.location!.latitude!.toDouble(),
          _driverModel!.location!.longitude!.toDouble(),
        );
        dev.log("📍 Using real-time driver location from Firestore");
      } else if (Constant.currentLocation != null) {
        driverLocation = LatLng(
          Constant.currentLocation!.latitude!.toDouble(),
          Constant.currentLocation!.longitude!.toDouble(),
        );
        dev.log("📍 Using fallback Constant.currentLocation");
      }

      LatLng? targetLocation;
      if (widget.orderModel.status == Constant.rideInProgress) {
        // Target is destination
        if (widget.orderModel.destinationLocationLAtLng != null) {
          targetLocation = LatLng(
            widget.orderModel.destinationLocationLAtLng!.latitude!.toDouble(),
            widget.orderModel.destinationLocationLAtLng!.longitude!.toDouble(),
          );
        }
      } else {
        // Target is pickup
        if (widget.orderModel.sourceLocationLAtLng != null) {
          targetLocation = LatLng(
            widget.orderModel.sourceLocationLAtLng!.latitude!.toDouble(),
            widget.orderModel.sourceLocationLAtLng!.longitude!.toDouble(),
          );
        }
      }

      if (driverLocation != null && targetLocation != null && mounted) {
        LatLngBounds bounds =
            _calculateBounds([driverLocation, targetLocation]);

        // Additional safety check before camera animation
        if (mapController != null && mounted) {
          mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 20.0),
          );
          dev.log(
              "🎯 Camera bounds updated for status: ${widget.orderModel.status}");
        }
      }
    } catch (e) {
      dev.log("❌ Error updating camera bounds: $e");
      // Don't rethrow - just log and continue
    }
  }

  // Create a simple straight line route as fallback
  void _createSimpleRoute() {
    try {
      LatLng? sourceLocation;
      if (widget.orderModel.sourceLocationLAtLng != null) {
        double? sourceLat = widget.orderModel.sourceLocationLAtLng!.latitude;
        double? sourceLng = widget.orderModel.sourceLocationLAtLng!.longitude;
        if (sourceLat != null && sourceLng != null) {
          sourceLocation = LatLng(sourceLat.toDouble(), sourceLng.toDouble());
        }
      }

      LatLng? destinationLocation;
      if (widget.orderModel.destinationLocationLAtLng != null) {
        double? destLat = widget.orderModel.destinationLocationLAtLng!.latitude;
        double? destLng =
            widget.orderModel.destinationLocationLAtLng!.longitude;
        if (destLat != null && destLng != null) {
          destinationLocation = LatLng(destLat.toDouble(), destLng.toDouble());
        }
      }

      LatLng? driverLocation;
      if (Constant.currentLocation != null) {
        double? driverLat = Constant.currentLocation!.latitude;
        double? driverLng = Constant.currentLocation!.longitude;
        if (driverLat != null && driverLng != null) {
          driverLocation = LatLng(driverLat.toDouble(), driverLng.toDouble());
        }
      }

      if (driverLocation != null &&
          sourceLocation != null &&
          destinationLocation != null) {
        LatLng startPoint, endPoint;
        if (widget.orderModel.status == Constant.rideInProgress) {
          startPoint = driverLocation;
          endPoint = destinationLocation;
        } else {
          startPoint = driverLocation;
          endPoint = sourceLocation;
        }

        if (mounted) {
          setState(() {
            polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: [startPoint, endPoint],
                color: Colors.black,
                width: 5, // Increased width for better visibility
                geodesic: true,
                patterns: [], // Solid line
              ),
            };
          });
        }
        dev.log(
            "🔄 Simple route created as fallback with ${polylines.length} polylines");
      }
    } catch (e) {
      dev.log("❌ Error creating simple route: $e");
    }
  }

  // Zoom in method
  void _zoomIn() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.zoomIn(),
      );
      // Disable follow mode when user manually zooms
      setState(() {
        _isFollowingDriver = false;
      });
      dev.log("🔍 Zoomed in - follow mode disabled");
    }
  }

  // Zoom out method
  void _zoomOut() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.zoomOut(),
      );
      // Disable follow mode when user manually zooms
      setState(() {
        _isFollowingDriver = false;
      });
      dev.log("🔍 Zoomed out - follow mode disabled");
    }
  }

  // Recenter method to fit current route bounds and enable follow mode
  void _recenter() {
    dev.log("🔄 Recenter tapped - centering on driver location with follow mode");
    // Enable follow mode
    setState(() {
      _isFollowingDriver = true;
    });
    // Center directly on driver
    _centerOnDriver();
  }
  
  // Center map directly on driver's current location
  void _centerOnDriver() {
    if (mapController == null || !mounted) {
      dev.log("⚠️ Cannot center on driver - controller null or widget not mounted");
      return;
    }
    
    try {
      // Use real-time driver location from Firestore if available
      if (_driverModel?.location != null) {
        final lat = _driverModel!.location!.latitude;
        final lng = _driverModel!.location!.longitude;
        if (lat != null && lng != null) {
          final driver = LatLng(lat.toDouble(), lng.toDouble());
          mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: driver, 
                zoom: 16.0, // Higher zoom for better visibility of driver
                tilt: 0.0,
                bearing: 0.0,
              ),
            ),
          );
          dev.log("📍 Centered on real-time driver location from Firestore");
          return;
        }
      } 
      // Fall back to Constant.currentLocation if Firestore data unavailable
      else if (Constant.currentLocation != null) {
        final lat = Constant.currentLocation!.latitude;
        final lng = Constant.currentLocation!.longitude;
        if (lat != null && lng != null) {
          final driver = LatLng(lat.toDouble(), lng.toDouble());
          mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: driver, 
                zoom: 16.0,
                tilt: 0.0,
                bearing: 0.0,
              ),
            ),
          );
          dev.log("📍 Centered on fallback Constant.currentLocation");
          return;
        }
      }
      // Fallback: fit current bounds
      _updateCameraBounds();
      dev.log("⚠️ No driver location available, using camera bounds instead");
    } catch (e) {
      dev.log("❌ Error during center on driver: $e");
      _updateCameraBounds();
    }
  }

  // Create custom small circle marker
  BitmapDescriptor _createSmallCircleMarker(Color color) {
    return BitmapDescriptor.defaultMarkerWithHue(
      color == Colors.red
          ? BitmapDescriptor.hueRed
          : color == Colors.green
              ? BitmapDescriptor.hueGreen
              : color == Colors.blue
                  ? BitmapDescriptor.hueBlue
                  : BitmapDescriptor.hueRed,
    );
  }

  Future<void> _createRoutePolyline() async {
    if (!mounted) return;
    setState(() {
      isLoadingPolyline = true;
    });

    try {
      // Get coordinates
      LatLng? sourceLocation;
      if (widget.orderModel.sourceLocationLAtLng != null) {
        double? sourceLat = widget.orderModel.sourceLocationLAtLng!.latitude;
        double? sourceLng = widget.orderModel.sourceLocationLAtLng!.longitude;
        if (sourceLat != null && sourceLng != null) {
          sourceLocation = LatLng(sourceLat.toDouble(), sourceLng.toDouble());
        }
      }

      LatLng? destinationLocation;
      if (widget.orderModel.destinationLocationLAtLng != null) {
        double? destLat = widget.orderModel.destinationLocationLAtLng!.latitude;
        double? destLng =
            widget.orderModel.destinationLocationLAtLng!.longitude;
        if (destLat != null && destLng != null) {
          destinationLocation = LatLng(destLat.toDouble(), destLng.toDouble());
        }
      }

      LatLng? driverLocation;
      if (Constant.currentLocation != null) {
        double? driverLat = Constant.currentLocation!.latitude;
        double? driverLng = Constant.currentLocation!.longitude;
        if (driverLat != null && driverLng != null) {
          driverLocation = LatLng(driverLat.toDouble(), driverLng.toDouble());
        }
      }

      if (sourceLocation == null ||
          destinationLocation == null ||
          driverLocation == null) {
        dev.log("❌ Missing location data for polyline");
        return;
      }

      // Determine route based on ride status
      LatLng startPoint, endPoint;
      if (widget.orderModel.status == Constant.rideInProgress) {
        // If ride is in progress, show route from driver to destination
        startPoint = driverLocation;
        endPoint = destinationLocation;
        dev.log("🛣️ Creating route: Driver → Destination");
      } else {
        // If ride is active, show route from driver to pickup
        startPoint = driverLocation;
        endPoint = sourceLocation;
        dev.log("🛣️ Creating route: Driver → Pickup");
      }

      dev.log("📍 Start: ${startPoint.latitude}, ${startPoint.longitude}");
      dev.log("📍 End: ${endPoint.latitude}, ${endPoint.longitude}");

      // Create polyline using Google Directions API
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineRequest polylineRequest = PolylineRequest(
        origin: PointLatLng(startPoint.latitude, startPoint.longitude),
        destination: PointLatLng(endPoint.latitude, endPoint.longitude),
        mode: TravelMode.driving,
      );

      dev.log("🔑 Using API Key: ${Constant.mapAPIKey}");
      dev.log("🚀 Making API request for route...");

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: Constant.mapAPIKey,
        request: polylineRequest,
      );

      dev.log("📡 API Response Status: ${result.status}");
      dev.log("📊 API Points Count: ${result.points.length}");

      if (result.points.isNotEmpty && result.status == 'OK') {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        dev.log(
            "✅ API Route created with ${polylineCoordinates.length} points");

        if (mounted) {
          setState(() {
            polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylineCoordinates,
                color: Colors.black,
                width: 5, // Increased width for better visibility
                geodesic: true,
                patterns: [], // Solid line
              ),
            };
          });
        }
        dev.log("🎨 Polyline set with ${polylines.length} polylines");
      } else {
        // Fallback to straight line if API fails
        dev.log(
            "⚠️ API failed (Status: ${result.status}), using fallback straight line");
        if (mounted) {
          setState(() {
            polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: [startPoint, endPoint],
                color: Colors.black,
                width: 5, // Increased width for better visibility
                geodesic: true,
                patterns: [], // Solid line
              ),
            };
          });
        }
        dev.log("🎨 Fallback polyline set with ${polylines.length} polylines");
      }
    } catch (e) {
      // Fallback to straight line if API fails
      dev.log("❌ Error creating polyline: $e");

      LatLng? driverLocation;
      LatLng? sourceLocation;
      LatLng? destinationLocation;

      if (Constant.currentLocation != null) {
        double? driverLat = Constant.currentLocation!.latitude;
        double? driverLng = Constant.currentLocation!.longitude;
        if (driverLat != null && driverLng != null) {
          driverLocation = LatLng(driverLat.toDouble(), driverLng.toDouble());
        }
      }

      if (widget.orderModel.sourceLocationLAtLng != null) {
        double? sourceLat = widget.orderModel.sourceLocationLAtLng!.latitude;
        double? sourceLng = widget.orderModel.sourceLocationLAtLng!.longitude;
        if (sourceLat != null && sourceLng != null) {
          sourceLocation = LatLng(sourceLat.toDouble(), sourceLng.toDouble());
        }
      }

      if (widget.orderModel.destinationLocationLAtLng != null) {
        double? destLat = widget.orderModel.destinationLocationLAtLng!.latitude;
        double? destLng =
            widget.orderModel.destinationLocationLAtLng!.longitude;
        if (destLat != null && destLng != null) {
          destinationLocation = LatLng(destLat.toDouble(), destLng.toDouble());
        }
      }

      if (driverLocation != null &&
          sourceLocation != null &&
          destinationLocation != null) {
        LatLng startPoint, endPoint;
        if (widget.orderModel.status == Constant.rideInProgress) {
          startPoint = driverLocation;
          endPoint = destinationLocation;
        } else {
          startPoint = driverLocation;
          endPoint = sourceLocation;
        }

        dev.log("🔄 Creating fallback straight line route");
        if (mounted) {
          setState(() {
            polylines = {
              Polyline(
                polylineId: const PolylineId('route'),
                points: [startPoint, endPoint],
                color: Colors.black,
                width: 5, // Increased width for better visibility
                geodesic: true,
                patterns: [], // Solid line
              ),
            };
          });
        }
        dev.log(
            "🎨 Exception fallback polyline set with ${polylines.length} polylines");
      } else {
        dev.log("❌ Cannot create fallback route - missing location data");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingPolyline = false;
        });
      }
      dev.log("🏁 Polyline creation completed");
    }
  }

  @override
  Widget build(BuildContext context) {
    dev.log(
        "🏗️ MapPreviewWidget build() called with status: ${widget.orderModel.status}");

    // Check if marker icons are loaded
    if (widget.controller.isLoadingIcons) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 6), // Reduced from 8 to 6
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Loading map...'),
            ],
          ),
        ),
      );
    }

    // Check if icons are available
    if (!widget.controller.areIconsLoaded) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 6), // Reduced from 8 to 6
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Map unavailable'),
            ],
          ),
        ),
      );
    }

    // Get coordinates with proper null checks
    LatLng? sourceLocation;
    if (widget.orderModel.sourceLocationLAtLng != null) {
      double? sourceLat = widget.orderModel.sourceLocationLAtLng!.latitude;
      double? sourceLng = widget.orderModel.sourceLocationLAtLng!.longitude;
      if (sourceLat != null && sourceLng != null) {
        sourceLocation = LatLng(sourceLat.toDouble(), sourceLng.toDouble());
      }
    }

    LatLng? destinationLocation;
    if (widget.orderModel.destinationLocationLAtLng != null) {
      double? destLat = widget.orderModel.destinationLocationLAtLng!.latitude;
      double? destLng = widget.orderModel.destinationLocationLAtLng!.longitude;
      if (destLat != null && destLng != null) {
        destinationLocation = LatLng(destLat.toDouble(), destLng.toDouble());
      }
    }

    LatLng? driverLocation;
    if (Constant.currentLocation != null) {
      double? driverLat = Constant.currentLocation!.latitude;
      double? driverLng = Constant.currentLocation!.longitude;
      if (driverLat != null && driverLng != null) {
        driverLocation = LatLng(driverLat.toDouble(), driverLng.toDouble());
      }
    }

    // Validate coordinates
    if (sourceLocation == null ||
        destinationLocation == null ||
        driverLocation == null) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 6), // Reduced from 8 to 6
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Location data unavailable'),
            ],
          ),
        ),
      );
    }

    // Create markers for pickup/destination and driver car icon (keep native blue dot)
    Set<Marker> markers = {};

    // Dynamic destination marker based on ride status
    if (widget.orderModel.status == Constant.rideInProgress) {
      // Show destination marker when ride is in progress
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destinationLocation,
        icon: widget.controller.destinationIcon!, // Using destination icon
        infoWindow: InfoWindow(
          title: 'Drop-off Location',
          snippet: widget.orderModel.destinationLocationName ?? 'Destination',
        ),
      ));
      dev.log("🗺️ Showing Driver + Destination markers (ride in progress)");
    } else {
      // Show pickup marker when ride is active (going to pickup)
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: sourceLocation,
        icon: widget.controller.pickupIcon!, // Using pickup icon
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.orderModel.sourceLocationName ?? 'Pickup',
        ),
      ));
      dev.log("🗺️ Showing Driver + Pickup markers (going to pickup)");
    }

    // Add driver's car marker with correct rotation
    double rotation = 0.0;
    if (_driverModel?.rotation != null) {
      rotation = (_driverModel!.rotation ?? 0.0).toDouble();
    } else if (_prevDriverLatLng != null && _currDriverLatLng != null) {
      rotation = _calculateBearing(_prevDriverLatLng!, _currDriverLatLng!);
    }
    markers.add(Marker(
      markerId: const MarkerId('driver'),
      position: driverLocation,
      icon: widget.controller.driverIcon!,
      rotation: rotation,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      zIndex: 2.0,
    ));

    // Calculate bounds dynamically based on ride status
    List<LatLng> routePoints = [driverLocation];

    if (widget.orderModel.status == Constant.rideInProgress) {
      // Show route to destination when ride is in progress
      routePoints.add(destinationLocation);
      dev.log("🗺️ Focusing on Driver → Destination route (ride in progress)");
    } else {
      // Show route to pickup when ride is active
      routePoints.add(sourceLocation);
      dev.log("🗺️ Focusing on Driver → Pickup route (going to pickup)");
    }

    LatLngBounds bounds = _calculateBounds(routePoints);

    // Debug polylines
    dev.log("🎨 Build method - Polylines count: ${polylines.length}");
    if (polylines.isNotEmpty) {
      for (var polyline in polylines) {
        dev.log(
            "🎨 Polyline ID: ${polyline.polylineId.value}, Points: ${polyline.points.length}, Color: ${polyline.color}, Width: ${polyline.width}");
      }
    }

    // Container is no longer draggable; always render maximized map
    return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // Always show the map in maximized height (previously expanded state)
        height: MediaQuery.of(context).size.height * 0.7,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: <Widget>[
            GoogleMap(
              key: _mapKey,
              initialCameraPosition: CameraPosition(
                target: _calculateCenter(bounds),
                zoom: 15, // Higher zoom for tight focus on driver and pickup
              ),
              // Ensure the map captures gestures inside a scrollable parent (ListView)
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
              },
              markers: markers,
              polylines: polylines,
              zoomControlsEnabled: false, // We'll add custom zoom controls
              mapToolbarEnabled: true,
              myLocationButtonEnabled: true,
              myLocationEnabled: true, // Show native blue dot with accuracy circle
              compassEnabled: true,
              // Keep gestures enabled for map interaction; container itself is no longer draggable/expandable
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: true,
              liteModeEnabled: false,
              mapType: MapType.normal,
              onMapCreated: (GoogleMapController mapController) {
                this.mapController = mapController;
                _mapReady = true;
                dev.log(
                    "🗺️ Map created, fitting bounds with ${polylines.length} polylines");
                // Animate to fit the route with minimal padding for tight zoom
                Future.delayed(const Duration(milliseconds: 800), () {
                  // Enhanced safety checks to prevent platform channel errors
                  if (mounted && this.mapController != null && _mapReady) {
                    try {
                      // Use minimal padding to zoom in as close as possible
                      double padding = 20.0; // Minimal padding for tight zoom

                      mapController.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds, padding),
                      );

                      dev.log(
                          "🗺️ Camera animated with tight zoom, padding: $padding");
                    } catch (e) {
                      dev.log("❌ Error animating camera on map creation: $e");
                      // Don't rethrow - just log and continue
                    }
                  } else {
                    dev.log(
                        "⚠️ Skipping camera animation - widget disposed or controller null");
                  }
                });
              },
            ),
            // Map type toggle button
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Custom zoom controls
                    InkWell(
                      onTap: () {
                        // Zoom in
                        _zoomIn();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    InkWell(
                      onTap: () {
                        // Zoom out
                        _zoomOut();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.remove,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Removed view mode toggle; map is always maximized now
            
            // Toggle controls visibility button
            Positioned(
              left: 8,
              top: 8,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _controlsVisible = !_controlsVisible;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _controlsVisible ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            
            // Removed drag indicator; container is no longer draggable/expandable
            
            // Map type selector (always available since map is always maximized)
            if (true)
              Positioned(
                right: 50,
                top: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (mapController != null) {
                            // Change map type to normal
                            setState(() {
                              mapController!.setMapStyle(null); // Reset to default style
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: const Text('Normal'),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey.shade300,
                      ),
                      InkWell(
                        onTap: () {
                          if (mapController != null) {
                            // Apply terrain style using custom JSON
                            mapController!.setMapStyle('''[
                              {
                                "featureType": "landscape.natural",
                                "elementType": "geometry",
                                "stylers": [{"color": "#dde2e3"}, {"visibility": "on"}]
                              },
                              {
                                "featureType": "poi.park",
                                "elementType": "all",
                                "stylers": [{"color": "#c6e8b3"}, {"visibility": "on"}]
                              },
                              {
                                "featureType": "poi.park",
                                "elementType": "geometry.fill",
                                "stylers": [{"color": "#c6e8b3"}, {"visibility": "on"}]
                              }
                            ]''');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: const Text('Terrain'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Hide UI controls when not visible
            if (!_controlsVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _controlsVisible = true;
                    });
                  },
                ),
              ),
            
            // Show controls only when visible
            if (_controlsVisible)
              Positioned(
                right: 8,
                bottom: 8,
                child: InkWell(
                  onTap: () {
                    _recenter();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            if (isLoadingPolyline)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Calculate bounds that include all points with proper padding for route visibility
  LatLngBounds _calculateBounds(List<LatLng> positions) {
    if (positions.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = positions.map((p) => p.latitude).reduce(min);
    double maxLat = positions.map((p) => p.latitude).reduce(max);
    double minLng = positions.map((p) => p.longitude).reduce(min);
    double maxLng = positions.map((p) => p.longitude).reduce(max);

    // Calculate distance between points to determine appropriate padding
    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;

    // Use minimal padding to zoom in tight - locations should reach map borders
    double latPadding, lngPadding;

    if (latDiff < 0.005 && lngDiff < 0.005) {
      // Very close points - minimal padding to zoom in close
      latPadding = max(0.001, latDiff * 0.1);
      lngPadding = max(0.001, lngDiff * 0.1);
      dev.log("🗺️ Very close points - minimal padding for tight zoom");
    } else {
      // All other distances - very small padding to maximize zoom
      latPadding = max(0.0005, latDiff * 0.05);
      lngPadding = max(0.0005, lngDiff * 0.05);
      dev.log("🗺️ Normal distance - minimal padding for tight zoom");
    }

    dev.log(
        "🗺️ Bounds: LatDiff=$latDiff, LngDiff=$lngDiff, Padding=($latPadding, $lngPadding)");

    return LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  // Calculate center point of bounds
  LatLng _calculateCenter(LatLngBounds bounds) {
    return LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );
  }
}
