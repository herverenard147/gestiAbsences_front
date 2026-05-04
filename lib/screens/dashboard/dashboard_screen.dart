import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final s = await ApiService.getDashboardStats();
      if (!mounted) return; // ← widget peut être détruit pendant l'await
      setState(() {
        _stats = s;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return; // ← idem dans le catch
      setState(() => _loading = false);
      showSnack(context, 'Erreur chargement: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const EmptyState(message: 'Impossible de charger les données');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Métriques
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              MetricCard(label: 'Étudiants inscrits',
                  value: '${_stats!.totalEtudiants}', sub: 'Total actif'),
              MetricCard(label: 'Absences ce mois',
                  value: '${_stats!.absenceMois}', sub: 'Cumulées'),
              MetricCard(label: 'Justifiées',
                  value: '${_stats!.justifiees}',
                  sub: _stats!.absenceMois > 0
                      ? '${(_stats!.justifiees / _stats!.absenceMois * 100).toStringAsFixed(0)}% du total'
                      : '0%',
                  valueColor: AppConstants.success),
              MetricCard(label: 'Non justifiées',
                  value: '${_stats!.nonJustifiees}',
                  valueColor: AppConstants.danger),
            ],
          ),
          const SizedBox(height: 16),

          // Absences récentes
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Absences récentes'),
            const SizedBox(height: 12),
            if (_stats!.recentes.isEmpty)
              const EmptyState(message: 'Aucune absence récente')
            else
              ..._stats!.recentes.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  InitialesAvatar(
                    initiales: '${a['nom']?[0] ?? ''}${a['prenom']?[0] ?? ''}',
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${a['nom']} ${a['prenom']}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(a['nom_matiere'] ?? '',
                        style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                  ])),
                  StatusBadge(
                    label: a['statut'] == 'justifie' ? 'Justifiée' : 'Non justifiée',
                    type: a['statut'] == 'justifie' ? 'success' : 'danger',
                  ),
                ]),
              )),
          ])),
          const SizedBox(height: 16),

          // Taux par filière
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: "Taux d'absence par filière"),
            const SizedBox(height: 14),
            ..._stats!.tauxParFiliere.map((f) {
              final totalAbs = (f['total_absences'] ?? 0) as int;
              final nbEtu = (f['nb_etudiants'] ?? 1) as int;
              final taux = nbEtu > 0 ? (totalAbs / nbEtu * 10).clamp(0, 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(f['libelle_filiere'] ?? '',
                        style: const TextStyle(fontSize: 12)),
                    Text('${taux.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: taux / 100,
                      minHeight: 4,
                      backgroundColor: AppConstants.background,
                      color: taux > 10 ? AppConstants.danger
                          : taux > 6 ? AppConstants.warning
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