import 'package:flutter/material.dart';

class ConnectionSettings extends StatelessWidget {
  final String? selectedServer;
  final List<Map<String, String>> connections;
  final bool usePayload;
  final bool useSSL;
  final bool useSlowDNS;
  final bool useXray;
  final ValueChanged<String?> onServerChanged;
  final ValueChanged<bool?> onPayloadChanged;
  final ValueChanged<bool?> onSSLChanged;
  final ValueChanged<bool?> onSlowDNSChanged;
  final ValueChanged<bool?> onXrayChanged;

  const ConnectionSettings({
    super.key,
    required this.selectedServer,
    required this.connections,
    required this.usePayload,
    required this.useSSL,
    required this.useSlowDNS,
    required this.useXray,
    required this.onServerChanged,
    required this.onPayloadChanged,
    required this.onSSLChanged,
    required this.onSlowDNSChanged,
    required this.onXrayChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Pastikan selectedServer ada dalam daftar connections
    final validSelectedServer = connections.any((connection) {
      final value = '${connection['address']}:${connection['port']}';
      return value == selectedServer;
    }) ? selectedServer : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: DropdownButton<String>(
            hint: const Text('Pilih Server'),
            value: validSelectedServer,
            onChanged: onServerChanged,
            items: connections.map<DropdownMenuItem<String>>((Map<String, String> connection) {
              final value = '${connection['address']}:${connection['port']}';
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            isExpanded: true,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: usePayload,
                        onChanged: onPayloadChanged,
                      ),
                      const Text('Use Payload'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: useSSL,
                        onChanged: onSSLChanged,
                      ),
                      const Text('SSL'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: useSlowDNS,
                        onChanged: onSlowDNSChanged,
                      ),
                      const Text('SlowDNS'),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: useXray,
                        onChanged: onXrayChanged,
                      ),
                      const Text('Xray'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
