import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import 'create_event_page.dart';
import 'stats_page.dart';
import 'all_events_page.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  final EventService _eventService = EventService();
  List<EventModel> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerEvents();
  }

  Future<void> _chargerEvents() async {
    final authProvider = context.read<AuthProvider>();
    final events = await _eventService
        .getEventsByOrganisateur(authProvider.user!.uid);
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  Future<void> _supprimerEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous supprimer cet événement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final uid = context.read<AuthProvider>().user!.uid;
      await _eventService.supprimerEvent(event.id, uid);
      _chargerEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes événements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: 'Tous les événements',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllEventsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiques',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StatsPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventPage()),
          );
          _chargerEvents();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucun événement créé',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Appuyez sur "Créer" pour commencer',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerEvents,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
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
                            backgroundColor:
                                estPasse ? Colors.grey : Colors.deepPurple,
                            child: Text(
                              event.categorie[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            event.titre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: estPasse
                                      ? Colors.grey.shade200
                                      : event.statut == 'Disponible'
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
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
                            ],
                          ),
                          // ─── LOGIQUE BOUTONS ───────────────────────────
                          trailing: estPasse
                              // PASSÉ → supprimer uniquement
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: 'Supprimer',
                                  onPressed: () => _supprimerEvent(event),
                                )
                              // DISPONIBLE/À VENIR → modifier + supprimer
                              : SizedBox(
                                  width: 96,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.deepPurple),
                                        tooltip: 'Modifier',
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreateEventPage(
                                                  event: event),
                                            ),
                                          );
                                          _chargerEvents();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Supprimer',
                                        onPressed: () =>
                                            _supprimerEvent(event),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}