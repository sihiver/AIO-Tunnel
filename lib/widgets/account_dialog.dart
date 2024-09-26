import 'package:flutter/material.dart';

class AccountDialog extends StatelessWidget {
  final TextEditingController serverController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onSave;
  final String title;
  final String saveButtonText;

  const AccountDialog({
    super.key,
    required this.serverController,
    required this.usernameController,
    required this.passwordController,
    required this.onSave,
    required this.title,
    required this.saveButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextField(
              controller: serverController,
              decoration: const InputDecoration(labelText: 'Server (IP:Port)'),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Batal'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          onPressed: onSave,
          child: Text(saveButtonText),
        ),
      ],
    );
  }
}
