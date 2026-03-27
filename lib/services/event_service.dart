import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://eventapp-eacc6-default-rtdb.europe-west1.firebasedatabase.app',
  );

  Future<bool> creerEvent(EventModel event) async {
    try {
      DatabaseReference ref = _database.ref('events').push();
      EventModel newEvent = EventModel(
        id: ref.key!,
        titre: event.titre,
        categorie: event.categorie,
        description: event.description,
        date: event.date,
        lieu: event.lieu,
        latitude: event.latitude,
        longitude: event.longitude,
        placesDisponibles: event.placesDisponibles,
        prix: event.prix,
        organisateurId: event.organisateurId,
        organisateurNom: event.organisateurNom,
        statut: event.statut,
      );
      await ref.set(newEvent.toJson());
      return true;
    } catch (e) {
      print('Erreur création event: $e');
      return false;
    }
  }

  Future<List<EventModel>> getEvents() async {
    try {
      DataSnapshot snapshot = await _database.ref('events').get();
      if (snapshot.value == null) return [];
      Map<dynamic, dynamic> data = snapshot.value as Map;
      List<EventModel> events = [];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            EventModel event = EventModel.fromJson(
                Map<String, dynamic>.from(value));
            events.add(event);
          } catch (e) {
            print('Erreur parsing event: $e');
          }
        }
      });
      await _mettreAJourStatutsPasses(events);
      return events;
    } catch (e) {
      print('Erreur récupération events: $e');
      return [];
    }
  }

  Future<void> _mettreAJourStatutsPasses(List<EventModel> events) async {
    DateTime maintenant = DateTime.now();
    for (EventModel event in events) {
      if (event.date.isBefore(maintenant) && event.statut != 'Passé') {
        await _database.ref('events/${event.id}').update({
          'statut': 'Passé',
        });
      }
    }
  }

  Future<List<EventModel>> getEventsByOrganisateur(String organisateurId) async {
    try {
      List<EventModel> tous = await getEvents();
      return tous.where((e) => e.organisateurId == organisateurId).toList();
    } catch (e) {
      print('Erreur events organisateur: $e');
      return [];
    }
  }

  Future<bool> modifierEvent(EventModel event, String organisateurId) async {
    try {
      if (event.organisateurId != organisateurId) {
        print('Non autorisé : cet événement ne vous appartient pas');
        return false;
      }
      if (event.date.isBefore(DateTime.now())) {
        print('Non autorisé : événement passé');
        return false;
      }
      await _database.ref('events/${event.id}').update(event.toJson());
      return true;
    } catch (e) {
      print('Erreur modification event: $e');
      return false;
    }
  }

  Future<bool> supprimerEvent(String eventId, String organisateurId) async {
    try {
      DataSnapshot snapshot = await _database.ref('events/$eventId').get();
      if (snapshot.value == null) return false;
      Map<String, dynamic> event =
          Map<String, dynamic>.from(snapshot.value as Map);
      if (event['organisateurId'] != organisateurId) {
        print('Non autorisé : cet événement ne vous appartient pas');
        return false;
      }
      await _database.ref('events/$eventId').remove();
      return true;
    } catch (e) {
      print('Erreur suppression event: $e');
      return false;
    }
  }
}