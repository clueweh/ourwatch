import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';

const List<String> kReportStatuses = ['Active', 'Under Review', 'Resolved'];

/// Displays a single incident report, fetched fresh from Firestore by [docId].
///
/// Status is shown to everyone, but only editable by a "responder" — a
/// "resident" (including the report's own author) sees it as read-only
/// text. This keeps "Resolved" meaningful as independent verification
/// rather than something the reporter could set on themselves.
///
/// Navigate to it like:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => ViewReportScreen(docId: report.id),
///   ));
class ViewReportScreen extends StatefulWidget {
  final String docId;

  const ViewReportScreen({super.key, required this.docId});

  @override
  State<ViewReportScreen> createState() => _ViewReportScreenState();
}

class _ViewReportScreenState extends State<ViewReportScreen> {
  final AuthService _authService = AuthService();
  late final Future<String> _roleFuture;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _roleFuture = _authService.getCurrentUserRole();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await FirebaseFirestore.instance
          .collection('incident_reports')
          .doc(widget.docId)
          .update({'status': newStatus});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _openDirections(String destination) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${Uri.encodeComponent(destination)}'
      '&travelmode=driving',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Incident Report',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('incident_reports')
            .doc(widget.docId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading report: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Report not found.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data()!;

          final String title = data['title'] ?? 'Untitled';
          final String type = data['type'] ?? 'Unknown';
          final String description = data['description'] ?? '';
          final barangayValue = data['barangayId']?.toString().trim() ?? '';
          final locationValue = data['locationText']?.toString().trim() ?? '';
          final destination = [
            barangayValue,
            locationValue,
          ].where((value) => value.isNotEmpty).join(', ');
          final String barangay = barangayValue.isEmpty ? '—' : barangayValue;
          final String location = locationValue.isEmpty ? '—' : locationValue;
          final String? imageBase64 = data['imageBase64'];
          final String? userId = data['userId'];
          final Timestamp? timestamp = data['timestamp'];
          final String status = data['status'] ?? 'Active';

          // Decode the image safely — malformed/missing base64 shouldn't crash the screen.
          Uint8List? imageBytes;
          if (imageBase64 != null && imageBase64.isNotEmpty) {
            try {
              imageBytes = base64Decode(imageBase64);
            } catch (_) {
              imageBytes = null; // fall through to "no image" state below
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Photo ---
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imageBytes,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _noImagePlaceholder();
                      },
                    ),
                  )
                else
                  _noImagePlaceholder(),

                const SizedBox(height: 20),

                // --- Type badge ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // --- Status: read-only for residents, editable for responders ---
                FutureBuilder<String>(
                  future: _roleFuture,
                  builder: (context, roleSnapshot) {
                    final role = roleSnapshot.data ?? 'resident';
                    final isResponder = role == 'responder';

                    if (!isResponder) {
                      // Read-only status pill for residents.
                      return Row(
                        children: [
                          const Text(
                            'STATUS: ',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }

                    // Editable dropdown for responders only.
                    return Row(
                      children: [
                        const Text(
                          'STATUS: ',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _isUpdatingStatus
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : DropdownButton<String>(
                                value: kReportStatuses.contains(status)
                                    ? status
                                    : kReportStatuses.first,
                                dropdownColor: AppColors.inputBg,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                underline: Container(
                                  height: 1,
                                  color: AppColors.primaryRed,
                                ),
                                items: kReportStatuses
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null &&
                                      newStatus != status) {
                                    _updateStatus(newStatus);
                                  }
                                },
                              ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // --- Title ---
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // --- Description ---
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),
                _metaRow(Icons.location_city_outlined, 'Barangay: $barangay'),
                _metaRow(Icons.place_outlined, 'Location: $location'),
                if (destination.isNotEmpty)
                  FutureBuilder<String>(
                    future: _roleFuture,
                    builder: (context, roleSnapshot) {
                      if (roleSnapshot.data != 'responder') {
                        return const SizedBox.shrink();
                      }

                      return OutlinedButton.icon(
                        onPressed: () => _openDirections(destination),
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: AppColors.borderDark),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),
                Divider(color: AppColors.borderDark),
                const SizedBox(height: 12),

                // --- Metadata ---
                if (timestamp != null)
                  _metaRow(Icons.access_time, _formatTimestamp(timestamp)),
                if (userId != null) _metaRow(Icons.person_outline, userId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _noImagePlaceholder() {
    return Container(
      width: double.infinity,
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
              Icons.image_not_supported_outlined,
              color: Colors.white38,
              size: 32,
            ),
            SizedBox(height: 8),
            Text('No photo attached', style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp ts) {
    final date = ts.toDate();
    return '${date.month}/${date.day}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
