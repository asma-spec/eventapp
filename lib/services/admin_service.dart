import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/reservation_model.dart';

class AdminService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://eventapp-eacc6-default-rtdb.europe-west1.firebasedatabase.app',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── USER UNIQUE ──────────────────────────────────────────────────────────

  /// ✅ Récupérer les données d'un utilisateur par uid (utilisé dans BookingPage)
  Future<UserModel?> getUserData(String uid) async {
    try {
      DataSnapshot snapshot = await _database.ref('users/$uid').get();
      if (snapshot.value == null) return null;
      return UserModel.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      print('Erreur getUserData: $e');
      return null;
    }
  }

  // ─── USERS ────────────────────────────────────────────────────────────────

  Future<List<UserModel>> getTousLesUtilisateurs() async {
    try {
      DataSnapshot snapshot = await _database.ref('users').get();
      if (snapshot.value == null) return [];
      Map<dynamic, dynamic> data = snapshot.value as Map;
      List<UserModel> users = [];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            users.add(UserModel.fromJson(Map<String, dynamic>.from(value)));
          } catch (e) {
            print('Erreur parsing user: $e');
          }
        }
      });
      return users.where((u) => u.role != 'admin').toList();
    } catch (e) {
      print('Erreur getTousLesUtilisateurs: $e');
      return [];
    }
  }

  Future<List<UserModel>> getOrganisateurs() async {
    List<UserModel> tous = await getTousLesUtilisateurs();
    return tous.where((u) => u.role == 'organisateur').toList();
  }

  Future<List<UserModel>> getUtilisateursClassiques() async {
    List<UserModel> tous = await getTousLesUtilisateurs();
    return tous.where((u) => u.role == 'utilisateur').toList();
  }

  Future<bool> supprimerUtilisateur(String uid) async {
    try {
      await _database.ref('users/$uid').remove();
      DataSnapshot resSnap = await _database.ref('reservations').get();
      if (resSnap.value != null) {
        Map<dynamic, dynamic> resData = resSnap.value as Map;
        resData.forEach((key, value) async {
          if (value is Map && value['userId'] == uid) {
            await _database.ref('reservations/$key').remove();
          }
        });
      }
      return true;
    } catch (e) {
      print('Erreur suppression utilisateur: $e');
      return false;
    }
  }

  // ─── EVENTS ───────────────────────────────────────────────────────────────

  Future<List<EventModel>> getTousLesEvents() async {
    try {
      DataSnapshot snapshot = await _database.ref('events').get();
      if (snapshot.value == null) return [];
      Map<dynamic, dynamic> data = snapshot.value as Map;
      List<EventModel> events = [];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            events.add(EventModel.fromJson(Map<String, dynamic>.from(value)));
          } catch (e) {
            print('Erreur parsing event: $e');
          }
        }
      });
      return events;
    } catch (e) {
      print('Erreur getTousLesEvents: $e');
      return [];
    }
  }

  Future<bool> supprimerEvent(String eventId) async {
    try {
      await _database.ref('events/$eventId').remove();
      return true;
    } catch (e) {
      print('Erreur suppression event admin: $e');
      return false;
    }
  }

  Future<bool> modifierEvent(EventModel event) async {
    try {
      await _database.ref('events/${event.id}').update(event.toJson());
      return true;
    } catch (e) {
      print('Erreur modification event admin: $e');
      return false;
    }
  }

  // ─── RESERVATIONS ─────────────────────────────────────────────────────────

  Future<List<ReservationModel>> getToutesLesReservations() async {
    try {
      DataSnapshot snapshot = await _database.ref('reservations').get();
      if (snapshot.value == null) return [];
      Map<dynamic, dynamic> data = snapshot.value as Map;
      List<ReservationModel> reservations = [];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            reservations.add(
                ReservationModel.fromJson(Map<String, dynamic>.from(value)));
          } catch (e) {
            print('Erreur parsing réservation: $e');
          }
        }
      });
      return reservations;
    } catch (e) {
      print('Erreur getToutesLesReservations: $e');
      return [];
    }
  }

  // ─── STATISTIQUES ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getOrganisateurLePlusActif() async {
    try {
      List<EventModel> events = await getTousLesEvents();
      List<UserModel> organisateurs = await getOrganisateurs();
      if (organisateurs.isEmpty) return null;

      Map<String, int> compteur = {};
      for (EventModel e in events) {
        compteur[e.organisateurId] = (compteur[e.organisateurId] ?? 0) + 1;
      }
      if (compteur.isEmpty) return null;

      String meilleureUid =
          compteur.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      UserModel? meilleur =
          organisateurs.where((u) => u.uid == meilleureUid).firstOrNull;
      if (meilleur == null) return null;

      return {
        'user': meilleur,
        'nombreEvents': compteur[meilleureUid] ?? 0,
      };
    } catch (e) {
      print('Erreur organisateur le plus actif: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUtilisateurLePlusActif() async {
    try {
      List<ReservationModel> reservations = await getToutesLesReservations();
      List<UserModel> utilisateurs = await getUtilisateursClassiques();
      if (utilisateurs.isEmpty) return null;

      Map<String, int> compteur = {};
      for (ReservationModel r in reservations) {
        compteur[r.userId] = (compteur[r.userId] ?? 0) + r.nombrePlaces;
      }
      if (compteur.isEmpty) return null;

      String meilleureUid =
          compteur.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      UserModel? meilleur =
          utilisateurs.where((u) => u.uid == meilleureUid).firstOrNull;
      if (meilleur == null) return null;

      return {
        'user': meilleur,
        'nombreReservations': compteur[meilleureUid] ?? 0,
      };
    } catch (e) {
      print('Erreur utilisateur le plus actif: $e');
      return null;
    }
  }

  /// ✅ Attribuer un billet gratuit
  Future<bool> attribuerBilletGratuit(String userId) async {
    try {
      await _database.ref('users/$userId').update({'billetGratuit': true});
      return true;
    } catch (e) {
      print('Erreur attribution billet gratuit: $e');
      return false;
    }
  }

  /// ✅ Retirer le billet gratuit après utilisation
  Future<bool> retirerBilletGratuit(String userId) async {
    try {
      await _database.ref('users/$userId').update({'billetGratuit': false});
      return true;
    } catch (e) {
      print('Erreur retrait billet gratuit: $e');
      return false;
    }
  }
}// Service admin
