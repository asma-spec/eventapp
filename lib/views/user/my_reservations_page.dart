import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/reservation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/reservation_service.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  final ReservationService _reservationService = ReservationService();
  List<ReservationModel> _reservations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerReservations();
  }

  Future<void> _chargerReservations() async {
    final authProvider = context.read<AuthProvider>();
    List<ReservationModel> reservations =
        await _reservationService.getMesReservations(authProvider.user!.uid);
    setState(() {
      _reservations = reservations;
      _loading = false;
    });
  }

  void _afficherQR(ReservationModel reservation) {
    String qrData =
        'EVENTAPP|${reservation.id}|${reservation.eventTitre}|${reservation.nombrePlaces}|${reservation.prixTotal}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Mon billet'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  reservation.eventTitre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 250,
                  ),
                ),
                const SizedBox(height: 24),
                _billetRow('Places', '${reservation.nombrePlaces}'),
                _billetRow(
                  'Total',
                  reservation.prixTotal == 0
                      ? 'Gratuit'
                      : '${reservation.prixTotal.toStringAsFixed(2)} DT',
                ),
                _billetRow('Statut', reservation.statut),
                _billetRow(
                  'Date réservation',
                  '${reservation.dateReservation.day}/${reservation.dateReservation.month}/${reservation.dateReservation.year}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _billetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucune réservation',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Réservez un événement pour le voir ici',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerReservations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reservations.length,
                    itemBuilder: (context, index) {
                      ReservationModel res = _reservations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      res.eventTitre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: res.statut == 'Confirmée'
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      res.statut,
                                      style: TextStyle(
                                        color: res.statut == 'Confirmée'
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.people,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${res.nombrePlaces} place(s)',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.attach_money,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    res.prixTotal == 0
                                        ? 'Gratuit'
                                        : '${res.prixTotal.toStringAsFixed(2)} DT',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${res.dateReservation.day}/${res.dateReservation.month}/${res.dateReservation.year}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    icon: const Icon(Icons.qr_code,
                                        color: Colors.deepPurple),
                                    label: const Text(
                                      'Mon billet',
                                      style: TextStyle(
                                          color: Colors.deepPurple),
                                    ),
                                    onPressed: () => _afficherQR(res),
                                  ),
                                ],
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
}