import 'package:driver/themes/app_colors.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:driver/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:provider/provider.dart';

import '../model/search_info.dart';
import 'google_map_search_place.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  Marker? _selectedMarker;
  Place? place;
  TextEditingController textController = TextEditingController();

  LatLng? _selectedLatLng;

  @override
  void initState() {
    super.initState();
    _setUserLocation();
  }

  Future<void> _setUserLocation() async {
    try {
      final locationData = await Utils.getCurrentLocation();

      final latLng = LatLng(locationData.latitude, locationData.longitude);

      await _moveCamera(latLng);
      await _addMarker(latLng);
    } catch (e) {
      print("Error getting location: $e");
      // ممكن تعرض رسالة للمستخدم
    }
  }

  Future<void> _moveCamera(LatLng latLng) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    }
  }

  Future<void> _addMarker(LatLng latLng) async {
    // البحث العكسي من OSM عن العنوان
    place = await Nominatim.reverseSearch(
      lat: latLng.latitude,
      lon: latLng.longitude,
      zoom: 14,
      addressDetails: true,
      extraTags: true,
      nameDetails: true,
    );

    setState(() {
      _selectedLatLng = latLng;
      _selectedMarker = Marker(
        markerId: const MarkerId('selected-location'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: place?.displayName ?? 'Selected Location'),
      );
      textController.text = place?.displayName ?? '';
    });
  }

  void _onMapTapped(LatLng latLng) {
    _addMarker(latLng);
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Picker'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(31.5, 34.47), // مكان افتراضي (مثلاً غزة)
              zoom: 10,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_selectedLatLng != null) {
                _moveCamera(_selectedLatLng!);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _selectedMarker != null ? {_selectedMarker!} : {},
            onTap: _onMapTapped,
          ),

          // صندوق عرض العنوان في الأسفل
          if (place?.displayName != null && place!.displayName!.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100, left: 40, right: 40),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place?.displayName ?? '',
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Get.back(result: place);
                      },
                      icon: const Icon(
                        Icons.check_circle,
                        size: 40,
                        color: Colors.black,
                      ),
                    )
                  ],
                ),
              ),
            ),

          // حقل البحث (عند الضغط يفتح شاشة بحث خاصة بك)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: InkWell(
              onTap: () async {
                try {
                  final value = await Get.to(GoogleMapSearchPlacesApi());
                  final searchInfo = value as SearchInfo;
                  textController.text = searchInfo.address.toString();
                  final latLng = LatLng(searchInfo.point.latitude, searchInfo.point.longitude);
                  await _addMarker(latLng);
                  await _moveCamera(latLng);
                } catch (e) {
                  print('Returned value is not SearchInfo: $e');
                }

              },
              child: buildTextField(
                title: "Search Address".tr,
                textController: textController,
              ),
            ),
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setUserLocation,
        child: Icon(
          Icons.my_location,
          color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
        ),
      ),
    );
  }

  Widget buildTextField(
      {required String title, required TextEditingController textController}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: TextField(
        controller: textController,
        textInputAction: TextInputAction.done,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: const Icon(
              Icons.location_on,
              color: Colors.black,
            ),
            onPressed: () {},
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: title,
          hintStyle: const TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabled: false,
        ),
      ),
    );
  }
}
