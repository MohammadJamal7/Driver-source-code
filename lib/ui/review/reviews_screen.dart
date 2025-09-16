import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../../constant/constant.dart';
import '../../model/driver_user_model.dart';
import '../../model/review_model.dart';
import '../../themes/app_colors.dart';
import '../../utils/DarkThemeProvider.dart';
import '../../utils/fire_store_utils.dart';
import '../../widget/firebase_pagination/src/firestore_pagination.dart';

class ReviewsScreen extends StatelessWidget {
  final String customerId;

  const ReviewsScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: AppColors.primary,
        title: Text("Reviews".tr),
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: const Icon(
            Icons.arrow_back,
          ),
        ),
      ),
      body: FirestorePagination(
        query: FireStoreUtils.getReviewsQuery(customerId),
        //key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        padding: const EdgeInsets.all(10),
        limit: 10,
        onEmpty: Center(
          child: Text("No Reviews".tr),
        ),
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 5);
        },
        initialLoader: Constant.loader(context),
        itemBuilder: (context, docs, index) {
          print(docs);
          final review = ReviewModel.fromFirestore(docs[index]);
          log(review.comment.toString());
          log("-----------------------------------------");
          return Container(
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
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 5,
                        offset: const Offset(
                          0,
                          4,
                        ),
                      ),
                    ],
            ),
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 8,
            ),
            child: FutureBuilder<DriverUserModel?>(
                future: FireStoreUtils.getDriverProfile(
                  review.driverId.toString(),
                ),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            child: CachedNetworkImage(
                              height: 50,
                              width: 50,
                              imageUrl: Constant.userPlaceHolder,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Constant.loader(context),
                              errorWidget: (context, url, error) =>
                                  Image.network(
                                Constant.userPlaceHolder,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Asynchronous user",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(
                                        review.date!.toDate(),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 22,
                                      color: AppColors.ratingColour,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      Constant.calculateReview(
                                          reviewCount: "0.0", reviewSum: "0.0"),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (review.comment != null &&
                                    review.comment!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(review.comment!),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      else {
                        // if (snapshot.data == null) {
                        //   return SizedBox();
                        // }
                        DriverUserModel userModel = DriverUserModel(
                          fullName: snapshot.data?.fullName ?? "otherPerson".tr,
                          profilePic: snapshot.data?.profilePic,
                        );

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              child: CachedNetworkImage(
                                height: 50,
                                width: 50,
                                imageUrl: userModel.profilePic.toString(),
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Constant.loader(context),
                                errorWidget: (context, url, error) =>
                                    Image.network(Constant.userPlaceHolder),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userModel.fullName.toString(),
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(
                                          review.date!.toDate(),
                                        ),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 22,
                                        color: AppColors.ratingColour,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        review.rating ?? '0.0',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (review.comment != null &&
                                      review.comment!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(review.comment!),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    default:
                      return const Text('Error');
                  }
                }),
          );
        },
      ),
    );
  }
}
