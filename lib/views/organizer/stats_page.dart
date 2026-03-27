import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import '../../services/reservation_service.dart';
import '../../services/review_service.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final EventService _eventService = EventService();
  final ReservationService _reservationService = ReservationService();
  final ReviewService _reviewService = ReviewService();

  List<EventModel> _mesEvents = [];
  Map<String, int> _reservationsParEvent = {};
  Map<String, double> _notesParEvent = {};
  Map<String, int> _avisParEvent = {}; // ✅ AJOUT : nombre d'avis par événement
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    final authProvider = context.read<AuthProvider>();
    List<EventModel> events =
        await _eventService.getEventsByOrganisateur(authProvider.user!.uid);

    Map<String, int> reservations = {};
    Map<String, double> notes = {};
    Map<String, int> avisCount = {}; // ✅ AJOUT

    for (EventModel event in events) {
      int inscrits = await _reservationService.getNombreInscrits(event.id);
      reservations[event.id] = inscrits;

      List<ReviewModel> avis =
          await _reviewService.getAvisParEvent(event.id);

      // ✅ AJOUT : stocker le nombre d'avis
      avisCount[event.id] = avis.length;

      if (avis.isNotEmpty) {
        double moyenne =
            avis.map((a) => a.note).reduce((a, b) => a + b) / avis.length;
        notes[event.id] = moyenne;
      } else {
        notes[event.id] = 0;
      }
    }

    setState(() {
      _mesEvents = events;
      _reservationsParEvent = reservations;
      _notesParEvent = notes;
      _avisParEvent = avisCount; // ✅ AJOUT
      _loading = false;
    });
  }

  // ✅ SUPPRIMÉ : _totalInscrits
  // ✅ AJOUT : total des avis
  int get _totalAvis =>
      _avisParEvent.values.fold(0, (a, b) => a + b);

  double get _noteMoyenneGlobale {
    List<double> notes =
        _notesParEvent.values.where((n) => n > 0).toList();
    if (notes.isEmpty) return 0;
    return notes.reduce((a, b) => a + b) / notes.length;
  }

  List<EventModel> get _eventsAVenir => _mesEvents
      .where((e) => e.date.isAfter(DateTime.now()) && e.statut != 'Passé')
      .toList();

  List<EventModel> get _eventsPasses => _mesEvents
      .where((e) => e.date.isBefore(DateTime.now()) || e.statut == 'Passé')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _chargerStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _carteResume(
                            icon: Icons.event,
                            titre: 'Total événements',
                            valeur: '${_mesEvents.length}',
                            couleur: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ✅ MODIFIÉ : "Total inscrits" → "Total avis"
                        Expanded(
                          child: _carteResume(
                            icon: Icons.rate_review,
                            titre: 'Total avis',
                            valeur: '$_totalAvis',
                            couleur: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _carteResume(
                            icon: Icons.star,
                            titre: 'Note moyenne',
                            valeur: _noteMoyenneGlobale == 0
                                ? 'N/A'
                                : _noteMoyenneGlobale.toStringAsFixed(1),
                            couleur: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _carteResume(
                            icon: Icons.upcoming,
                            titre: 'À venir',
                            valeur: '${_eventsAVenir.length}',
                            couleur: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_eventsAVenir.isNotEmpty) ...[
                      const Text(
                        'Événements à venir',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._eventsAVenir.map((e) => _carteEvent(e)),
                    ],
                    if (_eventsPasses.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Événements passés',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._eventsPasses.map((e) => _carteEvent(e)),
                    ],
                    if (_mesEvents.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.bar_chart,
                                  size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucun événement créé',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _carteResume({
    required IconData icon,
    required String titre,
    required String valeur,
    required Color couleur,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: couleur, size: 28),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titre,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _carteEvent(EventModel event) {
    int inscrits = _reservationsParEvent[event.id] ?? 0;
    double note = _notesParEvent[event.id] ?? 0;
    int nbAvis = _avisParEvent[event.id] ?? 0; // ✅ AJOUT
    bool estPasse =
        event.date.isBefore(DateTime.now()) || event.statut == 'Passé';

    int capaciteTotale = inscrits + event.placesDisponibles;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.titre,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estPasse
                        ? Colors.grey.shade200
                        : event.statut == 'Complet'
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estPasse ? 'Passé' : event.statut,
                    style: TextStyle(
                      color: estPasse
                          ? Colors.grey.shade700
                          : event.statut == 'Complet'
                              ? Colors.red.shade800
                              : Colors.green.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${event.date.day}/${event.date.month}/${event.date.year}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // ✅ MODIFIÉ : "inscrits" → "avis"
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.rate_review, size: 16, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        '$nbAvis avis',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        note == 0 ? 'Pas d\'avis' : note.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // La barre de progression reste sur les inscrits/capacité (inchangée)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: capaciteTotale == 0
                    ? 0
                    : inscrits / capaciteTotale,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  event.statut == 'Complet' ? Colors.red : Colors.deepPurple,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$inscrits / $capaciteTotale places',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}