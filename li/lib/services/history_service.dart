import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/scan_model.dart';

class HistoryService {
  HistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _historyRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('scan_history');
  }

  Future<void> addScan(String uid, ScanResult result) async {
    await _historyRef(uid).add(result.toFirestore());
  }

  Stream<List<ScanResult>> watchHistory(String uid) {
    return _historyRef(uid)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(ScanResult.fromFirestore).toList();
    });
  }
}
