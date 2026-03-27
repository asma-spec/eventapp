import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import '../../widgets/map_picker.dart';

class CreateEventPage extends StatefulWidget {
  final EventModel? event; // null = création, non-null = modification

  const CreateEventPage({super.key, this.event});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lieuController = TextEditingController();
  final _placesController = TextEditingController();
  final _prixController = TextEditingController();
  String _categorie = 'Musique';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;
  double _latitude = 0.0;
  double _longitude = 0.0;

  bool get _estModification => widget.event != null;

  final List<String> _categories = [
    'Musique', 'Sport', 'Art', 'Théâtre', 'Cinéma', 'Conférence', 'Autre'
  ];

  @override
  void initState() {
    super.initState();
    // Si modification : pré-remplir les champs
    if (_estModification) {
      final e = widget.event!;
      _titreController.text = e.titre;
      _descriptionController.text = e.description;
      _lieuController.text = e.lieu;
      _placesController.text = e.placesDisponibles.toString();
      _prixController.text = e.prix.toString();
      _categorie = e.categorie;
      _date = e.date;
      _latitude = e.latitude;
      _longitude = e.longitude;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _lieuController.dispose();
    _placesController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );
      if (time != null) {
        setState(() {
          _date = DateTime(
            picked.year, picked.month, picked.day,
            time.hour, time.minute,
          );
        });
      }
    }
  }

  Future<void> _soumettre(String uid, String nom) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final eventService = EventService();
    bool success;

    if (_estModification) {
      // Modification : on garde le même id et organisateurId
      final eventModifie = EventModel(
        id: widget.event!.id,
        titre: _titreController.text.trim(),
        categorie: _categorie,
        description: _descriptionController.text.trim(),
        date: _date,
        lieu: _lieuController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        placesDisponibles: int.parse(_placesController.text.trim()),
        prix: double.tryParse(_prixController.text.trim()) ?? 0.0,
        organisateurId: widget.event!.organisateurId,
        organisateurNom: widget.event!.organisateurNom,
        statut: widget.event!.statut,
      );
      success = await eventService.modifierEvent(eventModifie, uid);
    } else {
      // Création
      final newEvent = EventModel(
        id: '',
        titre: _titreController.text.trim(),
        categorie: _categorie,
        description: _descriptionController.text.trim(),
        date: _date,
        lieu: _lieuController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        placesDisponibles: int.parse(_placesController.text.trim()),
        prix: double.tryParse(_prixController.text.trim()) ?? 0.0,
        organisateurId: uid,
        organisateurNom: nom,
      );
      success = await eventService.creerEvent(newEvent);
    }

    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_estModification
              ? 'Événement modifié avec succès !'
              : 'Événement créé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_estModification
              ? 'Erreur lors de la modification'
              : 'Erreur lors de la création'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_estModification ? 'Modifier l\'événement' : 'Créer un événement'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v!.isEmpty ? 'Entrez un titre' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categorie,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categorie = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) => v!.isEmpty ? 'Entrez une description' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
                leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                title: Text(
                  '${_date.day}/${_date.month}/${_date.year} à ${_date.hour}h${_date.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: _choisirDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lieuController,
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) => v!.isEmpty ? 'Entrez un lieu' : null,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.map, color: Colors.deepPurple),
                  label: Text(
                    _latitude == 0.0
                        ? 'Choisir sur la carte'
                        : 'Position : ${_latitude.toStringAsFixed(3)}, ${_longitude.toStringAsFixed(3)}',
                    style: const TextStyle(color: Colors.deepPurple),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPicker(
                          initialLat: _latitude == 0.0 ? 36.8065 : _latitude,
                          initialLng: _longitude == 0.0 ? 10.1815 : _longitude,
                          onLocationPicked: (lat, lng) {
                            setState(() {
                              _latitude = lat;
                              _longitude = lng;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre de places',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                validator: (v) => v!.isEmpty ? 'Entrez le nombre de places' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix (0 = gratuit)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading
                      ? null
                      : () => _soumettre(
                            authProvider.user!.uid,
                            authProvider.user!.nom,
                          ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _estModification
                              ? 'Enregistrer les modifications'
                              : 'Créer l\'événement',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}// Create event
