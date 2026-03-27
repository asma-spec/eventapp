import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  List<UserModel> _organisateurs = [];
  List<UserModel> _utilisateurs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final org = await _adminService.getOrganisateurs();
    final util = await _adminService.getUtilisateursClassiques();
    setState(() {
      _organisateurs = org;
      _utilisateurs = util;
      _loading = false;
    });
  }

  Future<void> _supprimer(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Text(
            'Supprimer le compte de "${user.nom}" ? Toutes ses données seront supprimées.'),
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
      await _adminService.supprimerUtilisateur(user.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte de ${user.nom} supprimé'),
          backgroundColor: Colors.red,
        ),
      );
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Organisateurs (${_organisateurs.length})'),
            Tab(text: 'Utilisateurs (${_utilisateurs.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _listeUtilisateurs(_organisateurs, isOrganisateur: true),
                _listeUtilisateurs(_utilisateurs, isOrganisateur: false),
              ],
            ),
    );
  }

  Widget _listeUtilisateurs(List<UserModel> users,
      {required bool isOrganisateur}) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOrganisateur ? Icons.business : Icons.person_off,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              isOrganisateur
                  ? 'Aucun organisateur'
                  : 'Aucun utilisateur',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isOrganisateur
                    ? Colors.deepPurple.shade100
                    : Colors.teal.shade100,
                child: Text(
                  user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isOrganisateur
                        ? Colors.deepPurple
                        : Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(user.nom,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  if (user.billetGratuit)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🎟 Billet gratuit',
                        style: TextStyle(
                            fontSize: 11, color: Colors.orange),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                user.email,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Supprimer le compte',
                onPressed: () => _supprimer(user),
              ),
            ),
          );
        },
      ),
    );
  }
}