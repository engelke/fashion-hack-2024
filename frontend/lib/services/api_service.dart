import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _baseUrl =
      'https://getsignedurl-348449317363.us-central1.run.app';
  static const String _bucketName = 'fashion-hacks-2024-uploads';

  Future<String?> getSignedUrl(String imageUrl) async {
    try {
      // Extract filename, handling both full URLs and just filenames
      final filename =
          imageUrl.contains('/') ? imageUrl.split('/').last : imageUrl;

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/getSignedUrl?bucket=$_bucketName&filename=$filename'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['signedUrl'];
      } else {
        print(
            'Failed to get signed URL: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting signed URL: $e');
      return null;
    }
  }

  Future<List<Item>> getItems() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('clothes').get();
      final items = snapshot.docs.map((doc) {
        return Item.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }).toList();

      // After getting items, get signed URLs for their images
      final List<Item> validItems = [];
      for (var item in items) {
        if (item.imageUrl.isNotEmpty) {
          try {
            final signedUrl = await getSignedUrl(item.imageUrl);
            if (signedUrl != null) {
              validItems.add(item.copyWith(imageUrl: signedUrl));
            }
          } catch (e) {
            print('Error getting signed URL for item ${item.id}: $e');
          }
        }
      }
      return validItems;
    } catch (e) {
      print('Error fetching items: $e');
      return [];
    }
  }

  Future<Item?> addItem(Item item) async {
    try {
      final docRef = await _firestore.collection('clothes').add(item.toJson());
      final doc = await docRef.get();
      if (doc.exists) {
        return Item.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error adding item: $e');
      return null;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _firestore.collection('clothes').doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting item: $e');
      return false;
    }
  }
}
