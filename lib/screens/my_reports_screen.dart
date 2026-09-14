import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/incident_card.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.hexagon_outlined, color: AppColors.primaryRed, size: 20),
            const SizedBox(width: 8),
            const Text('OURWATCH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('+ Report', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('Use sidebar to report', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Reports you have submitted', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatBox('1', 'Active'),
              const SizedBox(width: 12),
              _buildStatBox('0', 'Under Review'),
              const SizedBox(width: 12),
              _buildStatBox('0', 'Resolved'),
            ],
          ),
          const SizedBox(height: 24),
          const IncidentCard(
            title: 'Vehicle fire on Maple Ave',
            category: 'FIRE',
            description: 'A sedan has caught fire near the intersection of Maple Ave and 3rd St. Flames visible from the engine bay. No...',
            location: 'Maple Ave & 3rd St',
            timeAgo: '19h ago',
            status: 'Active',
            imageUrl: 'https://images.unsplash.com/photo-1599839575945-a9e5af0c3fa5?auto=format&fit=crop&w=600&q=80',
          ),
        ],
      ),
    );
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
            Text(count, style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}