import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/incident_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String selectedType = 'All Types';
  String selectedStatus = 'All Statuses';

  final List<String> types = [
    'All Types',
    'Fire',
    'Flood',
    'Theft',
    'Assault',
    'Accident',
    'Suspicious Activity',
    'Medical',
    'Vandalism'
  ];

  final List<String> statuses = ['All Statuses', 'Active', 'Under Review', 'Resolved'];

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
            Text('OURWATCH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('+ Report', style: TextStyle(color: Colors.white, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
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
              Text(
                'Area Incident Feed',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('2 active', style: TextStyle(color: AppColors.primaryRed, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Riverside District · 6 reports', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search reports...',
              hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderDark)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderDark)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedType,
            dropdownColor: AppColors.cardBg,
            decoration: _dropdownDecoration(),
            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
            onChanged: (val) => setState(() => selectedType = val!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedStatus,
            dropdownColor: AppColors.cardBg,
            decoration: _dropdownDecoration(),
            items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
            onChanged: (val) => setState(() => selectedStatus = val!),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryRed.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: '2 active incidents ',
                      style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 13),
                      children: [
                        TextSpan(
                          text: 'in your area — stay vigilant',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ),
                Text('Use sidebar to report', style: TextStyle(color: AppColors.primaryRed, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),
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

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderDark)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderDark)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryRed)),
    );
  }
}