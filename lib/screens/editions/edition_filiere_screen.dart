import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

// ══════════════════════════════════════════════════════════════
// ÉDITION — MATIÈRES PAR FILIÈRE
// ══════════════════════════════════════════════════════════════
class EditionFiliereScreen extends StatefulWidget {
  const EditionFiliereScreen({super.key});
  @override State<EditionFiliereScreen> createState() => _EditionFiliereScreenState();
}

class _EditionFiliereScreenState extends State<EditionFiliereScreen> {
  List<Filiere> _filieres = [];
  List<Periode> _periodes = [];
  List<Map<String, dynamic>> _editionData = [];
  Filiere? _filiere;
  Periode? _periode;
  bool _loading = false;
  bool _initLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInit();
  }

  Future<void> _loadInit() async {
    try {
      final r = await Future.wait([ApiService.getFilieres(), ApiService.getPeriodes()]);
      if (!mounted) return;
      setState(() {
        _filieres = r[0] as List<Filiere>;
        _periodes = r[1] as List<Periode>;
        _initLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _initLoading = false);
    }
  }

  Future<void> _filtrer() async {
    if (_filiere == null) {
      showSnack(context, 'Sélectionnez une filière', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      // Essayer l'endpoint enrichi edition-matieres
      try {
        final r = await ApiService.getEditionMatieres(_filiere!.id!, periodeId: _periode?.id);
        final data = r['data'];
        if (data is List && data.isNotEmpty) {
          setState(() { _editionData = List<Map<String, dynamic>>.from(data); _loading = false; });
          return;
        }
      } catch (_) {}

      // Fallback : construire depuis matières + enseignements
      final matieres = await ApiService.getMatieres(filiereId: _filiere!.id);
      final enseignements = await ApiService.getEnseignements(
        filiereId: _filiere!.id,
        periodeId: _periode?.id,
      );

      // Grouper les séances par matière
      final seancesParMatiere = <int, int>{};
      for (final e in enseignements) {
        seancesParMatiere[e.matiereId] = (seancesParMatiere[e.matiereId] ?? 0) + 1;
      }

      // Trouver l'enseignant de chaque matière (le dernier enseignement)
      final enseignantParMatiere = <int, String>{};
      for (final e in enseignements) {
        final nom = '${e.ensNom ?? ''} ${e.ensPrenom ?? ''}'.trim();
        if (nom.isNotEmpty) enseignantParMatiere[e.matiereId] = nom;
      }

      setState(() {
        _editionData = matieres.map((m) => {
          'code_matiere': m.codeMatiere,
          'nom_matiere': m.nomMatiere,
          'volume_horaire': m.volumeHoraire,
          'seances_prevues': m.volumeHoraire,
          'seances_effectuees': seancesParMatiere[m.id] ?? 0,
          'enseignant': enseignantParMatiere[m.id] ?? '',
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showSnack(context, 'Erreur: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading || _initLoading,
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
                items: _filieres.map((f) => DropdownMenuItem(
                  value: f, child: Text(f.libelleFiliere, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() { _filiere = v; _editionData = []; }),
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<Periode?>(
                value: _periode, isDense: true,
                decoration: const InputDecoration(labelText: 'Période'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes')),
                  ..._periodes.map((p) => DropdownMenuItem(value: p, child: Text(p.idPeriode))),
                ],
                onChanged: (v) => setState(() => _periode = v),
              )),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _filtrer, child: const Text('Filtrer')),
            ),
          ]),
        ),

        // ── Résumé filière ────────────────────────────────────
        if (_editionData.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: MetricCard(
                label: 'Matières', value: '${_editionData.length}')),
              const SizedBox(width: 8),
              Expanded(child: MetricCard(
                label: 'Vol. horaire total',
                value: '${_editionData.fold<int>(0, (s, d) => s + ((d['volume_horaire'] ?? 0) as int))}h')),
              const SizedBox(width: 8),
              Expanded(child: MetricCard(
                label: 'Séances effectuées',
                value: '${_editionData.fold<int>(0, (s, d) => s + ((d['seances_effectuees'] ?? 0) as int))}',
                valueColor: AppConstants.success)),
            ]),
          ),
        ],

        // ── Liste matières ────────────────────────────────────
        Expanded(
          child: _editionData.isEmpty
              ? const EmptyState(
                  message: 'Sélectionnez une filière et cliquez sur Filtrer',
                  icon: Icons.table_chart_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _editionData.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = _editionData[i];
                    final code = (d['code_matiere'] ?? '???').toString();
                    final prefix = code.length >= 3 ? code.substring(0, 3) : code;
                    final seancesEff = d['seances_effectuees'] ?? 0;
                    final seancesPrev = d['seances_prevues'] ?? d['volume_horaire'] ?? 0;
                    final enseignant = (d['enseignant'] ?? '').toString().trim();
                    final pct = seancesPrev > 0
                        ? (seancesEff / seancesPrev).clamp(0.0, 1.0)
                        : 0.0;
                    return AppCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppConstants.successBg,
                            borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text(prefix.toUpperCase(),
                              style: const TextStyle(fontSize: 10,
                                  fontWeight: FontWeight.w700, color: AppConstants.success))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['nom_matiere'] ?? '',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('$code · ${d['volume_horaire'] ?? 0}h',
                              style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                          if (enseignant.isNotEmpty)
                            Text('Ens. : $enseignant',
                                style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('$seancesEff / $seancesPrev',
                              style: const TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w700, color: AppConstants.primary)),
                          const Text('séances', style: TextStyle(
                              fontSize: 9, color: AppConstants.secondary)),
                        ]),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 4,
                          backgroundColor: AppConstants.background,
                          color: pct >= 0.8 ? AppConstants.success
                              : pct >= 0.5 ? AppConstants.warning
                              : AppConstants.danger,
                        ),
                      ),
                    ]));
                  },
                ),
        ),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// ÉDITION — ABSENCES PAR FILIÈRE & PÉRIODE
// ══════════════════════════════════════════════════════════════
class EditionAbsenceScreen extends StatefulWidget {
  const EditionAbsenceScreen({super.key});
  @override State<EditionAbsenceScreen> createState() => _EditionAbsenceScreenState();
}

class _EditionAbsenceScreenState extends State<EditionAbsenceScreen> {
  List<Filiere> _filieres = [];
  List<Periode> _periodes = [];
  Filiere? _filiere;
  Periode? _periode;
  List<Map<String, dynamic>> _rapport = [];
  bool _loading = false;
  bool _initLoading = true;
  bool _generated = false;

  @override
  void initState() {
    super.initState();
    _loadInit();
  }

  Future<void> _loadInit() async {
    try {
      final r = await Future.wait([ApiService.getFilieres(), ApiService.getPeriodes()]);
      if (!mounted) return;
      setState(() {
        _filieres = r[0] as List<Filiere>;
        _periodes = r[1] as List<Periode>;
        _initLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _initLoading = false);
    }
  }

  Future<void> _generer() async {
    if (_filiere == null) {
      showSnack(context, 'Sélectionnez une filière', error: true);
      return;
    }
    setState(() { _loading = true; _generated = false; });
    try {
      final r = await ApiService.getRapportFiliere(_filiere!.id!, periodeId: _periode?.id);
      final raw = r['data'];
      List<Map<String, dynamic>> liste = [];
      if (raw is List) {
        liste = List<Map<String, dynamic>>.from(raw);
      } else if (raw is Map) {
        // Certains backends retournent { absences: [...], stats: {...} }
        final absences = raw['absences'];
        if (absences is List) liste = List<Map<String, dynamic>>.from(absences);
      }
      setState(() { _rapport = liste; _loading = false; _generated = true; });
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; });
        showSnack(context, 'Erreur: $e', error: true);
      }
    }
  }

  // Agrégation des métriques — robuste même si les clés varient
  int _sum(String key) => _rapport.fold(0, (s, r) {
    final v = r[key];
    return s + (v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0);
  });

  int get _total    => _sum('total_absences');
  int get _justif   => _sum('justifiees');
  int get _nonJustif => _sum('non_justifiees');

  Color _tauxColor(double taux) =>
      taux > 10 ? AppConstants.danger : taux > 5 ? AppConstants.warning : AppConstants.success;

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading || _initLoading,
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
                items: _filieres.map((f) => DropdownMenuItem(
                  value: f, child: Text(f.libelleFiliere, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() { _filiere = v; _rapport = []; _generated = false; }),
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<Periode?>(
                value: _periode, isDense: true,
                decoration: const InputDecoration(labelText: 'Période'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes')),
                  ..._periodes.map((p) => DropdownMenuItem(value: p, child: Text(p.idPeriode))),
                ],
                onChanged: (v) => setState(() => _periode = v),
              )),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _generer, child: const Text('Générer le rapport')),
            ),
          ]),
        ),

        // ── Métriques globales ────────────────────────────────
        if (_generated && _rapport.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: MetricCard(label: 'Total absences', value: '$_total')),
              const SizedBox(width: 8),
              Expanded(child: MetricCard(
                label: 'Justifiées', value: '$_justif', valueColor: AppConstants.success)),
              const SizedBox(width: 8),
              Expanded(child: MetricCard(
                label: 'Non justif.', value: '$_nonJustif', valueColor: AppConstants.danger)),
            ]),
          ),
        ],

        // ── Tableau absences ──────────────────────────────────
        Expanded(
          child: !_generated
              ? const EmptyState(
                  message: 'Sélectionnez une filière et une période,\npuis cliquez sur Générer le rapport',
                  icon: Icons.analytics_outlined)
              : _rapport.isEmpty
                  ? const EmptyState(
                      message: 'Aucune absence enregistrée\npour cette filière et période',
                      icon: Icons.check_circle_outline)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rapport.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = _rapport[i];
                        final total  = r['total_absences'] is int ? r['total_absences'] as int
                            : int.tryParse(r['total_absences']?.toString() ?? '0') ?? 0;
                        final j      = r['justifiees'] is int ? r['justifiees'] as int
                            : int.tryParse(r['justifiees']?.toString() ?? '0') ?? 0;
                        final nj     = r['non_justifiees'] is int ? r['non_justifiees'] as int
                            : int.tryParse(r['non_justifiees']?.toString() ?? '0') ?? 0;
                        final nbEtu  = r['nb_etudiants'] is int ? r['nb_etudiants'] as int
                            : int.tryParse(r['nb_etudiants']?.toString() ?? '1') ?? 1;
                        final taux   = nbEtu > 0 ? (total / nbEtu * 100).clamp(0, 100).toDouble() : 0.0;

                        return AppCard(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r['nom_etudiant'] ?? r['nom'] ?? r['libelle_filiere'] ?? '',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              if ((r['numero_etudiant'] ?? r['code_matiere'] ?? '').toString().isNotEmpty)
                                Text((r['numero_etudiant'] ?? r['code_matiere'] ?? '').toString(),
                                    style: const TextStyle(fontSize: 10, color: AppConstants.secondary)),
                              if ((r['nom_matiere'] ?? '').toString().isNotEmpty)
                                Text(r['nom_matiere'].toString(),
                                    style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                              if ((r['motif'] ?? '').toString().isNotEmpty)
                                Text('Motif : ${r['motif']}',
                                    style: const TextStyle(fontSize: 10, color: AppConstants.secondary)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _tauxColor(taux).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _tauxColor(taux).withOpacity(0.3)),
                                ),
                                child: Text('${taux.toStringAsFixed(1)}%',
                                    style: TextStyle(fontSize: 11,
                                        fontWeight: FontWeight.w700, color: _tauxColor(taux))),
                              ),
                            ]),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            _chip('Total: $total', AppConstants.info, AppConstants.infoBg),
                            const SizedBox(width: 6),
                            _chip('✓ Justif.: $j', AppConstants.success, AppConstants.successBg),
                            const SizedBox(width: 6),
                            _chip('✗ Non just.: $nj', AppConstants.danger, AppConstants.dangerBg),
                          ]),
                        ]));
                      },
                    ),
        ),
      ]),
    ),
  );

  Widget _chip(String lbl, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(lbl, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
  );
}

// ══════════════════════════════════════════════════════════════
// ÉDITION — RAPPORT PAR ÉTUDIANT
// ══════════════════════════════════════════════════════════════
class EditionEtudiantScreen extends StatefulWidget {
  const EditionEtudiantScreen({super.key});
  @override State<EditionEtudiantScreen> createState() => _EditionEtudiantScreenState();
}

class _EditionEtudiantScreenState extends State<EditionEtudiantScreen> {
  List<Etudiant> _etudiants = [];
  List<Periode> _periodes = [];
  Etudiant? _etudiant;
  Periode? _periode;
  List<Map<String, dynamic>> _absences = [];
  Map<String, dynamic>? _stats;
  bool _loading = false;
  bool _initLoading = true;
  bool _generated = false;
  final _searchCtrl = TextEditingController();
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadInit();
  }

  Future<void> _loadInit() async {
    try {
      final r = await Future.wait([ApiService.getEtudiants(), ApiService.getPeriodes()]);
      if (!mounted) return;
      setState(() {
        _etudiants = r[0] as List<Etudiant>;
        _periodes  = r[1] as List<Periode>;
        _initLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _initLoading = false);
    }
  }

  List<Etudiant> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return [];
    return _etudiants.where((e) =>
        e.nomComplet.toLowerCase().contains(q) ||
        e.numeroEtudiant.toLowerCase().contains(q)).take(6).toList();
  }

  Future<void> _generer() async {
    if (_etudiant == null) {
      showSnack(context, 'Sélectionnez un étudiant', error: true);
      return;
    }
    setState(() { _loading = true; _generated = false; });
    try {
      final r = await ApiService.getRapportEtudiant(_etudiant!.id!, periodeId: _periode?.id);
      final data = r['data'] ?? r;

      List<Map<String, dynamic>> absences = [];
      Map<String, dynamic>? stats;

      if (data is Map) {
        final rawAbs = data['absences'];
        if (rawAbs is List) {
          absences = List<Map<String, dynamic>>.from(rawAbs);
        }
        final rawStats = data['stats'];
        if (rawStats is Map) {
          stats = Map<String, dynamic>.from(rawStats);
        } else {
          // Calculer stats depuis la liste si absentes
          final total = absences.length;
          final justif = absences.where((a) => a['statut'] == 'justifie').length;
          stats = {'total': total, 'justifiees': justif, 'non_justifiees': total - justif};
        }
      }

      setState(() {
        _absences = absences;
        _stats = stats;
        _loading = false;
        _generated = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showSnack(context, 'Erreur: $e', error: true);
      }
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading || _initLoading,
    child: Scaffold(
      backgroundColor: AppConstants.background,
      body: Column(children: [
        // ── Filtres ──────────────────────────────────────────
        Container(
          color: AppConstants.surface,
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Recherche étudiant avec autocomplete
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _showDropdown = v.isNotEmpty;
                if (_etudiant != null && v != _etudiant!.nomComplet) {
                  _etudiant = null;
                  _absences = [];
                  _stats = null;
                  _generated = false;
                }
              }),
              decoration: InputDecoration(
                labelText: 'Rechercher un étudiant (nom ou numéro)',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _etudiant != null
                    ? const Icon(Icons.check_circle, size: 18, color: AppConstants.success)
                    : null,
              ),
            ),
            // Dropdown suggestions
            if (_showDropdown && _etudiant == null) ...[
              const SizedBox(height: 4),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: AppConstants.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.border),
                  ),
                  child: _filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Aucun résultat', style: TextStyle(
                              fontSize: 12, color: AppConstants.secondary)))
                      : ListView(
                          shrinkWrap: true,
                          children: _filtered.map((e) => ListTile(
                            dense: true,
                            leading: InitialesAvatar(initiales: e.initiales, size: 32),
                            title: Text(e.nomComplet,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            subtitle: Text('${e.numeroEtudiant} · ${e.libelleFiliere ?? ''}',
                                style: const TextStyle(fontSize: 10)),
                            onTap: () {
                              setState(() {
                                _etudiant = e;
                                _searchCtrl.text = e.nomComplet;
                                _showDropdown = false;
                                _absences = [];
                                _stats = null;
                                _generated = false;
                              });
                            },
                          )).toList(),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: DropdownButtonFormField<Periode?>(
                value: _periode, isDense: true,
                decoration: const InputDecoration(labelText: 'Période (optionnel)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes les périodes')),
                  ..._periodes.map((p) => DropdownMenuItem(value: p, child: Text(p.idPeriode))),
                ],
                onChanged: (v) => setState(() => _periode = v),
              )),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _generer, child: const Text('Rechercher')),
            ]),
          ]),
        ),

        // ── Carte profil étudiant + stats ─────────────────────
        if (_generated && _etudiant != null && _stats != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppCard(child: Column(children: [
              Row(children: [
                InitialesAvatar(initiales: _etudiant!.initiales, size: 48),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_etudiant!.nomComplet,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${_etudiant!.numeroEtudiant} · ${_etudiant!.libelleFiliere ?? ''}',
                      style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                  if (_periode != null)
                    Text('Période : ${_periode!.idPeriode}',
                        style: const TextStyle(fontSize: 10, color: AppConstants.secondary)),
                ])),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _statCol(
                  '${_stats!['total'] ?? _absences.length}',
                  'Total absences', AppConstants.danger)),
                Expanded(child: _statCol(
                  '${_stats!['justifiees'] ?? 0}',
                  'Justifiées', AppConstants.success)),
                Expanded(child: _statCol(
                  '${_stats!['non_justifiees'] ?? 0}',
                  'Non justifiées', AppConstants.warning)),
              ]),
            ])),
          ),
        ],

        // ── Historique absences ───────────────────────────────
        if (_generated) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Historique des absences',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppConstants.secondary)),
            ),
          ),
        ],
        Expanded(
          child: !_generated
              ? const EmptyState(
                  message: 'Recherchez un étudiant et cliquez sur Rechercher',
                  icon: Icons.person_search_outlined)
              : _absences.isEmpty
                  ? const EmptyState(
                      message: 'Aucune absence enregistrée pour cet étudiant',
                      icon: Icons.check_circle_outline)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _absences.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final a = _absences[i];
                        final statut = a['statut']?.toString() ?? 'absent';
                        final isJustifie = statut == 'justifie';
                        final motif = a['motif']?.toString();
                        final date = a['date_enseignement']?.toString() ?? '';
                        final matiere = a['nom_matiere']?.toString() ?? '';
                        return AppCard(child: Row(children: [
                          Container(
                            width: 4, height: 50,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isJustifie ? AppConstants.success : AppConstants.danger,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(matiere.isNotEmpty ? matiere : '—',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            if (date.isNotEmpty)
                              Text(date, style: const TextStyle(
                                  fontSize: 11, color: AppConstants.secondary)),
                            if (motif != null && motif.isNotEmpty)
                              Text('Motif : $motif', style: const TextStyle(
                                  fontSize: 10, color: AppConstants.secondary)),
                          ])),
                          StatusBadge(
                            label: isJustifie ? 'Justifiée' : 'Non justifiée',
                            type: isJustifie ? 'success' : 'danger',
                          ),
                        ]));
                      },
                    ),
        ),
      ]),
    ),
  );

  Widget _statCol(String value, String label, Color color) => Column(children: [
    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
    Text(label, style: const TextStyle(fontSize: 10, color: AppConstants.secondary),
        textAlign: TextAlign.center),
  ]);
}
