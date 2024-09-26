import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SNIModal extends StatefulWidget {
  const SNIModal({super.key});

  @override
  State<SNIModal> createState() => _SNIModalState();
}

class _SNIModalState extends State<SNIModal> {
  final TextEditingController _sniController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSNI();
  }

  @override
  void dispose() {
    _sniController.dispose();
    super.dispose();
  }

  Future<void> _loadSNI() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sniController.text = prefs.getString('sni') ?? '';
    });
  }

  Future<void> _saveSNI() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sni', _sniController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SNI berhasil disimpan')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SNI'),
          automaticallyImplyLeading: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _sniController,
                decoration: const InputDecoration(
                  labelText: 'SNI',
                  border: OutlineInputBorder(),
                  hintText: 'Masukkan SNI di sini...',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveSNI,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // full width
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