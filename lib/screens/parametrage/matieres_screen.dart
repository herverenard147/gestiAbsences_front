import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});
  @override State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {
  List<Matiere> _list = [];
  List<Filiere> _filieres = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getMatieres(), ApiService.getFilieres()]);
      setState(() {
        _list = results[0] as List<Matiere>;
        _filieres = results[1] as List<Filiere>;
        _loading = false;
      });
    } catch (e) { setState(() => _loading = false); }
  }

  void _showForm([Matiere? m]) => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: AppConstants.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _MatiereForm(
      matiere: m, filieres: _filieres,
      onSaved: (newM) async {
        try {
          if (m == null) await ApiService.createMatiere(newM);
          else await ApiService.updateMatiere(m.id!, newM);
          if (mounted) showSnack(context, m == null ? 'Matière créée' : 'Mise à jour');
          _load();
        } catch (e) { if (mounted) showSnack(context, 'Erreur: $e', error: true); }
      },
    ),
  );

  Future<void> _delete(Matiere m) async {
    final ok = await showConfirmDialog(context, 'Supprimer', 'Supprimer "${m.nomMatiere}" ?');
    if (ok == true) {
      try {
        await ApiService.deleteMatiere(m.id!);
        if (mounted) showSnack(context, 'Matière supprimée');
        _load();
      } catch (e) { if (mounted) showSnack(context, 'Erreur: $e', error: true); }
    }
  }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading,
    child: Scaffold(
      backgroundColor: AppConstants.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        label: const Text('Nouvelle matière'), icon: const Icon(Icons.add),
        backgroundColor: AppConstants.primary, foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _list.isEmpty && !_loading
            ? const EmptyState(message: 'Aucune matière')
            : ListView.separated(
                padding: const EdgeInsets.all(16), itemCount: _list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final m = _list[i];
                  return AppCard(child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppConstants.successBg,
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(m.codeMatiere.substring(0, 3).toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppConstants.success))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.nomMatiere, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${m.libelleFiliere ?? ''} · ${m.volumeHoraire}h',
                          style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                    ])),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showForm(m)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppConstants.danger),
                        onPressed: () => _delete(m)),
                  ]));
                },
              ),
      ),
    ),
  );
}

class _MatiereForm extends StatefulWidget {
  final Matiere? matiere;
  final List<Filiere> filieres;
  final Function(Matiere) onSaved;
  const _MatiereForm({this.matiere, required this.filieres, required this.onSaved});
  @override State<_MatiereForm> createState() => _MatiereFormState();
}
class _MatiereFormState extends State<_MatiereForm> {
  final _fk = GlobalKey<FormState>();
  late TextEditingController _code, _nom, _heures;
  int? _filiereId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.matiere?.codeMatiere ?? '');
    _nom = TextEditingController(text: widget.matiere?.nomMatiere ?? '');
    _heures = TextEditingController(text: '${widget.matiere?.volumeHoraire ?? 0}');
    _filiereId = widget.matiere?.filiereId ?? (widget.filieres.isNotEmpty ? widget.filieres[0].id : null);
  }

  Future<void> _save() async {
    if (!_fk.currentState!.validate() || _filiereId == null) return;
    setState(() => _saving = true);
    await widget.onSaved(Matiere(
      codeMatiere: _code.text.trim(), nomMatiere: _nom.text.trim(),
      volumeHoraire: int.tryParse(_heures.text) ?? 0, filiereId: _filiereId!,
    ));
    if (mounted) { setState(() => _saving = false); Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
    child: Form(key: _fk, child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.matiere == null ? 'Nouvelle matière' : 'Modifier matière',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      TextFormField(controller: _code, decoration: const InputDecoration(labelText: 'Code matière'),
          validator: (v) => v!.isEmpty ? 'Requis' : null),
      const SizedBox(height: 10),
      TextFormField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom de la matière'),
          validator: (v) => v!.isEmpty ? 'Requis' : null),
      const SizedBox(height: 10),
      DropdownButtonFormField<int>(
        value: _filiereId,
        decoration: const InputDecoration(labelText: 'Filière'),
        items: widget.filieres.map((f) =>
            DropdownMenuItem(value: f.id, child: Text(f.libelleFiliere))).toList(),
        onChanged: (v) => setState(() => _filiereId = v),
        validator: (v) => v == null ? 'Requis' : null,
      ),
      const SizedBox(height: 10),
      TextFormField(controller: _heures, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Volume horaire (h)')),
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
