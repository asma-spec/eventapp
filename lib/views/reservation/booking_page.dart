import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/reservation_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/reservation_service.dart';
import '../../services/admin_service.dart';
import 'payment_page.dart';

class BookingPage extends StatefulWidget {
  final EventModel event;

  const BookingPage({super.key, required this.event});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final ReservationService _reservationService = ReservationService();
  final AdminService _adminService = AdminService();

  int _nombrePlaces = 1;
  bool _loading = false;
  bool _checkingBillet = true;
  bool _aBilletGratuit = false;        // ✅ billet gratuit attribué par admin
  bool _utiliserBilletGratuit = false; // ✅ l'user choisit de l'utiliser
  int _nombreDejaReserve = 0;

  bool get _estBloque =>
      widget.event.placesDisponibles <= 0 ||
      widget.event.statut == 'Complet' ||
      widget.event.statut == 'Passé' ||
      widget.event.date.isBefore(DateTime.now());

  // ✅ Prix calculé : 0 si billet gratuit coché, sinon prix normal
  double get _prixTotal {
    if (_utiliserBilletGratuit) return 0.0;
    return _nombrePlaces * widget.event.prix;
  }

  @override
  void initState() {
    super.initState();
    _verifierBilletEtReservations();
  }

  Future<void> _verifierBilletEtReservations() async {
    final authProvider = context.read<AuthProvider>();
    final String uid = authProvider.user!.uid;

    // Vérifier le billet gratuit depuis la DB
    try {
      final snapshot = await _adminService.getUserData(uid);
      if (snapshot != null) {
        setState(() => _aBilletGratuit = snapshot.billetGratuit);
      }
    } catch (_) {}

    // Vérifier combien de fois déjà réservé
    int count = await _reservationService.nombreReservationsPourEvent(
        widget.event.id, uid);

    setState(() {
      _nombreDejaReserve = count;
      _checkingBillet = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    // ✅ Limite 2 réservations par user par event
    final bool limiteAtteinte = _nombreDejaReserve >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _checkingBillet
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Carte infos événement ───────────────────────────
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.titre,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.event.date.day}/${widget.event.date.month}/${widget.event.date.year}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.location_on,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(widget.event.lieu,
                                style: const TextStyle(color: Colors.grey)),
                          ]),
                          const SizedBox(height: 4),
                          // ✅ Places restantes en temps réel
                          Row(children: [
                            const Icon(Icons.event_seat,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              widget.event.placesDisponibles <= 0
                                  ? 'Aucune place disponible'
                                  : '${widget.event.placesDisponibles} place(s) restante(s)',
                              style: TextStyle(
                                color: widget.event.placesDisponibles <= 0
                                    ? Colors.red
                                    : Colors.grey,
                                fontWeight: widget.event.placesDisponibles <= 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ]),
                          // Badge bloqué
                          if (_estBloque) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.event.statut == 'Passé' ||
                                        widget.event.date
                                            .isBefore(DateTime.now())
                                    ? 'Événement terminé'
                                    : 'Événement complet — réservation impossible',
                                style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Billet gratuit disponible
                  if (_aBilletGratuit && !_estBloque && !limiteAtteinte)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.confirmation_number,
                                  color: Colors.amber),
                              SizedBox(width: 8),
                              Text(
                                '🎟 Vous avez un billet gratuit !',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'L\'admin vous a offert une réservation gratuite. Voulez-vous l\'utiliser pour cette réservation ?',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Checkbox(
                                value: _utiliserBilletGratuit,
                                activeColor: Colors.amber.shade700,
                                onChanged: (val) => setState(
                                    () => _utiliserBilletGratuit =
                                        val ?? false),
                              ),
                              const Text('Utiliser mon billet gratuit'),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // ✅ Indicateur réservations déjà faites
                  if (_nombreDejaReserve > 0 && !_estBloque && !limiteAtteinte)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Vous avez déjà réservé $_nombreDejaReserve fois — il vous reste ${2 - _nombreDejaReserve} réservation(s) possible(s)',
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Contenu principal ───────────────────────────────
                  if (!_estBloque && !limiteAtteinte) ...[
                    const Text('Nombre de places',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _nombrePlaces > 1
                              ? () => setState(() => _nombrePlaces--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 36,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 24),
                        Text('$_nombrePlaces',
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 24),
                        IconButton(
                          onPressed:
                              _nombrePlaces < widget.event.placesDisponibles
                                  ? () => setState(() => _nombrePlaces++)
                                  : null,
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 36,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Prix total ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _utiliserBilletGratuit
                            ? Colors.green.shade50
                            : Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Prix total',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              if (_utiliserBilletGratuit &&
                                  widget.event.prix > 0) ...[
                                Text(
                                  '${(_nombrePlaces * widget.event.prix).toStringAsFixed(2)} DT',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _utiliserBilletGratuit
                                    ? 'Gratuit 🎟'
                                    : widget.event.prix == 0
                                        ? 'Gratuit'
                                        : '${_prixTotal.toStringAsFixed(2)} DT',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _utiliserBilletGratuit
                                      ? Colors.green
                                      : Colors.deepPurple.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Bouton réserver ─────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _loading ? null : () => _confirmerReservation(authProvider),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Continuer vers le paiement',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ] else ...[
                    // ── Message bloqué ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            limiteAtteinte
                                ? Icons.how_to_reg
                                : widget.event.statut == 'Passé' ||
                                        widget.event.date
                                            .isBefore(DateTime.now())
                                    ? Icons.event_busy
                                    : Icons.block,
                            size: 60,
                            color: limiteAtteinte
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            limiteAtteinte
                                ? 'Limite atteinte : vous avez réservé 2 fois cet événement'
                                : widget.event.statut == 'Passé' ||
                                        widget.event.date
                                            .isBefore(DateTime.now())
                                    ? 'Cet événement est terminé'
                                    : 'Cet événement est complet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: limiteAtteinte
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            limiteAtteinte
                                ? 'Vous avez atteint le maximum de réservations pour cet événement'
                                : 'La réservation n\'est plus disponible',
                            style:
                                const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _confirmerReservation(dynamic authProvider) async {
    setState(() => _loading = true);

    double prixFinal = _utiliserBilletGratuit ? 0.0 : _prixTotal;

    ReservationModel reservation = ReservationModel(
      id: '',
      eventId: widget.event.id,
      userId: authProvider.user!.uid,
      userNom: authProvider.user!.nom,
      eventTitre: widget.event.titre,
      nombrePlaces: _nombrePlaces,
      prixTotal: prixFinal,
      statut: 'En attente',
      dateReservation: DateTime.now(),
    );

    String? reservationId =
        await _reservationService.reserver(reservation);
    setState(() => _loading = false);

    if (reservationId != null) {
      // ✅ Si billet gratuit utilisé, le retirer de la DB
      if (_utiliserBilletGratuit) {
        await _adminService.retirerBilletGratuit(authProvider.user!.uid);
      }

      ReservationModel reservationAvecId = ReservationModel(
        id: reservationId,
        eventId: reservation.eventId,
        userId: reservation.userId,
        userNom: reservation.userNom,
        eventTitre: reservation.eventTitre,
        nombrePlaces: reservation.nombrePlaces,
        prixTotal: prixFinal,
        statut: reservation.statut,
        dateReservation: reservation.dateReservation,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            reservation: reservationAvecId,
            event: widget.event,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Réservation impossible : événement complet ou erreur'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}// Booking
