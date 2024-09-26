import 'package:flutter/material.dart';
import 'start_stop_button.dart' as start_stop_button;

class CustomTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final start_stop_button.ConnectionState connectionState;

  const CustomTabBar({
    super.key,  // Tambahkan ini
    required this.controller,
    required this.tabs,
    required this.connectionState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Menggunakan warna button untuk indikator
    final indicatorColor = start_stop_button.getButtonColor(connectionState);

    return Container(
      height: 48,
      color: isDarkMode ? Colors.grey[900] : colorScheme.primary,
      child: TabBar(
        controller: controller,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        indicatorColor: indicatorColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }
}
