import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/event_controller.dart';
import '../../state/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  bool _userEdited = false;

  @override
  void initState() {
    super.initState();
    final initialUrl = ref.read(
      settingsControllerProvider.select((s) => s.serverUrl),
    );
    _urlController = TextEditingController(text: initialUrl);
    ref.listen<SettingsState>(settingsControllerProvider, (previous, next) {
      if (!_userEdited && next.serverUrl != _urlController.text) {
        _urlController.text = next.serverUrl;
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final events = ref.watch(eventControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                backgroundColor: events.isConnected
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFFE4E6),
                label: Text(
                  events.isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: events.isConnected
                        ? const Color(0xFF065F46)
                        : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Raspberry Pi base URL',
                    hintText: 'http://192.168.0.20:8000',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _userEdited = true,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Enter the Raspberry Pi base URL (http/https).';
                    }
                    if (!trimmed.startsWith('http://') &&
                        !trimmed.startsWith('https://')) {
                      return 'URL must start with http:// or https://';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save & Apply'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: settings.isLoaded ? _onSave : null,
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: The app will poll /api/events every 2 seconds when a URL is set. '
                'Use the Simulate Event button on the dashboard for offline demos.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final url = _urlController.text.trim();
    final settingsController = ref.read(settingsControllerProvider.notifier);
    await settingsController.updateServerUrl(url);
    if (!mounted) return;
    _userEdited = false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Server URL saved.')));
  }
}
