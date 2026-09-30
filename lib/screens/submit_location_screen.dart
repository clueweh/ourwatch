import 'submit_media_screen.dart';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_colors.dart';

class SubmitLocationScreen extends StatefulWidget {
  final String title;
  final String type;
  final String description;

  const SubmitLocationScreen({
    super.key,
    required this.title,
    required this.type,
    required this.description,
  });

  @override
  State<SubmitLocationScreen> createState() => _SubmitLocationScreenState();
}

class _SubmitLocationScreenState extends State<SubmitLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barangayController = TextEditingController();
  final _locationController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    _barangayController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        throw Exception('No address was found for this location.');
      }

      final placemark = placemarks.first;
      final address =
          <String?>[
                placemark.street,
                placemark.subLocality,
                placemark.locality,
                placemark.subAdministrativeArea,
                placemark.administrativeArea,
                placemark.postalCode,
                placemark.country,
              ]
              .whereType<String>()
              .map((part) => part.trim())
              .where((part) => part.isNotEmpty)
              .join(', ');
      if (address.isEmpty) {
        throw Exception('No address was found for this location.');
      }

      setState(() {
        _locationController.text = address;
        isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Failed to get GPS location: $e');
      setState(() {
        errorMessage = "Couldn't get your GPS location. Please type the location manually, or try this on the Android app.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Submit Incident',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step 2 of 3',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 20,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 20,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'INCIDENT LOCATION',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _barangayController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Community / Barangay',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your community or barangay.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter a location.'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _getCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text('Use GPS'),
                        ),
                      ),
                    ],
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    ),
                ],
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubmitMediaScreen(
                        title: widget.title,
                        type: widget.type,
                        description: widget.description,
                        barangayText: _barangayController.text.trim(),
                        locationText: _locationController.text.trim(),
                      ),
                    ),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
