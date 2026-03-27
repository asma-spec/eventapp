import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class AllEventsPage extends StatefulWidget {
  const AllEventsPage({super.key});

  @override
  State<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends State<AllEventsPage> {
  final EventService _eventService = EventService();
  List<EventModel> _allEvents = [];
  List<EventModel> _filtered = [];
  bool _loading = true;
  String _selectedCategorie = 'Tous';
  String _selectedStatut = 'Tous';

  final List<String> _categories = [
    'Tous', 'Musique', 'Sport', 'Art', 'Théâtre', 'Cinéma', 'Conférence', 'Autre'
  ];
  final List<String> _statuts = ['Tous', 'Disponible', 'Complet', 'Passé'];

  @override
  void initState() {
    super.initState();
    _chargerTousLesEvents();
  }

  Future<void> _chargerTousLesEvents() async {
    setState(() => _loading = true);
    final events = await _eventService.getEvents();
    // Tri : à venir en premier, puis passés
    events.sort((a, b) {
      final aPasse = a.date.isBefore(DateTime.now());
      final bPasse = b.date.isBefore(DateTime.now());
      if (aPasse && !bPasse) return 1;
      if (!aPasse && bPasse) return -1;
      return a.date.compareTo(b.date);
    });
    setState(() {
      _allEvents = events;
      _filtered = events;
      _loading = false;
    });
  }

  void _appliquerFiltres() {
    setState(() {
      _filtered = _allEvents.where((e) {
        final estPasse = e.date.isBefore(DateTime.now()) || e.statut == 'Passé';
        final statutAffiche = estPasse ? 'Passé' : e.statut;
        final matchCat =
            _selectedCategorie == 'Tous' || e.categorie == _selectedCategorie;
        final matchStatut =
            _selectedStatut == 'Tous' || statutAffiche == _selectedStatut;
        return matchCat && matchStatut;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les événements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ─── Filtres ───────────────────────────────────────────────
          Container(
            color: Colors.deepPurple.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategorie,
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      _selectedCategorie = val!;
                      _appliquerFiltres();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatut,
                    decoration: InputDecoration(
                      labelText: 'Statut',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _statuts
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      _selectedStatut = val!;
                      _appliquerFiltres();
                    },
                  ),
                ),
              ],
            ),
          ),

          // ─── Compteur ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} événement(s)',
                style: const TextStyle(
                    color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ),

          // ─── Liste ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Aucun événement trouvé',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _chargerTousLesEvents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final event = _filtered[index];
                            final bool estPasse =
                                event.date.isBefore(DateTime.now()) ||
                                    event.statut == 'Passé';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: estPasse
                                      ? Colors.grey
                                      : Colors.deepPurple,
                                  child: Text(
                                    event.categorie[0],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  event.titre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      '${event.date.day}/${event.date.month}/${event.date.year} '
                                      'à ${event.date.hour}h${event.date.minute.toString().padLeft(2, '0')}',
                                    ),
                                    Text(event.lieu),
                                    Text(
                                      'Par : ${event.organisateurNom}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.deepPurple),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // Badge statut
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: estPasse
                                                ? Colors.grey.shade200
                                                : event.statut == 'Disponible'
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            estPasse ? 'Passé' : event.statut,
                                            style: TextStyle(
                                              color: estPasse
                                                  ? Colors.grey.shade700
                                                  : event.statut == 'Disponible'
                                                      ? Colors.green.shade800
                                                      : Colors.red.shade800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Badge catégorie
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple.shade50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            event.categorie,
                                            style: TextStyle(
                                              color:
                                                  Colors.deepPurple.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      event.prix == 0
                                          ? 'Gratuit'
                                          : '${event.prix.toStringAsFixed(0)} DT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: event.prix == 0
                                            ? Colors.green
                                            : Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${event.placesDisponibles} places',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}