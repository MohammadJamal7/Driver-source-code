import 'dart:developer';
import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controller/login_controller.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/auth_screen/information_screen.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../controller/vehicle_information_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LoginController>(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 28,
                    color: Color(0xFF061711),
                  ),
                  Image.asset("assets/images/login_image.jpeg", width: Responsive.width(100, context)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text("Login".tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text("Welcome Back! We are happy to have \n you back".tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w400)),
                        ),
                        // const SizedBox(
                        //   height: 20,
                        // ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40),
                          child: Row(
                            children: [
                              const Expanded(
                                  child: Divider(
                                    thickness: 2,
                              )),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "تسجيل دخول بإستخدام",
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(
                                    thickness: 2,
                              )),
                            ],
                          ),
                        ),
                        Row(mainAxisAlignment: MainAxisAlignment.center,children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 16,
                                  offset: Offset(5, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Material(
                                color: Colors.white,
                                child: InkWell(
                                  onTap: () async {
                                    ShowToastDialog.showLoader("Please wait".tr);
                                    await controller.signInWithGoogle().then((value) async {
                                      ShowToastDialog.closeLoader();

                                      if (value == null || value.user == null) {
                                        ShowToastDialog.showToast("فشل تسجيل الدخول. حاول مرة أخرى.");
                                        return;
                                      }

                                      final user = value.user!;
                                      String uid = value.user?.uid ?? '';
                                      bool isUser = await FireStoreUtils.checkUserInCollection(uid, CollectionName.users);
                                      log(uid.toString());
                                      log(isUser.toString());
                                      if (isUser) {
                                        await FirebaseAuth.instance.signOut();
                                        ShowToastDialog.showToast("thisDriverAccount".tr);
                                        Get.offAll(const LoginScreen());
                                        return;
                                      }
                                      if (value.additionalUserInfo!.isNewUser) {
                                        log("----->new user");
                                        DriverUserModel userModel = DriverUserModel();
                                        userModel.id = user.uid;
                                        userModel.email = user.email;
                                        userModel.fullName = user.displayName;
                                        userModel.profilePic = user.photoURL;
                                        userModel.loginType = Constant.googleLoginType;
                                        if (!Get.isRegistered<VehicleInformationController>()) {
                                          Get.put(VehicleInformationController());
                                        }
                                        Get.find<VehicleInformationController>().getVehicleTye();

                                        Get.to(const InformationScreen(), arguments: {
                                          "userModel": userModel,
                                        });
                                      }
                                      else {
                                        log("----->old user");
                                        final exists = await FireStoreUtils.userExitOrNot(user.uid);
                                        if (exists) {
                                          if (!Get.isRegistered<VehicleInformationController>()) {
                                            Get.put(VehicleInformationController());
                                          }
                                          Get.find<VehicleInformationController>().getVehicleTye();
                                          // Get.to(const DashBoardScreen());
                                          Get.off(() => const DashBoardScreen());

                                        } else {
                                          DriverUserModel userModel = DriverUserModel();
                                          userModel.id = user.uid;
                                          userModel.email = user.email;
                                          userModel.fullName = user.displayName;
                                          userModel.profilePic = user.photoURL;
                                          userModel.loginType = Constant.googleLoginType;
                                          if (!Get.isRegistered<VehicleInformationController>()) {
                                            Get.put(VehicleInformationController());
                                          }
                                          Get.find<VehicleInformationController>().getVehicleTye();

                                          Get.to(const InformationScreen(), arguments: {
                                            "userModel": userModel,
                                          });
                                        }
                                      }
                                    });

                                    // ShowToastDialog.showLoader("Please wait".tr);
                                    // await controller
                                    //     .signInWithGoogle()
                                    //     .then((value) {
                                    //   ShowToastDialog.closeLoader();
                                    //   if (value != null) {
                                    //     if (value.additionalUserInfo!.isNewUser) {
                                    //       print("----->new user");
                                    //       UserModel userModel = UserModel();
                                    //       userModel.id = value.user!.uid;
                                    //       userModel.email = value.user!.email;
                                    //       userModel.fullName =
                                    //           value.user!.displayName;
                                    //       userModel.profilePic =
                                    //           value.user!.photoURL;
                                    //       userModel.loginType =
                                    //           Constant.googleLoginType;
                                    //
                                    //       ShowToastDialog.closeLoader();
                                    //       Get.to(const InformationScreen(),
                                    //           arguments: {
                                    //             "userModel": userModel,
                                    //           });
                                    //     } else {
                                    //       print("----->old user");
                                    //       FireStoreUtils.userExitOrNot(
                                    //           value.user!.uid)
                                    //           .then((userExit) async {
                                    //         ShowToastDialog.closeLoader();
                                    //         if (userExit == true) {
                                    //           UserModel? userModel =
                                    //           await FireStoreUtils
                                    //               .getUserProfile(
                                    //               value.user!.uid);
                                    //           if (userModel != null) {
                                    //             if (userModel.isActive == true) {
                                    //               Get.offAll(
                                    //                   const DashBoardScreen());
                                    //             } else {
                                    //               await FirebaseAuth.instance
                                    //                   .signOut();
                                    //               ShowToastDialog.showToast(
                                    //                   "This user is disable please contact administrator"
                                    //                       .tr);
                                    //             }
                                    //           }
                                    //         } else {
                                    //           UserModel userModel = UserModel();
                                    //           userModel.id = value.user!.uid;
                                    //           userModel.email = value.user!.email;
                                    //           userModel.fullName =
                                    //               value.user!.displayName;
                                    //           userModel.profilePic =
                                    //               value.user!.photoURL;
                                    //           userModel.loginType =
                                    //               Constant.googleLoginType;
                                    //
                                    //           Get.to(const InformationScreen(),
                                    //               arguments: {
                                    //                 "userModel": userModel,
                                    //               });
                                    //         }
                                    //       });
                                    //     }
                                    //   }
                                    // });
                                  },
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Image.asset(
                                          'assets/icons/ic_google.png'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if(Platform.isIOS)...[
                            SizedBox(width: 20),
                            Text('أو',style: TextStyle(color: themeChange.getThem()?Colors.white:Colors.black,fontSize: 20,fontWeight: FontWeight.bold)),
                            SizedBox(width: 20),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 16,
                                    offset: Offset(5, 5),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                  child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child:SignInWithAppleButton(
                                        style: SignInWithAppleButtonStyle.white,
                                        onPressed: () async {
                                          ShowToastDialog.showLoader("Please wait".tr);
                                          await controller.signInWithApple().then((value) {
                                            ShowToastDialog.closeLoader();
                                            if (value != null) {
                                              Map<String, dynamic> map = value;
                                              AuthorizationCredentialAppleID appleCredential = map['appleCredential'];
                                              UserCredential userCredential = map['userCredential'];

                                              if (userCredential.additionalUserInfo!.isNewUser) {
                                                log("----->new user");
                                                DriverUserModel userModel = DriverUserModel();
                                                userModel.id = userCredential.user!.uid;
                                                userModel.profilePic = userCredential.user!.photoURL;
                                                userModel.loginType = Constant.appleLoginType;
                                                userModel.email = userCredential.additionalUserInfo!.profile!['email'];
                                                userModel.fullName = "${appleCredential.givenName} ${appleCredential.familyName}";

                                                ShowToastDialog.closeLoader();
                                                if (!Get.isRegistered<VehicleInformationController>()) {
                                                  Get.put(VehicleInformationController());
                                                }
                                                 Get.find<VehicleInformationController>().getVehicleTye();
                                                Get.to(const InformationScreen(), arguments: {
                                                  "userModel": userModel,
                                                });
                                              }
                                              else {
                                                log("----->old user");
                                                FireStoreUtils.userExitOrNot(userCredential.user!.uid).then((userExit) {
                                                  if (userExit == true) {
                                                    if (!Get.isRegistered<VehicleInformationController>()) {
                                                      Get.put(VehicleInformationController());
                                                    }
                                                     Get.find<VehicleInformationController>().getVehicleTye();
                                                    ShowToastDialog.closeLoader();
                                                    // Get.to(const DashBoardScreen());
                                                    Get.off(() => const DashBoardScreen());
                                                  } else {
                                                    DriverUserModel userModel = DriverUserModel();
                                                    userModel.id = userCredential.user!.uid;
                                                    userModel.profilePic = userCredential.user!.photoURL;
                                                    userModel.loginType = Constant.appleLoginType;
                                                    userModel.email = userCredential.additionalUserInfo!.profile!['email'];
                                                    userModel.fullName = "${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}";

                                                    Get.to(const InformationScreen(), arguments: {
                                                      "userModel": userModel,
                                                    });
                                                  }
                                                });
                                              }
                                            }

                                          });
                                        },
                                      )
                                  )),
                            ),

                          ]

                        ],),
                        const SizedBox(height: 20),
                        ButtonThem.buildBorderButton(
                          context,
                          title: "Continue as Guest".tr,
                          iconVisibility: false,
                          onPress: () {
                            Constant.isGuestUser = true;
                            Get.offAll(const DashBoardScreen());
                          },
                        ),
                        const SizedBox(height: 40),
                        Container(
                          decoration: BoxDecoration(
                            color: themeChange.getThem()
                                ? AppColors.darkTextField.withOpacity(0.5)
                                : AppColors.textField.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: themeChange.getThem()
                                  ? AppColors.darkTextFieldBorder.withOpacity(0.5)
                                  : AppColors.textFieldBorder.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              TextFormField(
                                enabled: false,
                                validator: (value) => value != null && value.isNotEmpty ? null : 'Required',
                                keyboardType: TextInputType.number,
                                textCapitalization: TextCapitalization.sentences,
                                controller: controller.phoneNumberController.value,
                                textAlign: TextAlign.start,
                                style: GoogleFonts.poppins(
                                  color: themeChange.getThem()
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.6),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  prefixIcon: CountryCodePicker(
                                    enabled: false,
                                    onChanged: (value) {
                                      controller.countryCode.value = value.dialCode.toString();
                                    },
                                    dialogBackgroundColor: themeChange.getThem()
                                        ? AppColors.darkBackground
                                        : AppColors.background,
                                    initialSelection: "YE",
                                    comparator: (a, b) => b.name!.compareTo(a.name.toString()),
                                    flagDecoration: const BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(2)),
                                    ),
                                    padding: const EdgeInsets.only(right: 12.0),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    borderSide: BorderSide(
                                        color: themeChange.getThem()
                                            ? AppColors.darkTextFieldBorder
                                            : AppColors.textFieldBorder,
                                        width: 1),
                                  ),
                                  hintText: "Phone number".tr,
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.construction,
                                          color: Colors.orange,
                                          size: 14,
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          "قيد التطوير",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "قريباً!",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 7,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  "Next".tr,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.construction,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "قريباً",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ButtonThem.buildBorderButton(
                        //   context,
                        //   title: "Login with google".tr,
                        //   iconVisibility: true,
                        //   iconAssetImage: 'assets/icons/ic_google.png',
                        //   onPress: () async {
                        //     ShowToastDialog.showLoader("Please wait".tr);
                        //     await controller.signInWithGoogle().then((value) {
                        //       ShowToastDialog.closeLoader();
                        //       if (value != null) {
                        //         if (value.additionalUserInfo!.isNewUser) {
                        //           log("----->new user");
                        //           DriverUserModel userModel = DriverUserModel();
                        //           userModel.id = value.user!.uid;
                        //           userModel.email = value.user!.email;
                        //           userModel.fullName = value.user!.displayName;
                        //           userModel.profilePic = value.user!.photoURL;
                        //           userModel.loginType = Constant.googleLoginType;
                        //
                        //           ShowToastDialog.closeLoader();
                        //           Get.to(const InformationScreen(), arguments: {
                        //             "userModel": userModel,
                        //           });
                        //         } else {
                        //           log("----->old user");
                        //           FireStoreUtils.userExitOrNot(value.user!.uid).then((userExit) async {
                        //             if (userExit == true) {
                        //               String token = await NotificationService.getToken();
                        //               DriverUserModel userModel = DriverUserModel();
                        //
                        //               userModel.fcmToken = token;
                        //               await FireStoreUtils.updateDriverUser(userModel);
                        //               await FireStoreUtils.getDriverProfile(FirebaseAuth.instance.currentUser!.uid).then(
                        //                 (value) {
                        //                   if (value != null) {
                        //                     DriverUserModel userModel = value;
                        //                     bool isPlanExpire = false;
                        //                     if (userModel.subscriptionPlan?.id != null) {
                        //                       if (userModel.subscriptionExpiryDate == null) {
                        //                         if (userModel.subscriptionPlan?.expiryDay == '-1') {
                        //                           isPlanExpire = false;
                        //                         } else {
                        //                           isPlanExpire = true;
                        //                         }
                        //                       } else {
                        //                         DateTime expiryDate = userModel.subscriptionExpiryDate!.toDate();
                        //                         isPlanExpire = expiryDate.isBefore(DateTime.now());
                        //                       }
                        //                     } else {
                        //                       isPlanExpire = true;
                        //                     }
                        //                     if (userModel.subscriptionPlanId == null || isPlanExpire == true) {
                        //                       if (Constant.adminCommission?.isEnabled == false && Constant.isSubscriptionModelApplied == false) {
                        //                         ShowToastDialog.closeLoader();
                        //                         Get.offAll(const DashBoardScreen());
                        //                       } else {
                        //                         ShowToastDialog.closeLoader();
                        //                         //Get.offAll(const SubscriptionListScreen(), arguments: {"isShow": true});
                        //                         Get.offAll(const DashBoardScreen());
                        //                       }
                        //                     } else {
                        //                       Get.offAll(const DashBoardScreen());
                        //                     }
                        //                   }
                        //                 },
                        //               );
                        //             } else {
                        //               DriverUserModel userModel = DriverUserModel();
                        //               userModel.id = value.user!.uid;
                        //               userModel.email = value.user!.email;
                        //               userModel.fullName = value.user!.displayName;
                        //               userModel.profilePic = value.user!.photoURL;
                        //               userModel.loginType = Constant.googleLoginType;
                        //
                        //               Get.to(const InformationScreen(), arguments: {
                        //                 "userModel": userModel,
                        //               });
                        //             }
                        //           });
                        //         }
                        //       }
                        //     });
                        //   },
                        // ),
                        // const SizedBox(
                        //   height: 16,
                        // ),
                        // Visibility(
                        //     visible: Platform.isIOS,
                        //     child: ButtonThem.buildBorderButton(
                        //       context,
                        //       title: "Login with apple".tr,
                        //       iconVisibility: true,
                        //       iconAssetImage: 'assets/icons/ic_apple.png',
                        //       color: themeChange.getThem() ? AppColors.darkModePrimary : Colors.black,
                        //       onPress: () async {
                        //         ShowToastDialog.showLoader("Please wait".tr);
                        //         await controller.signInWithApple().then((value) {
                        //           ShowToastDialog.closeLoader();
                        //           if (value != null) {
                        //             Map<String, dynamic> map = value;
                        //             AuthorizationCredentialAppleID appleCredential = map['appleCredential'];
                        //             UserCredential userCredential = map['userCredential'];
                        //
                        //             if (userCredential.additionalUserInfo!.isNewUser) {
                        //               log("----->new user");
                        //               DriverUserModel userModel = DriverUserModel();
                        //               userModel.id = userCredential.user!.uid;
                        //               userModel.profilePic = userCredential.user!.photoURL;
                        //               userModel.loginType = Constant.appleLoginType;
                        //               userModel.email = userCredential.additionalUserInfo!.profile!['email'];
                        //               userModel.fullName = "${appleCredential.givenName} ${appleCredential.familyName}";
                        //
                        //               ShowToastDialog.closeLoader();
                        //               Get.to(const InformationScreen(), arguments: {
                        //                 "userModel": userModel,
                        //               });
                        //             } else {
                        //               log("----->old user");
                        //               FireStoreUtils.userExitOrNot(userCredential.user!.uid).then((userExit) async {
                        //                 if (userExit == true) {
                        //                   await FireStoreUtils.getDriverProfile(FirebaseAuth.instance.currentUser!.uid).then(
                        //                     (value) {
                        //                       if (value != null) {
                        //                         DriverUserModel userModel = value;
                        //                         bool isPlanExpire = false;
                        //                         if (userModel.subscriptionPlan?.id != null) {
                        //                           if (userModel.subscriptionExpiryDate == null) {
                        //                             if (userModel.subscriptionPlan?.expiryDay == '-1') {
                        //                               isPlanExpire = false;
                        //                             } else {
                        //                               isPlanExpire = true;
                        //                             }
                        //                           } else {
                        //                             DateTime expiryDate = userModel.subscriptionExpiryDate!.toDate();
                        //                             isPlanExpire = expiryDate.isBefore(DateTime.now());
                        //                           }
                        //                         } else {
                        //                           isPlanExpire = true;
                        //                         }
                        //                         if (userModel.subscriptionPlanId == null || isPlanExpire == true) {
                        //                           if (Constant.adminCommission?.isEnabled == false && Constant.isSubscriptionModelApplied == false) {
                        //                             ShowToastDialog.closeLoader();
                        //                             Get.offAll(const DashBoardScreen());
                        //                           } else {
                        //                             ShowToastDialog.closeLoader();
                        //                             //Get.offAll(const SubscriptionListScreen(), arguments: {"isShow": true});
                        //                             Get.offAll(const DashBoardScreen());
                        //                           }
                        //                         } else {
                        //                           Get.offAll(const DashBoardScreen());
                        //                         }
                        //                       }
                        //                     },
                        //                   );
                        //                 } else {
                        //                   DriverUserModel userModel = DriverUserModel();
                        //                   userModel.id = userCredential.user!.uid;
                        //                   userModel.profilePic = userCredential.user!.photoURL;
                        //                   userModel.loginType = Constant.appleLoginType;
                        //                   userModel.email = userCredential.additionalUserInfo!.profile!['email'];
                        //                   userModel.fullName = "${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}";
                        //
                        //                   Get.to(const InformationScreen(), arguments: {
                        //                     "userModel": userModel,
                        //                   });
                        //                 }
                        //               });
                        //             }
                        //           }
                        //         });
                        //       },
                        //     )),
                      ],
                    ),
                  )
                ],
              ),
            ),
            bottomNavigationBar: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    text: 'By tapping "Next" you agree to '.tr,
                    style: GoogleFonts.poppins(),
                    children: <TextSpan>[
                      TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(const TermsAndConditionScreen(
                                type: "terms",
                              ));
                            },
                          text: 'Terms and conditions'.tr,
                          style: GoogleFonts.poppins(decoration: TextDecoration.underline)),
                      TextSpan(text: ' and '.tr, style: GoogleFonts.poppins()),
                      TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(const TermsAndConditionScreen(
                                type: "privacy",
                              ));
                            },
                          text: 'privacy policy'.tr,
                          style: GoogleFonts.poppins(decoration: TextDecoration.underline)),
                      // can add more TextSpans here...
                    ],
                  ),
                )),
          );
        });
  }
}
