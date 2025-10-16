// lib/services/ngo_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NgoService {
  final CollectionReference _ngos =
  FirebaseFirestore.instance.collection('ngos');

  /// ✅ Get stream of all NGOs
  Stream<QuerySnapshot> getAllNgos() {
    return _ngos.snapshots();
  }

  /// ✅ Get pending NGOs
  Stream<QuerySnapshot> getPendingNgos() {
    return _ngos.where('status', isEqualTo: 'Pending').snapshots();
  }

  /// ✅ Get approved NGOs
  Stream<QuerySnapshot> getApprovedNgos() {
    return _ngos.where('status', isEqualTo: 'Approved').snapshots();
  }

  /// ✅ Approve NGO
  Future<void> approveNgo(String docId) async {
    await _ngos.doc(docId).update({'status': 'Approved'});
  }

  /// ✅ Reject NGO
  Future<void> rejectNgo(String docId) async {
    await _ngos.doc(docId).update({'status': 'Rejected'});
  }

  /// ✅ Delete NGO (optional)
  Future<void> deleteNgo(String docId) async {
    await _ngos.doc(docId).delete();
  }
}
