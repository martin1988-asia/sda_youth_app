// lib/features/admin/add_incident_page.dart
import 'package:flutter/material.dart';
import 'package:sda_youth_app/services/security_queue_service.dart';

class AddIncidentPage extends StatefulWidget {
  const AddIncidentPage({super.key});

  @override
  State<AddIncidentPage> createState() => _AddIncidentPageState();
}

class _AddIncidentPageState extends State<AddIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedType = 'General Violation';
  String _selectedSeverity = 'Medium';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "ADD INCIDENT",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _userIdController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "User ID",
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter a user ID" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Reason",
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter a reason" : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedType, // fixed
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white),
                items: ['General Violation', 'Spam', 'Harassment']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedType = val ?? 'General Violation'),
                decoration: const InputDecoration(
                  labelText: "Type",
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedSeverity, // fixed
                dropdownColor: const Color(0xFF050505),
                style: const TextStyle(color: Colors.white),
                items: ['Low', 'Medium', 'High']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedSeverity = val ?? 'Medium'),
                decoration: const InputDecoration(
                  labelText: "Severity",
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFCC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitIncident,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "SUBMIT INCIDENT",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await SecurityQueueService.enqueueIncident(
        userId: _userIdController.text.trim(),
        reason: _reasonController.text.trim(),
        type: _selectedType,
        severity: _selectedSeverity.toLowerCase(),
      );
      if (!mounted) return; // guard context use
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Incident added successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to add incident"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
