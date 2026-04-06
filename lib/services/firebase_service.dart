import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? pairId;
  String? deviceId;

  // ✅ INIT (must be awaited before use)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    pairId = prefs.getString('pairId');
    deviceId = prefs.getString('deviceId');

    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('deviceId', deviceId!);
    }
  }

  // ✅ Save pair ID
  Future<void> setPairId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pairId', id);
    pairId = id;
  }

  // ✅ SAFE stream (no crash)
  Stream<QuerySnapshot>? listenToMessages() {
    if (pairId == null) return null;

    return _firestore
        .collection('pairs')
        .doc(pairId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }

  // ✅ Send message
  Future<void> sendMessage(String message) async {
    if (pairId == null) return;

    await _firestore
        .collection('pairs')
        .doc(pairId)
        .collection('messages')
        .add({
      'type': 'popup',
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sender': deviceId,
    });
  }
}