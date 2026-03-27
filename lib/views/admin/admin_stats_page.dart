import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

class _AdminStatsPageState extends State<AdminStatsPage> {
  final AdminService _adminService = AdminService();
  bool _loading = true;

  int _totalEvents = 0;
  int _totalReservations = 0;
  int _totalOrganisateurs = 0;
  int _totalUtilisateurs = 0;

  Map<String, dynamic>? _orgActif;
  Map<String, dynamic>? _userActif;
  bool _billetAttribue = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);

    final events = await _adminService.getTousLesEvents();
    final reservations = await _adminService.getToutesLesReservations();
    final orgs = await _adminService.getOrganisateurs();
    final utils = await _adminService.getUtilisateursClassiques();
    final orgActif = await _adminService.getOrganisateurLePlusActif();
    final userActif = await _adminService.getUtilisateurLePlusActif();

    // Vérifier si le billet est déjà attribué
    bool billetDejaAttribue = false;
    if (userActif != null) {
      final UserModel u = userActif['user'];
      billetDejaAttribue = u.billetGratuit;
    }

    setState(() {
      _totalEvents = events.length;
      _totalReservations = reservations.length;
      _totalOrganisateurs = orgs.length;
      _totalUtilisateurs = utils.length;
      _orgActif = orgActif;
      _userActif = userActif;
      _billetAttribue = billetDejaAttribue;
      _loading = false;
    });
  }

  Future<void> _attribuerBillet() async {
    if (_userActif == null) return;
    final UserModel user = _userActif!['user'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attribuer un billet gratuit'),
        content: Text(
            'Attribuer un billet gratuit pour la prochaine réservation de ${user.nom} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer',
                  style: TextStyle(color: Colors.deepPurple))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _adminService.attribuerBilletGratuit(user.uid);
      if (success) {
        setState(() => _billetAttribue = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎟 Billet gratuit attribué à ${user.nom} !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _retirerBillet() async {
    if (_userActif == null) return;
    final UserModel user = _userActif!['user'];
    await _adminService.retirerBilletGratuit(user.uid);
    setState(() => _billetAttribue = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Billet gratuit retiré pour ${user.nom}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques globales'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _charger,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Chiffres clés ──────────────────────────────────
                    const Text('Vue d\'ensemble',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _carteChiffre(Icons.event, 'Événements',
                            '$_totalEvents', Colors.deepPurple),
                        _carteChiffre(Icons.bookmark, 'Réservations',
                            '$_totalReservations', Colors.teal),
                        _carteChiffre(Icons.business, 'Organisateurs',
                            '$_totalOrganisateurs', Colors.indigo),
                        _carteChiffre(Icons.person, 'Utilisateurs',
                            '$_totalUtilisateurs', Colors.green),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Organisateur le plus actif ─────────────────────
                    const Text('🏆 Organisateur le plus actif',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _orgActif == null
                        ? _carteVide('Aucun organisateur avec des événements')
                        : _carteChampion(
                            user: _orgActif!['user'] as UserModel,
                            label:
                                '${_orgActif!['nombreEvents']} événement(s) créé(s)',
                            couleur: Colors.deepPurple,
                            badge: '🎤',
                          ),
                    const SizedBox(height: 24),

                    // ── Utilisateur le plus actif ──────────────────────
                    const Text('🥇 Utilisateur le plus actif',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _userActif == null
                        ? _carteVide('Aucun utilisateur avec des réservations')
                        : _carteChampionUtilisateur(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _carteChiffre(
      IconData icon, String label, String valeur, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: couleur, size: 22),
              const SizedBox(width: 6),
              Text(valeur,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: couleur)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _carteChampion({
    required UserModel user,
    required String label,
    required Color couleur,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [couleur.withOpacity(0.15), couleur.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: couleur.withOpacity(0.2),
            child: Text(badge, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nom,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(user.email,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: couleur, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteChampionUtilisateur() {
    final UserModel user = _userActif!['user'];
    final int nbRes = _userActif!['nombreReservations'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.withOpacity(0.15),
            Colors.teal.withOpacity(0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.teal.withOpacity(0.2),
                child: const Text('🥇', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.nom,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        if (_billetAttribue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('🎟 Billet attribué',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.orange)),
                          ),
                      ],
                    ),
                    Text(user.email,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('$nbRes place(s) réservée(s) au total',
                        style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Bouton billet gratuit ──────────────────────────────
          SizedBox(
            width: double.infinity,
            child: _billetAttribue
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.orange),
                    label: const Text('Retirer le billet gratuit',
                        style: TextStyle(color: Colors.orange)),
                    onPressed: _retirerBillet,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.confirmation_number),
                    label: const Text(
                        'Attribuer un billet gratuit 🎟'),
                    onPressed: _attribuerBillet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _carteVide(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center),
      ),
    );
  }
}