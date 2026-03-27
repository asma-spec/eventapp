class UserModel {
  final String uid;
  final String email;
  final String nom;
  final String role; // 'organisateur', 'utilisateur', 'admin'
  final bool billetGratuit; // ✅ AJOUT : billet gratuit gagné

  UserModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.role,
    this.billetGratuit = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      nom: json['nom'],
      role: json['role'],
      billetGratuit: json['billetGratuit'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nom': nom,
      'role': role,
      'billetGratuit': billetGratuit,
    };
  }
}