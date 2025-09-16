import 'dart:developer';
import 'package:driver/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_webservice/places.dart';

class GoogleSearchPlaceController extends GetxController {
  Rx<TextEditingController> searchTxtController = TextEditingController().obs;
  RxList<Prediction> suggestionsList = <Prediction>[].obs;

  late GoogleMapsPlaces _places;

  @override
  void onInit() {
    super.onInit();
    _places = GoogleMapsPlaces(apiKey: Constant.mapAPIKey);
    searchTxtController.value.addListener(_onChanged);
  }

  void _onChanged() {
    final input = searchTxtController.value.text;
    if (input.isNotEmpty) {
      fetchSuggestions(input);
    } else {
      suggestionsList.clear();
    }
  }

  Future<void> fetchSuggestions(String input) async {
    log(":: fetchSuggestions :: $input");
    try {
      final response = await _places.autocomplete(input);
      if (response.isOkay) {
        final filtered = response.predictions.where((place) {
          // نحاول نحصل على بلد من description أو structuredFormatting
          final description = place.description?.toLowerCase() ?? "";
          final countryFilter = Constant.regionCountry.toLowerCase();

          if (countryFilter == "all") {
            return true;
          }
          // نبحث إذا كان اسم البلد موجود داخل النص
          return description.contains(countryFilter);
        }).toList();

        suggestionsList.value = filtered;
      } else {
        log("Google Places API error: ${response.errorMessage}");
      }
    } catch (e) {
      log("fetchSuggestions error: $e");
    }
  }

  @override
  void onClose() {
    searchTxtController.value.dispose();
    _places.dispose();
    super.onClose();
  }
}
