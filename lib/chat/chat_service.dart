import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  /// 🔹 Create or get chat between current user and partner
  Future<String> createChat({required String partnerId}) async {
    final chats = await _db
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    // check if chat already exists
    for (var doc in chats.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(partnerId)) {
        return doc.id; // already exists
      }
    }

    // create new chat
    final newChat = await _db.collection('chats').add({
      'participants': [currentUserId, partnerId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }
}
