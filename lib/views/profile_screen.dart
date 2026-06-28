import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_path.dart';
import '../widgets/my_drawer.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  bool isEditing = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    phoneController = TextEditingController(text: widget.user.phone);
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse(ApiPath.endpoint('update_profile.php')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': widget.user.id,
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Profile update failed');
      }

      widget.user.name = nameController.text.trim();
      widget.user.phone = phoneController.text.trim();
      final prefs = await SharedPreferences.getInstance();
      // Keep the saved session in sync with the updated profile.
      await prefs.setString('current_user', jsonEncode(widget.user.toJson()));

      if (!mounted) return;
      setState(() => isEditing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'].toString())));
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
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: () => setState(() => isEditing = !isEditing),
            icon: Icon(isEditing ? Icons.close : Icons.edit_outlined),
          ),
        ],
      ),
      drawer: MyDrawer(
        user: widget.user,
        currentSection: DrawerSection.profile,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: const Color(0xFFE8F0FF),
                        child: Text(
                          widget.user.name.isEmpty
                              ? 'U'
                              : widget.user.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF155EEF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.user.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nameController,
                        enabled: isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: widget.user.email,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: phoneController,
                        enabled: isEditing,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: _required,
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : saveProfile,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              isSaving ? 'Saving...' : 'Save Changes',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
