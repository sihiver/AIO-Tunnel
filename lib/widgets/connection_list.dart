import 'package:flutter/material.dart';

class ConnectionList extends StatelessWidget {
  final List<Map<String, String>> connections;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const ConnectionList({
    super.key,
    required this.connections,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: connections.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text('${connections[index]['address']}:${connections[index]['port']}'),
            subtitle: Text(connections[index]['username']!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onDelete(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
