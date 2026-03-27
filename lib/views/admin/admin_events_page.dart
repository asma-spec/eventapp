import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/admin_service.dart';
import '../organizer/create_event_page.dart';

class AdminEventsPage extends StatefulWidget {
  const AdminEventsPage({super.key});

  @override
  State<AdminEventsPage> createState() => _AdminEventsPageState();
}

class _AdminEventsPageState extends State<AdminEventsPage> {
  final AdminService _adminService = AdminService();
  List<EventModel> _events = [];
  List<EventModel> _filtered = [];
  bool _loading = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final events = await _adminService.getTousLesEvents();
    events.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _events = events;
      _filtered = events;
      _loading = false;
    });
  }

  void _filtrer(String query) {
    setState(() {
      _recherche = query;
      _filtered = _events
          .where((e) =>
              e.titre.toLowerCase().contains(query.toLowerCase()) ||
              e.organisateurNom.toLowerCase().contains(query.toLowerCase()) ||
              e.categorie.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _supprimer(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: Text('Supprimer "${event.titre}" définitivement ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _adminService.supprimerEvent(event.id);
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les événements'),
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
                hintText: 'Rechercher...',
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
                  child: Text('Aucun événement trouvé',
                      style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final event = _filtered[index];
                      final bool estPasse = event.date
                              .isBefore(DateTime.now()) ||
                          event.statut == 'Passé';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor:
                                estPasse ? Colors.grey : Colors.deepPurple,
                            child: Text(
                              event.categorie[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(event.titre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${event.date.day}/${event.date.month}/${event.date.year} · ${event.lieu}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Organisateur : ${event.organisateurNom}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  estPasse ? 'Passé' : event.statut,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: estPasse
                                        ? Colors.grey.shade700
                                        : event.statut == 'Disponible'
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 96,
                            child: Row(
                              children: [
                                if (!estPasse)
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.deepPurple),
                                    tooltip: 'Modifier',
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CreateEventPage(event: event),
                                        ),
                                      );
                                      _charger();
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  tooltip: 'Supprimer',
                                  onPressed: () => _supprimer(event),
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