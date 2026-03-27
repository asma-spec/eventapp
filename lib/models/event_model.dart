class EventModel {
  final String id;
  final String titre;
  final String categorie;
  final String description;
  final DateTime date;
  final String lieu;
  final double latitude;
  final double longitude;
  final int placesDisponibles;
  final double prix;
  final String organisateurId;
  final String organisateurNom;
  final String statut;

  EventModel({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.description,
    required this.date,
    required this.lieu,
    required this.latitude,
    required this.longitude,
    required this.placesDisponibles,
    required this.prix,
    required this.organisateurId,
    required this.organisateurNom,
    this.statut = 'Disponible',
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      titre: json['titre'],
      categorie: json['categorie'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      lieu: json['lieu'],
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      placesDisponibles: json['placesDisponibles'],
      prix: json['prix']?.toDouble() ?? 0.0,
      organisateurId: json['organisateurId'],
      organisateurNom: json['organisateurNom'],
      statut: json['statut'] ?? 'Disponible',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'categorie': categorie,
      'description': description,
      'date': date.toIso8601String(),
      'lieu': lieu,
      'latitude': latitude,
      'longitude': longitude,
      'placesDisponibles': placesDisponibles,
      'prix': prix,
      'organisateurId': organisateurId,
      'organisateurNom': organisateurNom,
      'statut': statut,
    };
  }
}