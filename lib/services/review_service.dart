import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://eventapp-eacc6-default-rtdb.europe-west1.firebasedatabase.app',
  );

  Future<bool> ajouterAvis(ReviewModel review) async {
    try {
      DatabaseReference ref = _database.ref('reviews').push();
      ReviewModel newReview = ReviewModel(
        id: ref.key!,
        eventId: review.eventId,
        userId: review.userId,
        userNom: review.userNom,
        note: review.note,
        commentaire: review.commentaire,
        date: review.date,
      );
      await ref.set(newReview.toJson());
      return true;
    } catch (e) {
      print('Erreur ajout avis: $e');
      return false;
    }
  }

  Future<List<ReviewModel>> getAvisParEvent(String eventId) async {
    try {
      DataSnapshot snapshot = await _database.ref('reviews').get();
      if (snapshot.value == null) return [];
      Map<dynamic, dynamic> data = snapshot.value as Map;
      List<ReviewModel> tous = [];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            tous.add(ReviewModel.fromJson(Map<String, dynamic>.from(value)));
          } catch (e) {
            print('Erreur parsing avis: $e');
          }
        }
      });
      return tous.where((r) => r.eventId == eventId).toList();
    } catch (e) {
      print('Erreur récupération avis: $e');
      return [];
    }
  }

  /// ✅ AJOUT : récupérer tous les avis d'un utilisateur
  Future<List<ReviewModel>> getMesAvis(String userId) async {
    try {
      DataSnapshot snapshot = await _database.ref('reviews').get();
      if (snapshot.value == null) return [];
      Map<dynamic, dynamic> data = snapshot.value as Map;
      List<ReviewModel> tous = [];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            tous.add(ReviewModel.fromJson(Map<String, dynamic>.from(value)));
          } catch (e) {
            print('Erreur parsing avis: $e');
          }
        }
      });
      return tous.where((r) => r.userId == userId).toList();
    } catch (e) {
      print('Erreur getMesAvis: $e');
      return [];
    }
  }

  Future<bool> dejaNote(String eventId, String userId) async {
    try {
      List<ReviewModel> avis = await getAvisParEvent(eventId);
      return avis.any((r) => r.userId == userId);
    } catch (e) {
      return false;
    }
  }
}