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
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ReportModel> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() => isLoading = true);
    try {
      // Load all reports used for the dashboard totals and recent list.
      final uri = Uri.parse(ApiPath.endpoint('load_reports.php')).replace(
        queryParameters: const {
          'page': '1',
          'limit': '100',
          'search': '',
          'report_type': 'All',
          'category': 'All',
          'status': 'All',
        },
      );
      final response = await http.get(uri);
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Dashboard load failed');
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
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dashboard error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> addReport() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ReportFormScreen(user: widget.user)),
    );
    if (changed == true) loadDashboard();
  }

  Future<void> openReport(ReportModel report) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(user: widget.user, report: report),
      ),
    );
    if (changed == true) loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final lostCount = reports
        .where((report) => report.reportType == 'Lost')
        .length;
    final foundCount = reports
        .where((report) => report.reportType == 'Found')
        .length;
    final claimedCount = reports
        .where((report) => report.status == 'Claimed')
        .length;
    final myCount = reports
        .where((report) => report.userId == widget.user.id)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('UniFind Dashboard')),
      drawer: MyDrawer(
        user: widget.user,
        currentSection: DrawerSection.dashboard,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 18),
                      Text(
                        'Report Summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = constraints.maxWidth > 700
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SummaryCard(
                                width: cardWidth,
                                title: 'Lost Reports',
                                value: lostCount,
                                icon: Icons.search_off_rounded,
                                color: Colors.orange,
                              ),
                              _SummaryCard(
                                width: cardWidth,
                                title: 'Found Reports',
                                value: foundCount,
                                icon: Icons.inventory_2_outlined,
                                color: Colors.blue,
                              ),
                              _SummaryCard(
                                width: cardWidth,
                                title: 'Claimed Items',
                                value: claimedCount,
                                icon: Icons.task_alt,
                                color: Colors.green,
                              ),
                              _SummaryCard(
                                width: cardWidth,
                                title: 'My Reports',
                                value: myCount,
                                icon: Icons.person_pin_outlined,
                                color: Colors.indigo,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.add_circle_outline,
                              title: 'Report an Item',
                              onTap: addReport,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.manage_search,
                              title: 'Browse Reports',
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReportsScreen(user: widget.user),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Text(
                            'Recent Reports',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReportsScreen(user: widget.user),
                                ),
                              );
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (reports.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('No reports available yet.'),
                            ),
                          ),
                        )
                      else
                        ...reports
                            .take(5)
                            .map(
                              (report) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ReportCard(
                                  report: report,
                                  onTap: () => openReport(report),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F4B), Color(0xFF1264F5)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${widget.user.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Welcome to UniFind!',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFFDCE9FF),
              height: 1.4,
            ),
          ),
          const Text(
            'Your one-stop solution for lost and found items on campus.',
            style: TextStyle(color: Color(0xFFDCE9FF), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double width;
  final String title;
  final int value;
  final IconData icon;
  final MaterialColor color;

  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.shade50,
                child: Icon(icon, color: color.shade700),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(title, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            children: [
              Icon(
                icon,
                size: 34,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
