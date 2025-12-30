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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _StatusBanner(isConnected: events.isConnected),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Server',
                child: TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Raspberry Pi base URL',
                    hintText: 'http://192.168.0.20:8000',
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
              _SectionCard(
                title: 'Calibration',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startController,
                            decoration: const InputDecoration(
                              labelText: 'Start point (cm)',
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
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validateDouble,
                      onChanged: (_) => _userEdited = true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save & Apply'),
                onPressed: settings.isLoaded ? _onSave : null,
              ),
              const SizedBox(height: 12),
              const _NoteCard(
                text:
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server URL saved.')),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isConnected});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final background = isConnected
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEE2E2);
    final border = isConnected
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFFECACA);
    final textColor = isConnected
        ? const Color(0xFF065F46)
        : const Color(0xFFB91C1C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isConnected ? Icons.wifi : Icons.wifi_off, color: textColor),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration([double radius = 16]) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  );
}
