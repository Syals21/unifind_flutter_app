import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/api_path.dart';
import 'report_form_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  final UserModel user;
  final ReportModel report;

  const ReportDetailScreen({
    super.key,
    required this.user,
    required this.report,
  });

  bool get isOwner => user.id == report.userId;

  Future<void> _editReport(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportFormScreen(user: user, report: report),
      ),
    );
    if (changed == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteReport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final response = await http.post(
        Uri.parse(ApiPath.endpoint('delete_report.php')),
        body: {'id': report.id.toString(), 'user_id': user.id.toString()},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Delete failed');
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'].toString())));
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markAsClaimed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as Claimed'),
        content: const Text(
          'Confirm that this item has been returned to its owner or claimed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      // Keep the report details and update only the claimed status.
      final response = await http.post(
        Uri.parse(ApiPath.endpoint('update_report.php')),
        body: {
          'id': report.id.toString(),
          'user_id': user.id.toString(),
          'report_type': report.reportType,
          'title': report.title,
          'category': report.category,
          'description': report.description,
          'location': report.location,
          'report_date': report.reportDate,
          'status': 'Claimed',
          'image': 'NA',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Unable to update report');
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item marked as claimed'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = report.reportType == 'Lost';
    final accent = isLost ? Colors.orange.shade800 : Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: isOwner
            ? [
                IconButton(
                  onPressed: () => _editReport(context),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _deleteReport(context),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    height: 260,
                    color: const Color(0xFFEAF1FB),
                    child: report.image.isEmpty
                        ? Icon(
                            isLost
                                ? Icons.search_off_rounded
                                : Icons.inventory_2_outlined,
                            size: 80,
                            color: accent,
                          )
                        : Image.network(
                            ApiPath.reportImage(report.image),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              size: 70,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(
                        isLost ? Icons.search : Icons.check_circle_outline,
                        size: 18,
                        color: accent,
                      ),
                      label: Text(report.reportType),
                    ),
                    Chip(label: Text(report.category)),
                    Chip(
                      avatar: Icon(
                        report.status == 'Claimed'
                            ? Icons.task_alt
                            : Icons.schedule,
                        size: 18,
                      ),
                      label: Text(report.status),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  report.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: report.location,
                ),
                _DetailRow(
                  icon: Icons.calendar_month_outlined,
                  title: 'Date',
                  value: report.reportDate,
                ),
                const SizedBox(height: 18),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reported By',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ContactRow(
                          icon: Icons.person_outline,
                          value: report.userName,
                        ),
                        _ContactRow(
                          icon: Icons.email_outlined,
                          value: report.userEmail,
                        ),
                        _ContactRow(
                          icon: Icons.phone_outlined,
                          value: report.userPhone,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF86C99A),
                        disabledForegroundColor: Colors.white,
                      ),
                      onPressed: report.status == 'Claimed'
                          ? null
                          : () => _markAsClaimed(context),
                      icon: const Icon(Icons.task_alt),
                      label: Text(
                        report.status == 'Claimed'
                            ? 'Item Claimed'
                            : 'Mark as Claimed',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
