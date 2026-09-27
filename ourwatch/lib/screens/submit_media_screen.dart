import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';

class SubmitMediaScreen extends StatefulWidget {
  final String title;
  final String type;
  final String description;
  final double latitude;
  final double longitude;

  const SubmitMediaScreen({
    super.key,
    required this.title,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SubmitMediaScreen> createState() => _SubmitMediaScreenState();
}

class _SubmitMediaScreenState extends State<SubmitMediaScreen> {
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  bool isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 70,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        selectedImageBytes = bytes;
        selectedImageName = picked.name;
      });
    }
  }

  void _removeImage() {
    setState(() {
      selectedImageBytes = null;
      selectedImageName = null;
    });
  }

  Future<void> _submitReport() async {
    setState(() => isSubmitting = true);

    try {
      // Convert image to base64 if one was selected (no Firebase Storage
      // needed — this avoids requiring the paid Blaze plan).
      String? imageBase64;
      if (selectedImageBytes != null) {
        imageBase64 = base64Encode(selectedImageBytes!);
      }

      // Tag the report with the reporter's barangay so Feed/Statistics can
      // eventually be scoped per-community.
      final barangayId = await AuthService().getCurrentUserBarangayId();

      // Save report data to Firestore
      await FirebaseFirestore.instance.collection('incident_reports').add({
        'title': widget.title,
        'type': widget.type,
        'description': widget.description,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'imageBase64': imageBase64,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'barangayId': barangayId,
        'timestamp': FieldValue.serverTimestamp(),
        // Every new report starts "Active". Only a responder can change
        // this later (see ViewReportScreen) — residents, including the
        // report's own author, cannot edit it themselves. This keeps the
        // "Resolved" status meaningful as independent verification.
        'status': 'Active',
      });

      setState(() => isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Report submitted!')));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting report: $e')));
      }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
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
                  'Step 3 of 3',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 20,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'ATTACH PHOTO (OPTIONAL)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            if (selectedImageBytes == null)
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.white54,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to add a photo',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      selectedImageBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
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
                onPressed: isSubmitting ? null : _submitReport,
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Submit Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.check, size: 16, color: Colors.white),
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