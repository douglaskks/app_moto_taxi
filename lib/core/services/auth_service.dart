// Arquivo: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_models.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obter usuário atual
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Login com email e senha
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Registro com email e senha
  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sair
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  // Criar perfil de usuário
  Future<void> createUserProfile(UserModel user) {
    return _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  // Obter perfil de usuário
  Future<UserModel> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    } else {
      throw Exception('Usuário não encontrado');
    }
  }

  // Atualizar tipo de usuário
  Future<void> updateUserType(String userId, String userType) {
    return _firestore.collection('users').doc(userId).update({
      'userType': userType,
    });
  }
}