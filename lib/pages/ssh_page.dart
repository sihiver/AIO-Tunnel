import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import '../widgets/account_dialog.dart';
import '../widgets/connection_list.dart';


class SSHPage extends StatefulWidget {
  const SSHPage({super.key, required this.onConnectionChanged});

  final VoidCallback onConnectionChanged;

  @override
  SSHPageState createState() => SSHPageState();
}

class SSHPageState extends State<SSHPage> {
  List<Map<String, String>> _connections = [];
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final String? connectionsString = prefs.getString('connections');
    if (connectionsString != null) {
      setState(() {
        _connections = List<Map<String, String>>.from(
          json.decode(connectionsString).map(
            (item) => Map<String, String>.from(item),
          ),
        );
      });
    }
  }

  Future<void> _saveConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final String connectionsString = json.encode(_connections);
    await prefs.setString('connections', connectionsString);
    _logger.i('Saved connections: $_connections');
    widget.onConnectionChanged();
  }

  void _addAkun() {
    final TextEditingController serverController = TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AccountDialog(
          serverController: serverController,
          usernameController: usernameController,
          passwordController: passwordController,
          onSave: () {
            final server = serverController.text;
            final parts = server.split(':');
            if (parts.length == 2) {
              final address = parts[0];
              final port = parts[1];
              setState(() {
                _connections.add({
                  'address': address,
                  'port': port,
                  'username': usernameController.text,
                  'password': passwordController.text,
                });
              });
              _saveConnections();
              _closeDialog();
            } else {
              _showSnackBar('Format server harus IP:Port');
            }
          },
          title: 'Tambah Akun SSH',
          saveButtonText: 'Tambah',
        );
      },
    );
  }

  void _closeDialog() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _editAkun(int index) {
    final TextEditingController serverController = TextEditingController(
      text: '${_connections[index]['address']}:${_connections[index]['port']}',
    );
    final TextEditingController usernameController = TextEditingController(text: _connections[index]['username']);
    final TextEditingController passwordController = TextEditingController(text: _connections[index]['password']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AccountDialog(
          serverController: serverController,
          usernameController: usernameController,
          passwordController: passwordController,
          onSave: () {
            final server = serverController.text;
            final parts = server.split(':');
            if (parts.length == 2) {
              final address = parts[0];
              final port = parts[1];
              setState(() {
                _connections[index] = {
                  'address': address,
                  'port': port,
                  'username': usernameController.text,
                  'password': passwordController.text,
                };
              });
              _saveConnections();
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Format server harus IP:Port')),
              );
            }
          },
          title: 'Edit Akun SSH',
          saveButtonText: 'Simpan',
        );
      },
    );
  }

  void _removeConnection(int index) {
    setState(() {
      _connections.removeAt(index);
    });
    _saveConnections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: ConnectionList(
        connections: _connections,
        onEdit: _editAkun,
        onDelete: _removeConnection,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAkun,
        tooltip: 'Tambah Akun',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}