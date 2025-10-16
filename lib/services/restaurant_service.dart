// lib/services/restaurant_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantService {
  final CollectionReference _restaurants =
  FirebaseFirestore.instance.collection('restaurants');

  /// ✅ Get stream of all restaurants (real-time updates)
  Stream<QuerySnapshot> getAllRestaurants() {
    return _restaurants.snapshots();
  }

  /// ✅ Get only pending restaurants
  Stream<QuerySnapshot> getPendingRestaurants() {
    return _restaurants.where('status', isEqualTo: 'Pending').snapshots();
  }

  /// ✅ Get only approved restaurants
  Stream<QuerySnapshot> getApprovedRestaurants() {
    return _restaurants.where('status', isEqualTo: 'Approved').snapshots();
  }

  /// ✅ Approve a restaurant
  Future<void> approveRestaurant(String docId) async {
    await _restaurants.doc(docId).update({'status': 'Approved'});
  }

  /// ✅ Reject a restaurant
  Future<void> rejectRestaurant(String docId) async {
    await _restaurants.doc(docId).update({'status': 'Rejected'});
  }

  /// ✅ Delete restaurant (optional)
  Future<void> deleteRestaurant(String docId) async {
    await _restaurants.doc(docId).delete();
  }
}
