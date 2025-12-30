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
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _laneController;

  @override
  void initState() {
    super.initState();
    final initialUrl = ref.read(
      settingsControllerProvider.select((s) => s.serverUrl),
    );
    final start = ref.read(settingsControllerProvider.select((s) => s.startCm));
    final end = ref.read(settingsControllerProvider.select((s) => s.endCm));
    final lane = ref.read(settingsControllerProvider.select((s) => s.laneCm));
    _urlController = TextEditingController(text: initialUrl);
    _startController = TextEditingController(text: start.toString());
    _endController = TextEditingController(text: end.toString());
    _laneController = TextEditingController(text: lane.toString());
    ref.listen<SettingsState>(settingsControllerProvider, (previous, next) {
      if (!_userEdited && next.serverUrl != _urlController.text) {
        _urlController.text = next.serverUrl;
      }
      if (!_userEdited) {
        _startController.text = next.startCm.toString();
        _endController.text = next.endCm.toString();
        _laneController.text = next.laneCm.toString();
      }
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _laneController.dispose();
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startController,
                      decoration: const InputDecoration(
                        labelText: 'Start point (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validateDouble,
                      onChanged: (_) => _userEdited = true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _endController,
                      decoration: const InputDecoration(
                        labelText: 'End point (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validateDouble,
                      onChanged: (_) => _userEdited = true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _laneController,
                decoration: const InputDecoration(
                  labelText: 'Lane Y (cm, 0~20)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validateDouble,
                onChanged: (_) => _userEdited = true,
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
                'Use the dashboard controls for demo if no device is connected.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateDouble(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Value required';
    if (double.tryParse(trimmed) == null) return 'Enter a number';
    return null;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final url = _urlController.text.trim();
    final start = double.parse(_startController.text.trim());
    final end = double.parse(_endController.text.trim());
    final lane = double.parse(_laneController.text.trim());
    final settingsController = ref.read(settingsControllerProvider.notifier);
    await settingsController.updateServerUrl(url);
    await settingsController.updateCalibration(
      start: start,
      end: end,
      lane: lane,
    );
    if (!mounted) return;
    _userEdited = false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Server URL saved.')));
  }
}
