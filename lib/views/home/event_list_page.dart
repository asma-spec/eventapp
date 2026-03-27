import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final EventService _eventService = EventService();
  List<EventModel> _events = [];
  List<EventModel> _eventsFiltres = [];
  bool _loading = true;
  bool _vueCalendrier = false;
  String _categorieChoisie = 'Toutes';
  String _lieuRecherche = '';
  DateTime? _dateFiltree;
  String _triChoisi = 'Date';
  DateTime _focusedDay = DateTime.now();

  final List<String> _categories = [
    'Toutes', 'Musique', 'Sport', 'Art', 'Théâtre', 'Cinéma', 'Conférence', 'Autre'
  ];

  final List<String> _tris = [
    'Date', 'Prix croissant', 'Prix décroissant'
  ];

  @override
  void initState() {
    super.initState();
    _chargerEvents();
  }

  Future<void> _chargerEvents() async {
    List<EventModel> events = await _eventService.getEvents();
    setState(() {
      _events = events;
      _appliquerFiltres();
      _loading = false;
    });
  }

  void _appliquerFiltres() {
    List<EventModel> filtres = List.from(_events);

    if (_categorieChoisie != 'Toutes') {
      filtres = filtres
          .where((e) => e.categorie == _categorieChoisie)
          .toList();
    }

    if (_lieuRecherche.isNotEmpty) {
      filtres = filtres
          .where((e) => e.lieu.toLowerCase()
              .contains(_lieuRecherche.toLowerCase()))
          .toList();
    }

    if (_dateFiltree != null) {
      filtres = filtres.where((e) =>
        e.date.year == _dateFiltree!.year &&
        e.date.month == _dateFiltree!.month &&
        e.date.day == _dateFiltree!.day
      ).toList();
    }

    if (_triChoisi == 'Date') {
      filtres.sort((a, b) => a.date.compareTo(b.date));
    } else if (_triChoisi == 'Prix croissant') {
      filtres.sort((a, b) => a.prix.compareTo(b.prix));
    } else if (_triChoisi == 'Prix décroissant') {
      filtres.sort((a, b) => b.prix.compareTo(a.prix));
    }

    setState(() => _eventsFiltres = filtres);
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return _events.where((e) =>
      e.date.year == day.year &&
      e.date.month == day.month &&
      e.date.day == day.day
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_vueCalendrier ? Icons.list : Icons.calendar_month),
            onPressed: () => setState(() => _vueCalendrier = !_vueCalendrier),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.deepPurple.shade50,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher par lieu...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (v) {
                    _lieuRecherche = v;
                    _appliquerFiltres();
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      String cat = _categories[index];
                      bool selected = cat == _categorieChoisie;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _categorieChoisie = cat);
                          _appliquerFiltres();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.deepPurple
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.deepPurple),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.deepPurple,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.sort, color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _triChoisi,
                        underline: const SizedBox(),
                        items: _tris.map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: const TextStyle(fontSize: 12)),
                        )).toList(),
                        onChanged: (v) {
                          setState(() => _triChoisi = v!);
                          _appliquerFiltres();
                        },
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.date_range, size: 16),
                      label: Text(
                        _dateFiltree == null
                            ? 'Date'
                            : '${_dateFiltree!.day}/${_dateFiltree!.month}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _dateFiltree = picked);
                          _appliquerFiltres();
                        }
                      },
                    ),
                    if (_dateFiltree != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() => _dateFiltree = null);
                          _appliquerFiltres();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _vueCalendrier
                    ? _buildCalendrier()
                    : _buildListe(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendrier() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          eventLoader: _getEventsForDay,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
              _dateFiltree = selectedDay;
            });
            _appliquerFiltres();
          },
          selectedDayPredicate: (day) =>
              _dateFiltree != null && isSameDay(_dateFiltree!, day),
          calendarStyle: CalendarStyle(
            markerDecoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.deepPurple.shade200,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const Divider(),
        Expanded(child: _buildListe()),
      ],
    );
  }

  Widget _buildListe() {
    if (_eventsFiltres.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun événement trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _chargerEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _eventsFiltres.length,
        itemBuilder: (context, index) {
          EventModel event = _eventsFiltres[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/event-detail',
                  arguments: event,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.categorie,
                            style: TextStyle(
                              color: Colors.deepPurple.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: event.statut == 'Disponible'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event.statut,
                            style: TextStyle(
                              color: event.statut == 'Disponible'
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.titre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${event.date.day}/${event.date.month}/${event.date.year}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.lieu,
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
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
                          '${event.placesDisponibles} places',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          event.prix == 0
                              ? 'Gratuit'
                              : '${event.prix} DT',
                          style: TextStyle(
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}