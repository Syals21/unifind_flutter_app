import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../views/home_screen.dart';
import '../views/login_screen.dart';
import '../views/profile_screen.dart';
import '../views/reports_screen.dart';

enum DrawerSection { dashboard, reports, myReports, profile }

class MyDrawer extends StatelessWidget {
  final UserModel user;
  final DrawerSection currentSection;

  const MyDrawer({super.key, required this.user, required this.currentSection});

  void _open(BuildContext context, DrawerSection section, Widget screen) {
    Navigator.pop(context);
    if (currentSection == section) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B1F4B), Color(0xFF1264F5)],
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user.name.isEmpty ? 'U' : user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF155EEF),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              accountName: Text(user.name),
              accountEmail: Text(user.email),
            ),
            ListTile(
              selected: currentSection == DrawerSection.dashboard,
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => _open(
                context,
                DrawerSection.dashboard,
                HomeScreen(user: user),
              ),
            ),
            ListTile(
              selected: currentSection == DrawerSection.reports,
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('All Reports'),
              onTap: () => _open(
                context,
                DrawerSection.reports,
                ReportsScreen(user: user),
              ),
            ),
            ListTile(
              selected: currentSection == DrawerSection.myReports,
              leading: const Icon(Icons.person_pin_outlined),
              title: const Text('My Reports'),
              onTap: () => _open(
                context,
                DrawerSection.myReports,
                ReportsScreen(user: user, onlyMine: true),
              ),
            ),
            ListTile(
              selected: currentSection == DrawerSection.profile,
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('My Profile'),
              onTap: () => _open(
                context,
                DrawerSection.profile,
                ProfileScreen(user: user),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
