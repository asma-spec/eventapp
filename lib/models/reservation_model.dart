class ReservationModel {
  final String id;
  final String eventId;
  final String userId;
  final String userNom;
  final String eventTitre;
  final int nombrePlaces;
  final double prixTotal;
  final String statut;
  final DateTime dateReservation;

  ReservationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userNom,
    required this.eventTitre,
    required this.nombrePlaces,
    required this.prixTotal,
    required this.statut,
    required this.dateReservation,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'],
      eventId: json['eventId'],
      userId: json['userId'],
      userNom: json['userNom'],
      eventTitre: json['eventTitre'],
      nombrePlaces: json['nombrePlaces'],
      prixTotal: json['prixTotal']?.toDouble() ?? 0.0,
      statut: json['statut'],
      dateReservation: DateTime.parse(json['dateReservation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userNom': userNom,
      'eventTitre': eventTitre,
      'nombrePlaces': nombrePlaces,
      'prixTotal': prixTotal,
      'statut': statut,
      'dateReservation': dateReservation.toIso8601String(),
    };
  }
}