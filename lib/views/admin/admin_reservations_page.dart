import 'package:flutter/material.dart';
import '../../models/reservation_model.dart';
import '../../services/admin_service.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
  final AdminService _adminService = AdminService();
  List<ReservationModel> _reservations = [];
  List<ReservationModel> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final reservations = await _adminService.getToutesLesReservations();
    reservations.sort(
        (a, b) => b.dateReservation.compareTo(a.dateReservation));
    setState(() {
      _reservations = reservations;
      _filtered = reservations;
      _loading = false;
    });
  }

  void _filtrer(String query) {
    setState(() {
      _filtered = _reservations
          .where((r) =>
              r.userNom.toLowerCase().contains(query.toLowerCase()) ||
              r.eventTitre.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réservations (${_reservations.length})'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              onChanged: _filtrer,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou événement...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
              ? const Center(
                  child: Text('Aucune réservation',
                      style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final res = _filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── En-tête ──────────────────────────────
                              Row(
                                children: [
                                  const Icon(Icons.confirmation_number,
                                      color: Colors.deepPurple, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      res.eventTitre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ),
                                  _badgeStatut(res.statut),
                                ],
                              ),
                              const Divider(height: 16),
                              // ── Billet ───────────────────────────────
                              _ligneBillet(
                                  Icons.person, 'Utilisateur', res.userNom),
                              const SizedBox(height: 6),
                              _ligneBillet(
                                  Icons.event_seat,
                                  'Places réservées',
                                  '${res.nombrePlaces} place(s)'),
                              const SizedBox(height: 6),
                              _ligneBillet(
                                  Icons.attach_money,
                                  'Prix total',
                                  res.prixTotal == 0
                                      ? 'Gratuit'
                                      : '${res.prixTotal.toStringAsFixed(2)} €'),
                              const SizedBox(height: 6),
                              _ligneBillet(
                                  Icons.calendar_today,
                                  'Date réservation',
                                  '${res.dateReservation.day}/${res.dateReservation.month}/${res.dateReservation.year} '
                                      'à ${res.dateReservation.hour}h${res.dateReservation.minute.toString().padLeft(2, '0')}'),
                              const SizedBox(height: 6),
                              // ── ID Billet ─────────────────────────────
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.qr_code,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Billet #${res.id.substring(0, 8).toUpperCase()}',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _ligneBillet(IconData icon, String label, String valeur) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label : ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Expanded(
          child: Text(
            valeur,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _badgeStatut(String statut) {
    Color bg;
    Color fg;
    switch (statut.toLowerCase()) {
      case 'confirmée':
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case 'en attente':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(statut,
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}