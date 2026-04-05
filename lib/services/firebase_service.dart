import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 unique device id
  final String deviceId = Random().nextInt(1000000).toString();

  // 🔥 listen only latest message
  Stream<QuerySnapshot> listenToMessages() {
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }

  // 🔥 send message
  Future<void> sendMessage(String message) async {
    try {
      await _firestore.collection('messages').add({
        'type': 'popup',
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sender': deviceId,
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }
}