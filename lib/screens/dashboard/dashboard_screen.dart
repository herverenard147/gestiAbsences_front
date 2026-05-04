import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

// Helper PostgreSQL-safe (cast String → int)
int _i(dynamic v, [int fb = 0]) =>
    v == null ? fb : int.tryParse(v.toString()) ?? fb;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /*Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final s = await ApiService.getDashboardStats();
      if (!mounted) return;
      setState(() { _stats = s; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
      showSnack(context, 'Erreur chargement: $e', error: true);
    }
  }*/
  
  Future<void> _load() async {
  if (!mounted) return;
  setState(() { _loading = true; _error = null; });
  try {
    final r = await ApiService._get('/dashboard');  // appel direct temporaire
    debugPrint('Dashboard raw: $r');  // ← ça te montrera exactement ce qui arrive
    final s = await ApiService.getDashboardStats();
    if (!mounted) return;
    setState(() { _stats = s; _loading = false; });
  } catch (e, stack) {
    debugPrint('ERREUR DASHBOARD: $e');
    debugPrint('STACK: $stack');       // ← ligne exacte du crash
    if (!mounted) return;
    setState(() { _loading = false; _error = e.toString(); });
  }
}

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off_outlined, size: 48, color: AppConstants.secondary),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: AppConstants.secondary, fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Réessayer'),
        ),
      ],
    ));
    if (_stats == null) return const EmptyState(message: 'Impossible de charger les données');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Métriques ──────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              MetricCard(
                label: 'Étudiants inscrits',
                value: '${_stats!.totalEtudiants}',
                sub: 'Total actif',
              ),
              MetricCard(
                label: 'Absences ce mois',
                value: '${_stats!.absenceMois}',
                sub: 'Cumulées',
              ),
              MetricCard(
                label: 'Justifiées',
                value: '${_stats!.justifiees}',
                sub: _stats!.absenceMois > 0
                    ? '${(_stats!.justifiees / _stats!.absenceMois * 100).toStringAsFixed(0)}% du total'
                    : '0%',
                valueColor: AppConstants.success,
              ),
              MetricCard(
                label: 'Non justifiées',
                value: '${_stats!.nonJustifiees}',
                valueColor: AppConstants.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Absences récentes ──────────────────────────────
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Absences récentes'),
            const SizedBox(height: 12),
            if (_stats!.recentes.isEmpty)
              const EmptyState(message: 'Aucune absence récente')
            else
              ..._stats!.recentes.map((a) {
                // Sécurisation des champs String nullable
                final nom    = (a['nom']    as String?) ?? '';
                final prenom = (a['prenom'] as String?) ?? '';
                final initN  = nom.isNotEmpty    ? nom[0]    : '?';
                final initP  = prenom.isNotEmpty ? prenom[0] : '';
                final matiere = (a['nom_matiere'] as String?) ?? '—';
                final statut  = (a['statut']     as String?) ?? 'absent';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    InitialesAvatar(initiales: '$initN$initP', size: 34),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$nom $prenom',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(matiere,
                          style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                    ])),
                    StatusBadge(
                      label: statut == 'justifie' ? 'Justifiée' : 'Non justifiée',
                      type:  statut == 'justifie' ? 'success'   : 'danger',
                    ),
                  ]),
                );
              }),
          ])),
          const SizedBox(height: 16),

          // ── Taux par filière ───────────────────────────────
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: "Taux d'absence par filière"),
            const SizedBox(height: 14),
            if (_stats!.tauxParFiliere.isEmpty)
              const EmptyState(message: 'Aucune donnée de filière')
            else
              ..._stats!.tauxParFiliere.map((f) {
                // Cast PostgreSQL-safe via helper _i
                final totalAbs = _i(f['total_absences']);
                final nbEtu    = _i(f['nb_etudiants'], 1);
                final libelle  = (f['libelle_filiere'] as String?) ?? '—';
                final taux = nbEtu > 0
                    ? (totalAbs / nbEtu * 10).clamp(0.0, 100.0)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(libelle,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis)),
                      Text('${taux.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 11, color: AppConstants.secondary)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        minHeight: 4,
                        backgroundColor: AppConstants.background,
                        color: taux > 10 ? AppConstants.danger
                             : taux > 6  ? AppConstants.warning
                             : AppConstants.success,
                      ),
                    ),
                  ]),
                );
              }),
          ])),
        ],
      ),
    );
  }
}
