import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/review_model.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../services/reservation_service.dart';

class ReviewsPage extends StatefulWidget {
  final EventModel event;

  const ReviewsPage({super.key, required this.event});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  final ReservationService _reservationService = ReservationService();
  final _commentaireController = TextEditingController();

  List<ReviewModel> _avis = [];
  bool _loading = true;
  bool _dejaNote = false;
  double _maNote = 0;
  bool _submitting = false;
  int _nombreInscrits = 0; // ← nombre réel depuis les réservations

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final authProvider = context.read<AuthProvider>();

    // Charger avis + nombre d'inscrits en parallèle
    final results = await Future.wait([
      _reviewService.getAvisParEvent(widget.event.id),
      _reviewService.dejaNote(widget.event.id, authProvider.user!.uid),
      _reservationService.getNombreInscrits(widget.event.id),
    ]);

    setState(() {
      _avis = results[0] as List<ReviewModel>;
      _dejaNote = results[1] as bool;
      _nombreInscrits = results[2] as int;
      _loading = false;
    });
  }

  double get _noteMoyenne {
    if (_avis.isEmpty) return 0;
    return _avis.map((a) => a.note).reduce((a, b) => a + b) / _avis.length;
  }

  Future<void> _soumettre() async {
    final authProvider = context.read<AuthProvider>();
    if (_maNote == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir une note'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_commentaireController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez écrire un commentaire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    ReviewModel review = ReviewModel(
      id: '',
      eventId: widget.event.id,
      userId: authProvider.user!.uid,
      userNom: authProvider.user!.nom,
      note: _maNote,
      commentaire: _commentaireController.text.trim(),
      date: DateTime.now(),
    );
    bool success = await _reviewService.ajouterAvis(review);
    setState(() => _submitting = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis ajouté avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      _commentaireController.clear();
      setState(() {
        _maNote = 0;
        _dejaNote = true;
      });
      _chargerDonnees();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'ajout'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avis — ${widget.event.titre}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Résumé : note + inscrits ──────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Note moyenne
                        Column(
                          children: [
                            Text(
                              _noteMoyenne.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < _noteMoyenne.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_avis.length} avis',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),

                        // Séparateur
                        Container(
                          height: 80,
                          width: 1,
                          color: Colors.deepPurple.shade200,
                        ),

                        // Nombre d'inscrits (depuis réservations)
                        Column(
                          children: [
                            Text(
                              '$_nombreInscrits',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const Icon(Icons.people,
                                color: Colors.deepPurple, size: 24),
                            const SizedBox(height: 4),
                            const Text(
                              'inscrits',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Formulaire avis ───────────────────────────
                  if (!_dejaNote) ...[
                    const Text(
                      'Donner votre avis',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          return GestureDetector(
                            onTap: () => setState(() => _maNote = i + 1.0),
                            child: Icon(
                              i < _maNote ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 40,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentaireController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Partagez votre expérience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _submitting ? null : _soumettre,
                        child: _submitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Publier mon avis',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],

                  if (_dejaNote)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Vous avez déjà donné votre avis',
                              style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ─── Liste des avis ────────────────────────────
                  const Text(
                    'Tous les avis',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _avis.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.rate_review_outlined,
                                    size: 60, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('Aucun avis pour le moment',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _avis.length,
                          itemBuilder: (context, index) {
                            ReviewModel avis = _avis[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              Colors.deepPurple.shade100,
                                          child: Text(
                                            avis.userNom[0].toUpperCase(),
                                            style: TextStyle(
                                              color:
                                                  Colors.deepPurple.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                avis.userNom,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                '${avis.date.day}/${avis.date.month}/${avis.date.year}',
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (i) {
                                            return Icon(
                                              i < avis.note
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: Colors.amber,
                                              size: 18,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      avis.commentaire,
                                      style: const TextStyle(
                                          fontSize: 15, height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}// Reviews
