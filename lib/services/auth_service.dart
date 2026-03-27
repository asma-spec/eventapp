import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://eventapp-eacc6-default-rtdb.europe-west1.firebasedatabase.app',
  );

  // ✅ Email admin unique
  static const String adminEmail = 'admin@gmail.com';

  Future<UserModel?> inscription({
    required String email,
    required String password,
    required String nom,
    required String role,
  }) async {
    try {
      // ✅ Bloquer l'inscription avec l'email admin
      if (email.trim().toLowerCase() == adminEmail) {
        print('Inscription impossible avec cet email réservé');
        return null;
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      UserModel user = UserModel(
        uid: result.user!.uid,
        email: email,
        nom: nom,
        role: role,
        billetGratuit: false,
      );
      await _database.ref('users/${result.user!.uid}').set(user.toJson());
      return user;
    } catch (e) {
      print('Erreur inscription: $e');
      return null;
    }
  }

  Future<UserModel?> connexion({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Si c'est l'admin, retourner un UserModel admin sans passer par la DB
      if (email.trim().toLowerCase() == adminEmail) {
        return UserModel(
          uid: result.user!.uid,
          email: adminEmail,
          nom: 'Administrateur',
          role: 'admin',
          billetGratuit: false,
        );
      }

      DataSnapshot snapshot = await _database
          .ref('users/${result.user!.uid}')
          .get();
      return UserModel.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      print('Erreur connexion: $e');
      return null;
    }
  }

  Future<void> deconnexion() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  // ✅ Initialiser le compte admin dans Firebase Auth (à appeler une seule fois)
  Future<void> initialiserCompteAdmin() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: 'admin123',
      );
      print('Compte admin créé avec succès');
    } catch (e) {
      // Déjà existant, pas de problème
      print('Compte admin déjà existant ou erreur: $e');
    }
  }
}