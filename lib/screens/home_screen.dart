import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../providers/auth_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'parametrage/filieres_screen.dart';
import 'parametrage/periodes_screen.dart';
import 'parametrage/matieres_screen.dart';
import 'parametrage/enseignants_screen.dart';
import 'saisie/inscription_screen.dart';
import 'saisie/presence_screen.dart';
import 'saisie/justification_screen.dart';
import 'editions/edition_filiere_screen.dart';
import 'editions/edition_absence_screen.dart';
import 'editions/edition_etudiant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selected = 0;

  final List<_NavItem> _items = [
    _NavItem('Tableau de bord', Icons.dashboard_outlined, const DashboardScreen()),
    _NavItem('Périodes',        Icons.schedule_outlined,  const PeriodesScreen()),
    _NavItem('Matières',        Icons.book_outlined,      const MatieresScreen()),
    _NavItem('Enseignants',     Icons.school_outlined,    const EnseignantsScreen()),
    _NavItem('Filières',        Icons.folder_outlined,    const FilieresScreen()),
    _NavItem('Inscriptions',    Icons.person_add_outlined, const InscriptionScreen()),
    _NavItem('Présences',       Icons.check_circle_outline, const PresenceScreen()),
    _NavItem('Justifications',  Icons.description_outlined, const JustificationScreen()),
    _NavItem('Par filière',     Icons.table_chart_outlined, const EditionFiliereScreen()),
    _NavItem('Absences/période',Icons.analytics_outlined,  const EditionAbsenceScreen()),
    _NavItem('Par étudiant',    Icons.person_search_outlined, const EditionEtudiantScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_items[_selected].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () async {
              await auth.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppConstants.surface,
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            color: AppConstants.primary,
            width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('GestiAbsences',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(auth.user?['username'] ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
              _section('Tableau de bord'),
              _tile(0),
              _section('Module 1 — Paramétrage'),
              _tile(1), _tile(2), _tile(3), _tile(4),
              _section('Module 2 — Saisie'),
              _tile(5), _tile(6), _tile(7),
              _section('Module 3 — Éditions'),
              _tile(8), _tile(9), _tile(10),
            ]),
          ),
        ]),
      ),
      body: _items[_selected].screen,
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(label, style: const TextStyle(
        fontSize: 9, fontWeight: FontWeight.w700,
        letterSpacing: .06, color: Color(0xFFAAA9A3))),
  );

  Widget _tile(int index) {
    final item = _items[index];
    final selected = _selected == index;
    return ListTile(
      dense: true,
      leading: Icon(item.icon, size: 18,
          color: selected ? AppConstants.primary : AppConstants.secondary),
      title: Text(item.label, style: TextStyle(
          fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? AppConstants.primary : AppConstants.secondary)),
      selected: selected,
      selectedTileColor: AppConstants.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      onTap: () {
        setState(() => _selected = index);
        Navigator.pop(context);
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const _NavItem(this.label, this.icon, this.screen);
}
