import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SubmitIncidentScreen extends StatefulWidget {
  const SubmitIncidentScreen({super.key});

  @override
  State<SubmitIncidentScreen> createState() => _SubmitIncidentScreenState();
}

class _SubmitIncidentScreenState extends State<SubmitIncidentScreen> {
  String? selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Submit Incident', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () {},
          )
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
                Text('Step 1 of 3', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Row(
                  children: [
                    Container(width: 20, height: 4, decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Container(width: 20, height: 4, decoration: BoxDecoration(color: AppColors.borderDark, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Container(width: 20, height: 4, decoration: BoxDecoration(color: AppColors.borderDark, borderRadius: BorderRadius.circular(2))),
                  ],
                )
              ],
            ),
            const SizedBox(height: 32),
            _buildLabel('INCIDENT TITLE'),
            const SizedBox(height: 8),
            TextField(
              decoration: _inputDecoration('e.g. Vehicle fire on Oak Street'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            _buildLabel('INCIDENT TYPE'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedType,
              hint: Text('Select type...', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5))),
              dropdownColor: AppColors.cardBg,
              decoration: _inputDecoration(''),
              items: ['Fire', 'Flood', 'Theft', 'Assault', 'Accident']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (val) => setState(() => selectedType = val),
            ),
            const SizedBox(height: 20),
            _buildLabel('DESCRIPTION'),
            const SizedBox(height: 8),
            TextField(
              maxLines: 5,
              decoration: _inputDecoration('Describe what is happening, who is involved, and any immediate danger...'),
              style: const TextStyle(color: Colors.white),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13),
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderDark)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderDark)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryRed)),
    );
  }
}