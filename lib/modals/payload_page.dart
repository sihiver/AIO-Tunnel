import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PayloadModal extends StatefulWidget {
  const PayloadModal({super.key});

  @override
  State<PayloadModal> createState() => _PayloadModalState();
}

class _PayloadModalState extends State<PayloadModal> {
  final TextEditingController _payloadController = TextEditingController();
  final TextEditingController _remoteProxyController = TextEditingController();
  final FocusNode _payloadFocus = FocusNode();
  final FocusNode _remoteProxyFocus = FocusNode();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _payloadController.dispose();
    _remoteProxyController.dispose();
    _payloadFocus.dispose();
    _remoteProxyFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _payloadController.text = prefs.getString('payload') ?? '';
      _remoteProxyController.text = prefs.getString('remoteProxy') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    if (_payloadController.text.isEmpty || _remoteProxyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payload dan Remote Proxy tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('payload', _payloadController.text);
    await prefs.setString('remoteProxy', _remoteProxyController.text);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // 90% dari lebar layar
        height: MediaQuery.of(context).size.height * 0.7, // 70% dari tinggi layar
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Payload'),
            automaticallyImplyLeading: false, // Menghilangkan tombol kembali
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    
                    const Text(
                      'Payload',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _payloadController,
                      focusNode: _payloadFocus,
                      maxLines: 5,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan payload di sini...',
                      ),
                      onSubmitted: (_) => _remoteProxyFocus.requestFocus(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _remoteProxyController,
                      focusNode: _remoteProxyFocus,
                      decoration: const InputDecoration(
                        labelText: 'Remote Proxy',
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan remote proxy...',
                      ),
                      onSubmitted: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveData,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}