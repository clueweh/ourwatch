import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/incident_card.dart';
import 'feed_screen.dart' show handleLogout;
import 'view_report_screen.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.hexagon_outlined, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 8),
            const Text('OURWATCH',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child:
                  const Text('+ Report', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'Sign out',
            onPressed: () => handleLogout(context),
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(
              child: Text(
                'You must be signed in to view your reports.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('incident_reports')
                  .where('userId', isEqualTo: currentUser.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // Firestore often throws here the first time a
                  // where()+orderBy() query runs, asking you to create a
                  // composite index. If you see that in the debug console,
                  // click the link it gives you — it takes ~1 minute to
                  // build, then this query works.
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error loading your reports: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                int activeCount = 0;
                int underReviewCount = 0;
                int resolvedCount = 0;
                for (final doc in docs) {
                  final status = doc.data()['status'] ?? 'Active';
                  switch (status) {
                    case 'Under Review':
                      underReviewCount++;
                      break;
                    case 'Resolved':
                      resolvedCount++;
                      break;
                    default:
                      activeCount++;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('My Reports',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Text('Use sidebar to report',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Reports you have submitted',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildStatBox('$activeCount', 'Active'),
                        const SizedBox(width: 12),
                        _buildStatBox('$underReviewCount', 'Under Review'),
                        const SizedBox(width: 12),
                        _buildStatBox('$resolvedCount', 'Resolved'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (docs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            "You haven't submitted any reports yet.",
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...docs.map((doc) => _buildCard(context, doc)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCard(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final String title = data['title'] ?? 'Untitled';
    final String category = data['type'] ?? 'Unknown';
    final String description = data['description'] ?? '';
    final String status = data['status'] ?? 'Active';
    final String? imageBase64 = data['imageBase64'];
    final double? lat = (data['latitude'] as num?)?.toDouble();
    final double? lng = (data['longitude'] as num?)?.toDouble();
    final Timestamp? timestamp = data['timestamp'];

    Uint8List? imageBytes;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64);
      } catch (_) {
        imageBytes = null;
      }
    }

    final String location = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
        : 'Location unavailable';

    final String timeAgo =
        timestamp != null ? _formatTimeAgo(timestamp.toDate()) : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ViewReportScreen(docId: doc.id)),
        );
      },
      child: IncidentCard(
        title: title,
        category: category,
        description: description,
        location: location,
        timeAgo: timeAgo,
        status: status,
        imageBytes: imageBytes,
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildStatBox(String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}