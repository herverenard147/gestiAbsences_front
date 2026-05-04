import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class PresenceScreen extends StatefulWidget {
  const PresenceScreen({super.key});
  @override State<PresenceScreen> createState() => _PresenceScreenState();
}

class _PresenceScreenState extends State<PresenceScreen> {
  List<Filiere> _filieres = [];
  List<Matiere> _matieres = [];
  List<Enseignant> _enseignants = [];
  List<Periode> _periodes = [];
  List<Enseignement> _seances = [];
  List<Etudiant> _etudiants = [];

  Filiere? _filiere;
  Matiere? _matiere;
  Enseignant? _enseignant;
  Periode? _periode;
  Enseignement? _seance;

  // Map etudiant_id -> statut
  Map<int, String> _presences = {};
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() { super.initState(); _loadInit(); }

  Future<void> _loadInit() async {
    setState(() => _loading = true);
    try {
      final r = await Future.wait([
        ApiService.getFilieres(), ApiService.getEnseignants(), ApiService.getPeriodes(),
      ]);
      setState(() {
        _filieres = r[0] as List<Filiere>;
        _enseignants = r[1] as List<Enseignant>;
        _periodes = r[2] as List<Periode>;
        _loading = false;
      });
    } catch (e) { setState(() => _loading = false); }
  }

  Future<void> _onFiliereChanged(Filiere? f) async {
    setState(() { _filiere = f; _matiere = null; _matieres = []; _seance = null; _seances = []; _presences = {}; });
    if (f == null) return;
    final m = await ApiService.getMatieres(filiereId: f.id);
    final e = await ApiService.getEtudiants(filiereId: f.id);
    setState(() { _matieres = m; _etudiants = e; });
  }

  Future<void> _onMatiereChanged(Matiere? m) async {
    setState(() { _matiere = m; _seance = null; _seances = []; _presences = {}; });
    if (m == null || _periode == null) return;
    _loadSeances();
  }

  Future<void> _onPeriodeChanged(Periode? p) async {
    setState(() { _periode = p; _seance = null; _seances = []; _presences = {}; });
    if (_matiere == null || p == null) return;
    _loadSeances();
  }

  Future<void> _loadSeances() async {
    if (_matiere == null || _periode == null) return;
    final s = await ApiService.getEnseignements(matiereId: _matiere!.id, periodeId: _periode!.id);
    setState(() => _seances = s);
  }

  Future<void> _createSeance() async {
    if (_matiere == null || _enseignant == null || _periode == null) {
      showSnack(context, 'Sélectionnez matière, enseignant et période', error: true);
      return;
    }
    // Demander la date de la séance
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    final id = 'SEA-${DateTime.now().millisecondsSinceEpoch}';
    final date = picked.toIso8601String().substring(0, 10);
    try {
      await ApiService.createEnseignement(Enseignement(
        idEnseignement: id, dateEnseignement: date,
        enseignantId: _enseignant!.id!, matiereId: _matiere!.id!, periodeId: _periode!.id!,
      ));
      showSnack(context, 'Séance créée');
      _loadSeances();
    } catch (e) { showSnack(context, 'Erreur: $e', error: true); }
  }

  Future<void> _onSeanceChanged(Enseignement? s) async {
    setState(() { _seance = s; _presences = {}; });
    if (s == null) return;
    // Charger les présences existantes via /presences/seance/:id
    final existing = await ApiService.getPresencesBySeance(s.id!);
    final map = <int, String>{};
    for (final p in existing) { map[p.etudiantId] = p.statut; }
    // Pré-remplir les non-renseignés
    for (final e in _etudiants) { map.putIfAbsent(e.id!, () => 'absent'); }
    setState(() => _presences = map);
  }

  void _toggleStatut(int etudiantId) {
    final current = _presences[etudiantId] ?? 'absent';
    final next = current == 'present' ? 'absent' : current == 'absent' ? 'justifie' : 'present';
    setState(() => _presences[etudiantId] = next);
  }

  Future<void> _save() async {
    if (_seance == null) { showSnack(context, 'Sélectionnez une séance', error: true); return; }
    setState(() => _saving = true);
    try {
      final list = _presences.entries.map((e) => {'etudiant_id': e.key, 'statut': e.value}).toList();
      await ApiService.saveBulkPresences(_seance!.id!, list);
      showSnack(context, '${list.length} présences enregistrées ✓');
    } catch (e) { showSnack(context, 'Erreur: $e', error: true); }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading,
    child: Scaffold(
      backgroundColor: AppConstants.background,
      body: Column(children: [
        // ── Filtres ──────────────────────────────────────────
        Container(
          color: AppConstants.surface,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              Expanded(child: DropdownButtonFormField<Filiere>(
                value: _filiere, isDense: true,
                decoration: const InputDecoration(labelText: 'Filière'),
                items: _filieres.map((f) => DropdownMenuItem(value: f, child: Text(f.libelleFiliere, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: _onFiliereChanged,
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<Periode>(
                value: _periode, isDense: true,
                decoration: const InputDecoration(labelText: 'Période'),
                items: _periodes.map((p) => DropdownMenuItem(value: p, child: Text(p.idPeriode))).toList(),
                onChanged: _onPeriodeChanged,
              )),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: DropdownButtonFormField<Matiere>(
                value: _matiere, isDense: true,
                decoration: const InputDecoration(labelText: 'Matière'),
                items: _matieres.map((m) => DropdownMenuItem(value: m, child: Text(m.nomMatiere, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: _onMatiereChanged,
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<Enseignant>(
                value: _enseignant, isDense: true,
                decoration: const InputDecoration(labelText: 'Enseignant'),
                items: _enseignants.map((e) => DropdownMenuItem(value: e, child: Text(e.nomComplet, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _enseignant = v),
              )),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: DropdownButtonFormField<Enseignement>(
                value: _seance, isDense: true,
                decoration: const InputDecoration(labelText: 'Séance'),
                items: _seances.map((s) => DropdownMenuItem(
                  value: s, child: Text('${s.dateEnseignement} ${s.horaire ?? ''}'),
                )).toList(),
                onChanged: _onSeanceChanged,
              )),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _createSeance,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nouvelle', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ]),
        ),

        // ── Légende ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppConstants.background,
          child: Row(children: [
            _legend('P', 'Présent', AppConstants.successBg, AppConstants.success),
            const SizedBox(width: 16),
            _legend('A', 'Absent', AppConstants.dangerBg, AppConstants.danger),
            const SizedBox(width: 16),
            _legend('J', 'Justifié', AppConstants.warningBg, AppConstants.warning),
            const Spacer(),
            Text('${_etudiants.length} étudiants',
                style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
          ]),
        ),

        // ── Liste présences ──────────────────────────────────
        Expanded(
          child: _seance == null
              ? const Center(child: EmptyState(
                  message: 'Sélectionnez une séance\npour saisir les présences',
                  icon: Icons.touch_app_outlined))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _etudiants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final e = _etudiants[i];
                    final statut = _presences[e.id] ?? 'absent';
                    return AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        InitialesAvatar(initiales: e.initiales, size: 36),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.nomComplet,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(e.numeroEtudiant,
                              style: const TextStyle(fontSize: 10, color: AppConstants.secondary)),
                        ])),
                        PresenceButton(statut: statut, onTap: () => _toggleStatut(e.id!)),
                      ]),
                    );
                  },
                ),
        ),

        // ── Bouton valider ───────────────────────────────────
        if (_seance != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppConstants.surface,
            child: Row(children: [
              Expanded(child: _summaryChip('P',
                  _presences.values.where((v) => v == 'present').length,
                  AppConstants.success, AppConstants.successBg)),
              const SizedBox(width: 8),
              Expanded(child: _summaryChip('A',
                  _presences.values.where((v) => v == 'absent').length,
                  AppConstants.danger, AppConstants.dangerBg)),
              const SizedBox(width: 8),
              Expanded(child: _summaryChip('J',
                  _presences.values.where((v) => v == 'justifie').length,
                  AppConstants.warning, AppConstants.warningBg)),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, size: 16),
                label: const Text('Valider'),
              ),
            ]),
          ),
      ]),
    ),
  );

  Widget _legend(String lbl, String text, Color bg, Color fg) => Row(children: [
    Container(width: 20, height: 20,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle,
            border: Border.all(color: fg)),
        child: Center(child: Text(lbl, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg)))),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(fontSize: 10, color: AppConstants.secondary)),
  ]);

  Widget _summaryChip(String lbl, int count, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(lbl, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      const SizedBox(width: 4),
      Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
    ]),
  );
}
