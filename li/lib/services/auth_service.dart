import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  UserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (cred.user == null) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Failed to create account.',
      );
    }

    await cred.user!.updateDisplayName(name.trim());
    await cred.user!.reload();
    final refreshed = _firebaseAuth.currentUser!;
    await _firestore.collection('users').doc(refreshed.uid).set({
      'name': name.trim(),
      'email': refreshed.email ?? email.trim(),
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return UserModel(
      uid: refreshed.uid,
      email: refreshed.email ?? email.trim(),
      displayName: refreshed.displayName,
    );
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (cred.user == null) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Failed to sign in.',
      );
    }

    return UserModel(
      uid: cred.user!.uid,
      email: cred.user!.email ?? email.trim(),
      displayName: cred.user!.displayName,
    );
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}
