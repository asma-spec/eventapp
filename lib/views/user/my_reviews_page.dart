import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../services/event_service.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  final EventService _eventService = EventService();

  List<ReviewModel> _mesAvis = [];
  // ✅ Map eventId → titre de l'événement
  Map<String, String> _titresEvents = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final uid = context.read<AuthProvider>().user!.uid;

    // Charger les avis + tous les events en parallèle
    final results = await Future.wait([
      _reviewService.getMesAvis(uid),
      _eventService.getEvents(),
    ]);

    final avis = results[0] as List<ReviewModel>;
    final events = results[1] as List;

    // Construire le map eventId → titre
    final Map<String, String> titres = {};
    for (final event in events) {
      titres[event.id] = event.titre;
    }

    avis.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _mesAvis = avis;
      _titresEvents = titres;
      _loading = false;
    });
  }

  double get _noteMoyenne {
    if (_mesAvis.isEmpty) return 0;
    return _mesAvis.map((a) => a.note).reduce((a, b) => a + b) /
        _mesAvis.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes avis'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mesAvis.isEmpty
              ? _vide()
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Résumé ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple.shade600,
                                Colors.deepPurple.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      _noteMoyenne.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < _noteMoyenne.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Note moyenne',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 70,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '${_mesAvis.length}',
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Icon(Icons.rate_review,
                                        color: Colors.white70, size: 18),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Avis publiés',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Mes ${_mesAvis.length} avis',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Liste ─────────────────────────────────
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _mesAvis.length,
                          itemBuilder: (context, index) {
                            return _carteAvis(_mesAvis[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _carteAvis(ReviewModel avis) {
    // ✅ Récupère le vrai titre, affiche "Événement introuvable" en fallback
    final String titre =
        _titresEvents[avis.eventId] ?? 'Événement introuvable';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête : titre event + date ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event,
                      color: Colors.deepPurple, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Vrai titre affiché ici
                      Text(
                        titre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.deepPurple,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${avis.date.day}/${avis.date.month}/${avis.date.year}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Étoiles ───────────────────────────────────────
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < avis.note ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${avis.note.toInt()}/5',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Commentaire ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                avis.commentaire,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rate_review_outlined,
                  size: 50, color: Colors.deepPurple),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun avis publié',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Participez à des événements et\npartagez votre expérience !',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}