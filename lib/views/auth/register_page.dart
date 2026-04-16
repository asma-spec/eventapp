import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/otp_service.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _role = 'utilisateur';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _sendingOtp = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _envoyerOtpEtContinuer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sendingOtp = true);

    bool envoye = await OtpService.envoyerCode(
      email: _emailController.text.trim(),
      nom: _nomController.text.trim(),
    );

    setState(() => _sendingOtp = false);

    if (envoye) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationPage(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            nom: _nomController.text.trim(),
            role: _role,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi du code. Vérifiez votre email.'),
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
                child: FadeTransition(
                  opacity: _fadeAnim,
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
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE91E8C)
                                      .withOpacity(0.5),
                                  blurRadius: 20,
                                )
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/eventify_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1A003A),
                                  child: const Icon(Icons.bolt,
                                      color: Color(0xFFFFD700), size: 26),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE0AAFF)],
                            ).createShader(b),
                            child: const Text(
                              'Eventify',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Créer un compte ✨',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rejoignez des milliers de passionnés\nd\'événements en Tunisie',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.55),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Formulaire ─────────────────────────────────────
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Nom ──────────────────────────────────
                          _label('Nom complet'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _nomController,
                            hint: 'Votre nom et prénom',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v!.trim().isEmpty
                                ? 'Entrez votre nom'
                                : null,
                          ),
                          const SizedBox(height: 18),

                          // ── Email ─────────────────────────────────
                          _label('Adresse email'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _emailController,
                            hint: 'votre@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v!.trim().isEmpty) {
                                return 'Entrez votre email';
                              }
                              final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Email invalide (ex: nom@domaine.com)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // ── Mot de passe ──────────────────────────
                          _label('Mot de passe'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _passwordController,
                            hint: 'Minimum 6 caractères',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscurePassword,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF7000FF),
                                size: 20,
                              ),
                            ),
                            validator: (v) => v!.length < 6
                                ? 'Minimum 6 caractères'
                                : null,
                          ),
                          const SizedBox(height: 18),

                          // ── Confirmer mot de passe ────────────────
                          _label('Confirmer le mot de passe'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _confirmPasswordController,
                            hint: 'Répétez votre mot de passe',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureConfirmPassword,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                              child: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF7000FF),
                                size: 20,
                              ),
                            ),
                            validator: (v) {
                              if (v!.isEmpty) {
                                return 'Confirmez votre mot de passe';
                              }
                              if (v != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── Sélecteur rôle ──────────────────────
                          _label('Je suis un(e)'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _RoleCard(
                                  role: 'utilisateur',
                                  label: 'Participant',
                                  subtitle: 'Explorer & réserver',
                                  emoji: '🎟',
                                  selected: _role == 'utilisateur',
                                  onTap: () => setState(
                                      () => _role = 'utilisateur'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RoleCard(
                                  role: 'organisateur',
                                  label: 'Organisateur',
                                  subtitle: 'Créer des events',
                                  emoji: '🎤',
                                  selected: _role == 'organisateur',
                                  onTap: () => setState(
                                      () => _role = 'organisateur'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // ── Bouton ───────────────────────────────
                          // ✅ context.read au lieu de watch
                          // ✅ loading = seulement _sendingOtp
                          _SubmitButton(
                            label: 'Créer mon compte',
                            loading: _sendingOtp,
                            onTap: _envoyerOtpEtContinuer,
                          ),
                          const SizedBox(height: 24),

                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, '/login'),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Déjà un compte ?  ',
                                  style: TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: 'Se connecter',
                                      style: TextStyle(
                                        color: Color(0xFF7000FF),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        decoration:
                                            TextDecoration.underline,
                                        decorationColor:
                                            Color(0xFF7000FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B003A),
          letterSpacing: 0.2,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1B003A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        prefixIcon:
            Icon(icon, color: const Color(0xFF7000FF), size: 20),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF7000FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role, label, subtitle, emoji;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.label,
    required this.subtitle,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE91E8C), Color(0xFF7B2FFF)],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : const Color(0xFFEEEEEE),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B2FFF).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : const Color(0xFFCCCCCC),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                          size: 13, color: Color(0xFF7B2FFF))
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color:
                    selected ? Colors.white : const Color(0xFF1B003A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SubmitButton(
      {required this.label, required this.loading, required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
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
            child: widget.loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}