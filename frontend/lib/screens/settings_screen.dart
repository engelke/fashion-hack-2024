import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Account'),
            leading: const Icon(Icons.person),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement account settings
            },
          ),
          ListTile(
            title: const Text('Notifications'),
            leading: const Icon(Icons.notifications),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notifications toggle
              },
            ),
          ),
          ListTile(
            title: const Text('Theme'),
            leading: const Icon(Icons.palette),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement theme settings
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description),
            onTap: () {
              // TODO: Show terms of service
            },
          ),
          ListTile(
            title: const Text('About'),
            leading: const Icon(Icons.info),
            onTap: () {
              // TODO: Show about dialog
            },
          ),
        ],
      ),
    );
  }
}
