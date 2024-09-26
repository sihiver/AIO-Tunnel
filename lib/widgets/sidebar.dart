import 'package:flutter/material.dart';
import '../modals/payload_page.dart';
import '../modals/sni_page.dart';
import '../pages/home_page.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final String appName;
  final String appVersion;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.appName,
    required this.appVersion,
  });

  void _navigateToHomeAndShowModal(BuildContext context, Widget modal) {
    Navigator.of(context).pop(); // Tutup drawer sebelum navigasi
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => HomePage(
          appName: appName,
          appVersion: appVersion,
          showModal: modal,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  void _navigateToPage(BuildContext context, String routeName, int index) {
    Navigator.of(context).pop();
    onItemTapped(index);
    if (routeName == '/home') {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => HomePage(
            appName: appName,
            appVersion: appVersion,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            currentAccountPicture: const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/logo.png'), // Ganti dengan path logo Anda
            ),
            accountName: Text(
              appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            accountEmail: Text(
              'Version $appVersion',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(), // Tanda pemisah antar kategori
          const ListTile(title: Text('Utility')),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Payload'),
            selected: selectedIndex == 3,
            onTap: () => _navigateToHomeAndShowModal(context, const PayloadModal()),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('SNI'),
            selected: selectedIndex == 4,
            onTap: () => _navigateToHomeAndShowModal(context, const SNIModal()),
          ),
          const Divider(), // Tanda pemisah antar kategori
          const ListTile(title: Text('Connection')),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('SSH'),
            selected: selectedIndex == 1,
            onTap: () => _navigateToPage(context, '/ssh', 1),
          ),
          const Divider(), // Tanda pemisah antar kategori
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            selected: selectedIndex == 2,
            onTap: () => _navigateToPage(context, '/settings', 2),
          ),
        ],
      ),
    );
  }
}