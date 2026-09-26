import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'sign_in_screen.dart';
import 'view_report_screen.dart';

/// Signs the current user out and returns them to Sign In, clearing the
/// entire navigation stack so the back button can't return into the app.
/// Shared by any screen that shows a logout action.
Future<void> handleLogout(BuildContext context) async {
  await AuthService().signOut();
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }
}

/// Lists all incident reports, newest first, and navigates to
/// [ViewReportScreen] on tap.
///
/// All incident types are treated equally here by design — no type is
/// visually prioritized over another. The only "urgency" signal is recency:
/// any report submitted within the last hour gets a NEW badge, and a report
/// that streams in while this screen is open triggers a snackbar.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // Tracks doc IDs we've already seen, so we only announce genuinely new
  // reports (not the initial batch loaded when the screen first opens).
  final Set<String> _seenDocIds = {};
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Feed',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'Sign out',
            onPressed: () => handleLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('incident_reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading reports: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Detect newly-arrived reports (skip the very first load, since
          // every doc is "new" then and we don't want a snackbar spam on
          // screen open).
          if (_isFirstLoad) {
            _seenDocIds.addAll(docs.map((d) => d.id));
            _isFirstLoad = false;
          } else {
            final newDocs = docs.where((d) => !_seenDocIds.contains(d.id));
            for (final doc in newDocs) {
              _seenDocIds.add(doc.id);
              final title = doc.data()['title'] ?? 'A new report';
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('New report: $title'),
                    backgroundColor: AppColors.primaryRed,
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }
          }

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No reports yet.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return _ReportCard(docId: doc.id, data: data);
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _ReportCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final String title = data['title'] ?? 'Untitled';
    final String type = data['type'] ?? 'Unknown';
    final String description = data['description'] ?? '';
    final String? imageBase64 = data['imageBase64'];
    final Timestamp? timestamp = data['timestamp'];

    Uint8List? thumbBytes;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        thumbBytes = base64Decode(imageBase64);
      } catch (_) {
        thumbBytes = null;
      }
    }

    // Recency-based urgency signal, applied equally across all incident
    // types — no type is treated as more important than another.
    final bool isRecent = timestamp != null &&
        DateTime.now().difference(timestamp.toDate()) <
            const Duration(hours: 1);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewReportScreen(docId: docId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRecent ? AppColors.primaryRed : AppColors.borderDark,
            width: isRecent ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: thumbBytes != null
                  ? Image.memory(
                      thumbBytes,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (isRecent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      if (timestamp != null)
                        Text(
                          _formatTimestamp(timestamp),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.borderDark,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white38,
        size: 20,
      ),
    );
  }

  String _formatTimestamp(Timestamp ts) {
    final date = ts.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }
}