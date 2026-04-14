import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<Organization?> getOrganization(String uid) async {
    final doc = await _db.collection('organizations').doc(uid).get();
    if (!doc.exists) return null;
    return Organization.fromFirestore(doc);
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String orgName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('organizations').doc(cred.user!.uid).set(
      Organization(
        id: cred.user!.uid,
        name: orgName,
        email: email,
        createdAt: DateTime.now(),
      ).toFirestore(),
    );
  }

  Future<void> signOut() => _auth.signOut();

  // Future<void> resetPassword(String email) =>
  //     _auth.sendPasswordResetEmail(email: email);

  
  Future<void> resetPassword(String email) async {
  try {
    await _auth.sendPasswordResetEmail(email: email.trim());
  } on FirebaseAuthException catch (e) {
    throw Exception(e.message ?? 'An error occurred while sending the reset link');
  }
}
}