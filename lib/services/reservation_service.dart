import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/reservation_model.dart';

class ReservationService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://eventapp-eacc6-default-rtdb.europe-west1.firebasedatabase.app',
  );

  Future<String?> reserver(ReservationModel reservation) async {
    try {
      // ── Vérifier les places disponibles AVANT de réserver ──────────────
      final eventSnap =
          await _database.ref('events/${reservation.eventId}').get();
      if (eventSnap.value == null) return null;

      final eventData = Map<String, dynamic>.from(eventSnap.value as Map);
      final int placesActuelles = eventData['placesDisponibles'] ?? 0;
      final String statutActuel = eventData['statut'] ?? 'Disponible';

      // ✅ Bloquer si plus de places ou événement complet
      if (placesActuelles <= 0 || statutActuel == 'Complet') {
        print('Réservation impossible : événement complet');
        return null;
      }
      if (reservation.nombrePlaces > placesActuelles) {
        print('Réservation impossible : pas assez de places');
        return null;
      }

      // ── Créer la réservation ────────────────────────────────────────────
      DatabaseReference ref = _database.ref('reservations').push();
      ReservationModel newRes = ReservationModel(
        id: ref.key!,
        eventId: reservation.eventId,
        userId: reservation.userId,
        userNom: reservation.userNom,
        eventTitre: reservation.eventTitre,
        nombrePlaces: reservation.nombrePlaces,
        prixTotal: reservation.prixTotal,
        statut: reservation.statut,
        dateReservation: reservation.dateReservation,
      );
      await ref.set(newRes.toJson());

      // ✅ Décrémenter les places et bloquer l'event si 0 places restantes
      await _mettreAJourPlaces(
          reservation.eventId, reservation.nombrePlaces, placesActuelles);

      return ref.key;
    } catch (e) {
      print('Erreur réservation: $e');
      return null;
    }
  }

  /// ✅ Décrémente les places et passe à 'Complet' si placesRestantes == 0
  Future<void> _mettreAJourPlaces(
      String eventId, int placesReservees, int placesActuelles) async {
    final int placesRestantes = placesActuelles - placesReservees;
    final String nouveauStatut =
        placesRestantes <= 0 ? 'Complet' : 'Disponible';
    await _database.ref('events/$eventId').update({
      'placesDisponibles': placesRestantes < 0 ? 0 : placesRestantes,
      'statut': nouveauStatut,
    });
  }

  /// Retourne le nombre total de places réservées pour un event
  Future<int> getNombreInscrits(String eventId) async {
    try {
      DataSnapshot snapshot = await _database.ref('reservations').get();
      if (snapshot.value == null) return 0;
      Map<dynamic, dynamic> data = snapshot.value as Map;
      int total = 0;
      data.forEach((key, value) {
        if (value is Map) {
          final res = Map<String, dynamic>.from(value);
          if (res['eventId'] == eventId) {
            total += (res['nombrePlaces'] as int? ?? 1);
          }
        }
      });
      return total;
    } catch (e) {
      print('Erreur getNombreInscrits: $e');
      return 0;
    }
  }

  /// ✅ Retourne toutes les réservations d'un utilisateur (plusieurs autorisées)
  Future<List<ReservationModel>> getMesReservations(String userId) async {
    try {
      DataSnapshot snapshot = await _database.ref('reservations').get();
      if (snapshot.value == null) return [];
      Map<dynamic, dynamic> data = snapshot.value as Map;
      List<ReservationModel> toutes = [];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            toutes.add(ReservationModel.fromJson(
                Map<String, dynamic>.from(value)));
          } catch (e) {
            print('Erreur parsing réservation: $e');
          }
        }
      });
      // Trier par date décroissante
      toutes.sort((a, b) => b.dateReservation.compareTo(a.dateReservation));
      return toutes.where((r) => r.userId == userId).toList();
    } catch (e) {
      print('Erreur mes réservations: $e');
      return [];
    }
  }

  /// ✅ Compte combien de fois un user a réservé un même event
  Future<int> nombreReservationsPourEvent(
      String eventId, String userId) async {
    try {
      DataSnapshot snapshot = await _database.ref('reservations').get();
      if (snapshot.value == null) return 0;
      Map<dynamic, dynamic> data = snapshot.value as Map;
      int count = 0;
      data.forEach((key, value) {
        if (value is Map) {
          final res = Map<String, dynamic>.from(value);
          if (res['eventId'] == eventId && res['userId'] == userId) {
            count++;
          }
        }
      });
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// ✅ Vérifie si un user peut encore réserver (max 2 fois par event)
  Future<bool> peutEncoreReserver(String eventId, String userId) async {
    int count = await nombreReservationsPourEvent(eventId, userId);
    return count < 2;
  }

  // Conservé pour compatibilité mais utilise peutEncoreReserver à la place
  Future<bool> dejaReserve(String eventId, String userId) async {
    try {
      DataSnapshot snapshot = await _database.ref('reservations').get();
      if (snapshot.value == null) return false;
      Map<dynamic, dynamic> data = snapshot.value as Map;
      bool trouve = false;
      data.forEach((key, value) {
        if (value is Map) {
          final res = Map<String, dynamic>.from(value);
          if (res['eventId'] == eventId && res['userId'] == userId) {
            trouve = true;
          }
        }
      });
      return trouve;
    } catch (e) {
      return false;
    }
  }

  Future<bool> confirmerReservation(String reservationId) async {
    try {
      DataSnapshot snapshot = await _database.ref('reservations').get();
      if (snapshot.value == null) return false;
      Map<dynamic, dynamic> data = snapshot.value as Map;
      String? firebaseKey;
      data.forEach((key, value) {
        if (value is Map && value['id'] == reservationId) {
          firebaseKey = key;
        }
      });
      if (firebaseKey != null) {
        await _database
            .ref('reservations/$firebaseKey')
            .update({'statut': 'Confirmée'});
      }
      return true;
    } catch (e) {
      print('Erreur confirmation: $e');
      return false;
    }
  }
}