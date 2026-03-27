import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/reservation_service.dart';
import '../reservation/booking_page.dart';
import 'reviews_page.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final ReservationService _reservationService = ReservationService();
  int _nombreReservations = 0; // ✅ Nombre de fois que le user a réservé cet event
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verifierReservation();
  }

  Future<void> _verifierReservation() async {
    final authProvider = context.read<AuthProvider>();
    final event = ModalRoute.of(context)!.settings.arguments as EventModel;
    int count = await _reservationService.nombreReservationsPourEvent(
      event.id,
      authProvider.user!.uid,
    );
    setState(() {
      _nombreReservations = count;
      _loading = false;
    });
  }

  // ✅ true si le user a atteint 2 réservations pour cet event
  bool get _limiteAtteinte => _nombreReservations >= 2;

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)!.settings.arguments as EventModel;
    final authProvider = context.read<AuthProvider>();

    final bool estComplet = event.statut == 'Complet' ||
        event.placesDisponibles <= 0;
    final bool estPasse = event.statut == 'Passé' ||
        event.date.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(event.titre),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: Colors.deepPurple.shade50,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.categorie,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.titre,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Par ${event.organisateurNom}',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.calendar_today,
                      '${event.date.day}/${event.date.month}/${event.date.year} à ${event.date.hour}h${event.date.minute.toString().padLeft(2, '0')}'),
                  const SizedBox(height: 12),
                  _infoRow(Icons.location_on, event.lieu),
                  const SizedBox(height: 12),
                  // ✅ Affichage places restantes dynamique
                  _infoRow(
                    Icons.people,
                    estComplet
                        ? 'Aucune place disponible'
                        : '${event.placesDisponibles} place(s) restante(s)',
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.attach_money,
                      event.prix == 0 ? 'Gratuit' : '${event.prix} DT'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: estComplet || estPasse
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estPasse
                          ? 'Passé'
                          : estComplet
                              ? 'Complet'
                              : 'Disponible',
                      style: TextStyle(
                        color: estComplet || estPasse
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Description ──────────────────────────────────────
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(event.description,
                      style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 20),

                  // ── Carte ─────────────────────────────────────────────
                  const Text('Localisation',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (event.latitude != 0.0 && event.longitude != 0.0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter:
                                LatLng(event.latitude, event.longitude),
                            initialZoom: 14,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.eventapp',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                      event.latitude, event.longitude),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_pin,
                                      color: Colors.red, size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_off, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Localisation non disponible',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Bouton réserver (utilisateur uniquement) ──────────
                  if (!authProvider.isOrganisateur && !authProvider.isAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : estPasse
                              ? _messageBloque(
                                  Icons.event_busy,
                                  'Cet événement est terminé',
                                  Colors.grey)
                              : estComplet
                                  ? _messageBloque(
                                      Icons.block,
                                      'Événement complet — réservation impossible',
                                      Colors.red)
                                  : _limiteAtteinte
                                      // ✅ Limite 2 réservations atteinte
                                      ? _messageBloque(
                                          Icons.how_to_reg,
                                          'Limite atteinte : vous avez déjà réservé 2 fois cet événement',
                                          Colors.orange)
                                      : Column(
                                          children: [
                                            // ✅ Indicateur nb réservations déjà faites
                                            if (_nombreReservations > 0)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color:
                                                          Colors.blue.shade200),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.info_outline,
                                                        size: 16,
                                                        color: Colors.blue),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Vous avez déjà réservé $_nombreReservations fois — il vous reste ${2 - _nombreReservations} réservation(s)',
                                                      style: const TextStyle(
                                                          color: Colors.blue,
                                                          fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.deepPurple,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        BookingPage(
                                                            event: event),
                                                  ),
                                                ).then(
                                                    (_) => _verifierReservation());
                                              },
                                              child: const Text('Réserver',
                                                  style:
                                                      TextStyle(fontSize: 16)),
                                            ),
                                          ],
                                        ),
                    ),

                  const SizedBox(height: 12),

                  // ── Bouton avis ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.rate_review,
                          color: Colors.deepPurple),
                      label: const Text('Voir les avis',
                          style: TextStyle(
                              color: Colors.deepPurple, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        side:
                            const BorderSide(color: Colors.deepPurple),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewsPage(event: event),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }

  Widget _messageBloque(IconData icon, String message, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: couleur),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: couleur, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}