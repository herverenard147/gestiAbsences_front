import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

// ══════════════════════════════════════════════════════════════
// PÉRIODES
// ══════════════════════════════════════════════════════════════
class PeriodesScreen extends StatefulWidget {
  const PeriodesScreen({super.key});
  @override State<PeriodesScreen> createState() => _PeriodesScreenState();
}
class _PeriodesScreenState extends State<PeriodesScreen> {
  List<Periode> _list = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getPeriodes();
      setState(() { _list = data; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  Color _statutColor(String s) => s == 'actif' ? AppConstants.success
      : s == 'a_venir' ? AppConstants.info : AppConstants.secondary;
  String _statutLabel(String s) => s == 'actif' ? 'Actif'
      : s == 'a_venir' ? 'À venir' : 'Terminé';
  String _statutType(String s) => s == 'actif' ? 'success'
      : s == 'a_venir' ? 'info' : 'warning';

  void _showForm([Periode? p]) => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: AppConstants.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _PeriodeForm(
      periode: p,
      onSaved: (newP) async {
        try {
          if (p == null) await ApiService.createPeriode(newP);
          else await ApiService.updatePeriode(p.id!, newP);
          if (mounted) showSnack(context, p == null ? 'Période créée' : 'Mise à jour');
          _load();
        } catch (e) { if (mounted) showSnack(context, 'Erreur: $e', error: true); }
      },
    ),
  );

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading,
    child: Scaffold(
      backgroundColor: AppConstants.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        label: const Text('Nouvelle période'),
        icon: const Icon(Icons.add),
        backgroundColor: AppConstants.primary, foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _list.isEmpty && !_loading
            ? const EmptyState(message: 'Aucune période')
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = _list[i];
                  return AppCard(child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.idPeriode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      if (p.datePeriode.isNotEmpty)
                        Text(p.datePeriode, style: const TextStyle(fontSize: 12, color: AppConstants.secondary)),
                      Text('${p.dateDebut} → ${p.dateFin}',
                          style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                    ])),
                    StatusBadge(label: _statutLabel(p.statut), type: _statutType(p.statut)),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showForm(p)),
                  ]));
                },
              ),
      ),
    ),
  );
}

class _PeriodeForm extends StatefulWidget {
  final Periode? periode;
  final Function(Periode) onSaved;
  const _PeriodeForm({this.periode, required this.onSaved});
  @override State<_PeriodeForm> createState() => _PeriodeFormState();
}
class _PeriodeFormState extends State<_PeriodeForm> {
  final _fk = GlobalKey<FormState>();
  late TextEditingController _id, _libelle, _debut, _fin;
  String _statut = 'a_venir';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _id = TextEditingController(text: widget.periode?.idPeriode ?? '');
    _libelle = TextEditingController(text: widget.periode?.datePeriode ?? '');
    _debut = TextEditingController(text: widget.periode?.dateDebut ?? '');
    _fin = TextEditingController(text: widget.periode?.dateFin ?? '');
    _statut = widget.periode?.statut ?? 'a_venir';
  }

  Future<void> _save() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSaved(Periode(
      idPeriode: _id.text.trim(), datePeriode: _libelle.text.trim(),
      dateDebut: _debut.text.trim(), dateFin: _fin.text.trim(), statut: _statut,
    ));
    if (mounted) { setState(() => _saving = false); Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
    child: Form(key: _fk, child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.periode == null ? 'Nouvelle période' : 'Modifier période',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      TextFormField(controller: _id, decoration: const InputDecoration(labelText: 'ID Période (ex: P-2024-S1)'),
          validator: (v) => v!.isEmpty ? 'Requis' : null),
      const SizedBox(height: 10),
      TextFormField(controller: _libelle, decoration: const InputDecoration(labelText: 'Libellé'),
          validator: (v) => v!.isEmpty ? 'Requis' : null),
      const SizedBox(height: 10),
      TextFormField(
        controller: _debut,
        readOnly: true,
        decoration: const InputDecoration(labelText: 'Date début', suffixIcon: Icon(Icons.calendar_today, size: 16)),
        validator: (v) => v!.isEmpty ? 'Requis' : null,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(_debut.text) ?? DateTime.now(),
            firstDate: DateTime(2020), lastDate: DateTime(2035),
          );
          if (picked != null) _debut.text = picked.toIso8601String().substring(0, 10);
        },
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _fin,
        readOnly: true,
        decoration: const InputDecoration(labelText: 'Date fin', suffixIcon: Icon(Icons.calendar_today, size: 16)),
        validator: (v) => v!.isEmpty ? 'Requis' : null,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(_fin.text) ?? DateTime.now(),
            firstDate: DateTime(2020), lastDate: DateTime(2035),
          );
          if (picked != null) _fin.text = picked.toIso8601String().substring(0, 10);
        },
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _statut,
        decoration: const InputDecoration(labelText: 'Statut'),
        items: const [
          DropdownMenuItem(value: 'a_venir', child: Text('À venir')),
          DropdownMenuItem(value: 'actif', child: Text('Actif')),
          DropdownMenuItem(value: 'termine', child: Text('Terminé')),
        ],
        onChanged: (v) => setState(() => _statut = v!),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: _saving ? const SizedBox(height: 18, width: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Enregistrer'),
      ),
    ])),
  );
}
