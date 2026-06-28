import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/api_path.dart';

class ReportFormScreen extends StatefulWidget {
  final UserModel user;
  final ReportModel? report;

  const ReportFormScreen({super.key, required this.user, this.report});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  static const categories = [
    'Electronics',
    'Wallet',
    'Keys',
    'Documents',
    'Clothing',
    'Bag',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  String reportType = 'Lost';
  String category = categories.first;
  String status = 'Unclaimed';
  DateTime reportDate = DateTime.now();
  Uint8List? imageBytes;
  bool isSaving = false;

  bool get isEditing => widget.report != null;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    if (report != null) {
      titleController.text = report.title;
      descriptionController.text = report.description;
      locationController.text = report.location;
      reportType = report.reportType;
      category = categories.contains(report.category)
          ? report.category
          : 'Other';
      status = report.status;
      reportDate = DateTime.tryParse(report.reportDate) ?? DateTime.now();
    }
  }

  String get formattedDate {
    final month = reportDate.month.toString().padLeft(2, '0');
    final day = reportDate.day.toString().padLeft(2, '0');
    return '${reportDate.year}-$month-$day';
  }

  Future<void> pickImage() async {
    // Read the photo as bytes before sending it to PHP.
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (mounted) setState(() => imageBytes = bytes);
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: reportDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => reportDate = selected);
  }

  Future<void> saveReport() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? 'Confirm Update' : 'Confirm Report'),
        content: Text(
          isEditing
              ? 'Save the changes to this report?'
              : 'Submit this $reportType item report?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => isSaving = true);
    try {
      // This form handles both new reports and report updates.
      final fields = <String, String>{
        'user_id': widget.user.id.toString(),
        'report_type': reportType,
        'title': titleController.text.trim(),
        'category': category,
        'description': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'report_date': formattedDate,
        'image': imageBytes == null
            ? (isEditing ? 'NA' : '')
            : base64Encode(imageBytes!),
      };

      String endpoint = 'add_report.php';
      if (isEditing) {
        endpoint = 'update_report.php';
        fields['id'] = widget.report!.id.toString();
        fields['status'] = status;
      }

      final response = await http.post(
        Uri.parse(ApiPath.endpoint(endpoint)),
        body: fields,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Unable to save report');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'].toString())));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Report' : 'New Report')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            width: width > 700 ? 620 : double.infinity,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: pickImage,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 190,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageBytes != null
                          ? Image.memory(imageBytes!, fit: BoxFit.cover)
                          : widget.report != null &&
                                widget.report!.image.isNotEmpty
                          ? Image.network(
                              ApiPath.reportImage(widget.report!.image),
                              fit: BoxFit.cover,
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 44),
                                SizedBox(height: 8),
                                Text('Tap to add an item photo (optional)'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: reportType,
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                      prefixIcon: Icon(Icons.swap_vert_circle_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Lost', child: Text('Lost Item')),
                      DropdownMenuItem(
                        value: 'Found',
                        child: Text('Found Item'),
                      ),
                    ],
                    onChanged: (value) => setState(() => reportType = value!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Item Title',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categories
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => category = value!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Campus Location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    tileColor: const Color(0xFFF5F8FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFD5DEED)),
                    ),
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Date'),
                    subtitle: Text(formattedDate),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: pickDate,
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.task_alt_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Unclaimed',
                          child: Text('Unclaimed'),
                        ),
                        DropdownMenuItem(
                          value: 'Claimed',
                          child: Text('Claimed'),
                        ),
                      ],
                      onChanged: (value) => setState(() => status = value!),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : saveReport,
                      icon: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isEditing ? 'Update Report' : 'Submit Report',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }
}
