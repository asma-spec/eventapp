import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class OtpService {
  static const String _serviceId = 'service_abc123';
  static const String _templateId = 'template_tnw5jtl';
  static const String _publicKey = 'ZBi3vkQVDlMRqOwRt';

  // Code OTP stocké en mémoire
  static String? _otpCode;
  static DateTime? _otpExpiry;

  // ✅ Générer un code OTP à 6 chiffres
  static String genererCode() {
    final random = Random();
    _otpCode = (100000 + random.nextInt(900000)).toString();
    _otpExpiry = DateTime.now().add(const Duration(minutes: 10));
    return _otpCode!;
  }

  // ✅ Envoyer le code OTP par email via EmailJS
  static Future<bool> envoyerCode({
    required String email,
    required String nom,
  }) async {
    try {
      final code = genererCode();

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_name': nom,
            'to_email': email,
            'code': code,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Email OTP envoyé avec succès à $email');
        return true;
      } else {
        print('Erreur envoi OTP: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erreur envoi OTP: $e');
      return false;
    }
  }

  // ✅ Vérifier le code OTP saisi
  static bool verifierCode(String codeSaisi) {
    if (_otpCode == null || _otpExpiry == null) return false;

    // Vérifie si le code n'est pas expiré
    if (DateTime.now().isAfter(_otpExpiry!)) {
      print('Code OTP expiré');
      return false;
    }

    return codeSaisi.trim() == _otpCode;
  }

  // ✅ Effacer le code après utilisation
  static void effacerCode() {
    _otpCode = null;
    _otpExpiry = null;
  }

  // ✅ Vérifier si le code est encore valide
  static bool get estValide =>
      _otpCode != null &&
      _otpExpiry != null &&
      DateTime.now().isBefore(_otpExpiry!);
}