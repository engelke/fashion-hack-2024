import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Item>> getItems() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('clothes').get();
      return snapshot.docs.map((doc) {
        return Item.fromJson(
          doc.data() as Map<String, dynamic>,
          id: doc.id,
        );
      }).toList();
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
