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

    } on FirebaseAuthException catch (e) {
      // ✅ Gestion précise des erreurs Firebase Auth
      switch (e.code) {
        case 'email-already-in-use':
          print('Erreur : cet email est déjà utilisé');
          throw Exception('Cet email est déjà associé à un compte existant');
        case 'invalid-email':
          print('Erreur : format email invalide');
          throw Exception('Le format de l\'email est invalide');
        case 'weak-password':
          print('Erreur : mot de passe trop faible');
          throw Exception('Le mot de passe est trop faible');
        case 'network-request-failed':
          throw Exception('Pas de connexion internet');
        default:
          print('Erreur inscription Firebase: ${e.code}');
          throw Exception('Erreur lors de l\'inscription : ${e.message}');
      }
    } catch (e) {
      print('Erreur inscription: $e');
      rethrow;
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

      // ✅ Si c'est l'admin
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

    } on FirebaseAuthException catch (e) {
      // ✅ Gestion précise des erreurs de connexion
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Aucun compte trouvé avec cet email');
        case 'wrong-password':
          throw Exception('Mot de passe incorrect');
        case 'invalid-email':
          throw Exception('Format email invalide');
        case 'user-disabled':
          throw Exception('Ce compte a été désactivé');
        case 'too-many-requests':
          throw Exception('Trop de tentatives, réessayez plus tard');
        case 'network-request-failed':
          throw Exception('Pas de connexion internet');
        default:
          throw Exception('Erreur de connexion : ${e.message}');
      }
    } catch (e) {
      print('Erreur connexion: $e');
      rethrow;
    }
  }

  Future<void> deconnexion() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Future<void> initialiserCompteAdmin() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: 'admin123',
      );
      print('Compte admin créé avec succès');
    } catch (e) {
      print('Compte admin déjà existant ou erreur: $e');
    }
  }
}
// Service d'authentification