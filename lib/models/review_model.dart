class ReviewModel {
  final String id;
  final String eventId;
  final String userId;
  final String userNom;
  final double note;
  final String commentaire;
  final DateTime date;

  ReviewModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userNom,
    required this.note,
    required this.commentaire,
    required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      eventId: json['eventId'],
      userId: json['userId'],
      userNom: json['userNom'],
      note: json['note']?.toDouble() ?? 0.0,
      commentaire: json['commentaire'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userNom': userNom,
      'note': note,
      'commentaire': commentaire,
      'date': date.toIso8601String(),
    };
  }
}