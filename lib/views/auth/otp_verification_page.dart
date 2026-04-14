import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/otp_service.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String password;
  final String nom;
  final String role;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.password,
    required this.nom,
    required this.role,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _renvoyerLoading = false;
  int _secondesRestantes = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _demarrerTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _demarrerTimer() {
    _secondesRestantes = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondesRestantes == 0) {
        timer.cancel();
      } else {
        setState(() => _secondesRestantes--);
      }
    });
  }

  // Récupère le code complet depuis les 6 champs
  String get _codeSaisi =>
      _controllers.map((c) => c.text).join();

  Future<void> _verifier() async {
    if (_codeSaisi.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez le code complet à 6 chiffres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    // Vérifier le code OTP
    bool codeCorrect = OtpService.verifierCode(_codeSaisi);

    if (!codeCorrect) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code incorrect ou expiré'),
          backgroundColor: Colors.red,
        ),
      );
      // Vider les champs
      for (var c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      return;
    }

    // Code correct → créer le compte Firebase
    final authProvider = context.read<AuthProvider>();
    bool success = await authProvider.inscription(
      email: widget.email,
      password: widget.password,
      nom: widget.nom,
      role: widget.role,
    );

    setState(() => _loading = false);
    OtpService.effacerCode();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      final erreur = authProvider.errorMessage ?? 'Erreur lors de l\'inscription';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erreur),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _renvoyerCode() async {
    setState(() => _renvoyerLoading = true);

    bool envoye = await OtpService.envoyerCode(
      email: widget.email,
      nom: widget.nom,
    );

    setState(() => _renvoyerLoading = false);

    if (envoye) {
      _demarrerTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nouveau code envoyé !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 44),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF060010),
                      Color(0xFF1B003A),
                      Color(0xFF7000FF),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 17),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Icône email
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.mark_email_read_outlined,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Vérification email 📧',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un code à 6 chiffres a été envoyé à\n${widget.email}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Corps ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: Column(
                  children: [
                    const Text(
                      'Entrez le code reçu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B003A),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 6 champs OTP ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 48,
                          height: 60,
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7000FF),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFEEEEEE)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFFEEEEEE)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF7000FF), width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                // Passer au champ suivant
                                _focusNodes[index + 1].requestFocus();
                              }
                              if (value.isEmpty && index > 0) {
                                // Revenir au champ précédent
                                _focusNodes[index - 1].requestFocus();
                              }
                              // Si tous les champs remplis → vérifier auto
                              if (_codeSaisi.length == 6) {
                                _verifier();
                              }
                            },
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // ── Bouton vérifier ───────────────────────────
                    GestureDetector(
                      onTap: _loading ? null : _verifier,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E8C), Color(0xFF7B2FFF)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B2FFF).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Confirmer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Renvoyer le code ──────────────────────────
                    _secondesRestantes > 0
                        ? Text(
                            'Renvoyer le code dans $_secondesRestantes s',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          )
                        : GestureDetector(
                            onTap: _renvoyerLoading ? null : _renvoyerCode,
                            child: _renvoyerLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text(
                                    'Renvoyer le code',
                                    style: TextStyle(
                                      color: Color(0xFF7000FF),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF7000FF),
                                    ),
                                  ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}