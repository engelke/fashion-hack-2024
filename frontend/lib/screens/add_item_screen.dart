import 'package:flutter/material.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Item Name',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter item name',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement image selection
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Primary Image'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement additional images
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Additional Images'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: const Text('Color'),
                  onDeleted: () {},
                ),
                Chip(
                  label: const Text('Style'),
                  onDeleted: () {},
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement save functionality
                Navigator.pop(context);
              },
              child: const Text('Add Item to Closet'),
            ),
          ],
        ),
      ),
    );
  }
}
