import 'submit_media_screen.dart';

import 'package:flutter/material.dart';
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
  Position? currentPosition;
  bool isLoading = false;
  String? errorMessage;

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = 'Location services are disabled.';
          isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage = 'Location permission denied.';
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage = 'Location permissions are permanently denied.';
          isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = position;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error getting location: $e';
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
            if (currentPosition == null && !isLoading)
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location, color: Colors.white),
                label: const Text('Capture Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            if (currentPosition != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Location captured',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${currentPosition!.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Lng: ${currentPosition!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
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
                onPressed: currentPosition == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubmitMediaScreen(
                              title: widget.title,
                              type: widget.type,
                              description: widget.description,
                              latitude: currentPosition!.latitude,
                              longitude: currentPosition!.longitude,
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
