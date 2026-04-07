import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? pairId;
  String? deviceId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    pairId = prefs.getString('pairId');
    deviceId = prefs.getString('deviceId');

    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('deviceId', deviceId!);
    }
  }

  Future<void> setPairId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pairId', id);
    pairId = id;
  }

  Stream<QuerySnapshot>? listenToMessages() {
    if (pairId == null) return null;

    return _firestore
        .collection('pairs')
        .doc(pairId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

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

  Future<void> sendStroke(
    List<Map<String, double>> points,
    int color,
    double width,
  ) async {
    if (pairId == null || points.isEmpty) return;

    await _firestore
        .collection('pairs')
        .doc(pairId)
        .collection('messages')
        .add({
      'type': 'stroke',
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'points': points,
      'color': color,
      'width': width,
      'isEraser': false,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sender': deviceId,
    });
  }

  Future<void> sendClearCanvas() async {
    if (pairId == null) return;

    await _firestore
        .collection('pairs')
        .doc(pairId)
        .collection('messages')
        .add({
      'type': 'clear',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sender': deviceId,
    });
  }
}