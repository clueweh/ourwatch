import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'feed_screen.dart' show handleLogout;

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final User? _currentUser;
  Future<DocumentSnapshot<Map<String, dynamic>>>? _userDocument;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _userDocument = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
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
          'Account',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _currentUser == null
          ? const Center(
              child: Text(
                'No signed-in user.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _userDocument,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Unable to load account.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text(
                      'Account details unavailable.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final data = snapshot.data!.data()!;
                final barangay = data['barangay']?.toString().trim();
                final createdAt = data['createdAt'];
                final DateTime? createdAtDate = createdAt is Timestamp
                    ? createdAt.toDate()
                    : createdAt is DateTime
                        ? createdAt
                        : null;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AccountDetail(
                            label: 'Name',
                            value: data['name']?.toString() ?? 'Not provided',
                          ),
                          const SizedBox(height: 18),
                          _AccountDetail(
                            label: 'Email',
                            value: data['email']?.toString() ?? 'Not provided',
                          ),
                          const SizedBox(height: 18),
                          _AccountDetail(
                            label: 'Barangay',
                            value: barangay == null || barangay.isEmpty
                                ? 'Not provided'
                                : barangay,
                          ),
                          const SizedBox(height: 18),
                          _AccountDetail(
                            label: 'Role',
                            value: data['role']?.toString() ?? 'Not provided',
                          ),
                          const SizedBox(height: 18),
                          _AccountDetail(
                            label: 'Created',
                            value: createdAtDate == null
                                ? 'Unavailable'
                                : MaterialLocalizations.of(context)
                                    .formatMediumDate(createdAtDate),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => handleLogout(context),
                              icon: const Icon(Icons.logout),
                              label: const Text('Log out'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _AccountDetail extends StatelessWidget {
  const _AccountDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}