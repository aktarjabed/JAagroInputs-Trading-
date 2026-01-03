import 'package:flutter/material.dart';
import 'company_settings_tab.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Company Profile', icon: Icon(Icons.business)),
              Tab(text: 'App Info', icon: Icon(Icons.info_outline)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CompanySettingsTab(),
            Center(child: Text('App Info & About - Coming Soon')),
          ],
        ),
      ),
    );
  }
}
