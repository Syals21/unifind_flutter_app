import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/report_model.dart';
import '../models/user_model.dart';
import '../services/api_path.dart';
import '../widgets/my_drawer.dart';
import '../widgets/report_card.dart';
import 'report_detail_screen.dart';
import 'report_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  final UserModel user;
  final bool onlyMine;

  const ReportsScreen({super.key, required this.user, this.onlyMine = false});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const categories = [
    'All',
    'Electronics',
    'Wallet',
    'Keys',
    'Documents',
    'Clothing',
    'Bag',
    'Other',
  ];

  final searchController = TextEditingController();
  final List<ReportModel> reports = [];
  String selectedType = 'All';
  String selectedCategory = 'All';
  String selectedStatus = 'All';
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports({int page = 1}) async {
    setState(() => isLoading = true);
    try {
      // Pass the current search and filter values to the API.
      final query = <String, String>{
        'page': page.toString(),
        'limit': '10',
        'search': searchController.text.trim(),
        'report_type': selectedType,
        'category': selectedCategory,
        'status': selectedStatus,
      };
      if (widget.onlyMine) query['user_id'] = widget.user.id.toString();

      final uri = Uri.parse(
        ApiPath.endpoint('load_reports.php'),
      ).replace(queryParameters: query);
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Unable to load reports');
      }

      final loaded = List<ReportModel>.from(
        (data['reports'] ?? []).map(
          (item) => ReportModel.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      if (!mounted) return;
      setState(() {
        reports
          ..clear()
          ..addAll(loaded);
        currentPage = (data['current_page'] as num?)?.toInt() ?? 1;
        totalPages = (data['total_pages'] as num?)?.toInt() ?? 1;
        totalItems = (data['total_items'] as num?)?.toInt() ?? loaded.length;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> openReport(ReportModel report) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(user: widget.user, report: report),
      ),
    );
    if (changed == true) loadReports(page: currentPage);
  }

  Future<void> addReport() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReportFormScreen(user: widget.user)),
    );
    if (changed == true) loadReports();
  }

  void clearFilters() {
    searchController.clear();
    setState(() {
      selectedType = 'All';
      selectedCategory = 'All';
      selectedStatus = 'All';
    });
    loadReports();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.onlyMine ? 'My Reports' : 'Lost & Found Reports'),
      ),
      drawer: MyDrawer(
        user: widget.user,
        currentSection: widget.onlyMine
            ? DrawerSection.myReports
            : DrawerSection.reports,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addReport,
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: RefreshIndicator(
            onRefresh: () => loadReports(page: currentPage),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                _buildFilterCard(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '$totalItems report${totalItems == 1 ? '' : 's'} found',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text('Page $currentPage of $totalPages'),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (reports.isEmpty)
                  const _EmptyReports()
                else
                  ...reports.map(
                    (report) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ReportCard(
                        report: report,
                        onTap: () => openReport(report),
                      ),
                    ),
                  ),
                if (!isLoading && totalPages > 1) _buildPagination(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => loadReports(),
              decoration: InputDecoration(
                labelText: 'Search item, description or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: loadReports,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 650;
                final fields = [
                  _filterDropdown(
                    label: 'Type',
                    value: selectedType,
                    values: const ['All', 'Lost', 'Found'],
                    onChanged: (value) => setState(() => selectedType = value),
                  ),
                  _filterDropdown(
                    label: 'Category',
                    value: selectedCategory,
                    values: categories,
                    onChanged: (value) =>
                        setState(() => selectedCategory = value),
                  ),
                  _filterDropdown(
                    label: 'Status',
                    value: selectedStatus,
                    values: const ['All', 'Unclaimed', 'Claimed'],
                    onChanged: (value) =>
                        setState(() => selectedStatus = value),
                  ),
                ];

                if (wide) {
                  return Row(
                    children: [
                      for (int index = 0; index < fields.length; index++) ...[
                        Expanded(child: fields[index]),
                        if (index < fields.length - 1)
                          const SizedBox(width: 10),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    for (int index = 0; index < fields.length; index++) ...[
                      fields[index],
                      if (index < fields.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loadReports,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Apply Filters'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(onPressed: clearFilters, child: const Text('Clear')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () => loadReports(page: currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$currentPage / $totalPages'),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => loadReports(page: currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off_outlined, size: 52, color: Colors.grey),
            SizedBox(height: 12),
            Text('No reports match your search.'),
          ],
        ),
      ),
    );
  }
}
