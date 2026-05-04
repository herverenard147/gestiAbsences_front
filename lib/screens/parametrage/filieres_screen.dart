import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class FilieresScreen extends StatefulWidget {
  const FilieresScreen({super.key});
  @override
  State<FilieresScreen> createState() => _FilieresScreenState();
}

class _FilieresScreenState extends State<FilieresScreen> {
  List<Filiere> _list = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getFilieres();
      setState(() { _list = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, 'Erreur: $e', error: true);
    }
  }

  void _showForm([Filiere? filiere]) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppConstants.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FiliereForm(
        filiere: filiere,
        onSaved: (f) async {
          try {
            if (filiere == null) {
              await ApiService.createFiliere(f);
              if (mounted) showSnack(context, 'Filière créée');
            } else {
              await ApiService.updateFiliere(filiere.id!, f);
              if (mounted) showSnack(context, 'Filière mise à jour');
            }
            _load();
          } catch (e) {
            if (mounted) showSnack(context, 'Erreur: $e', error: true);
          }
        },
      ),
    );
  }

  Future<void> _delete(Filiere f) async {
    final ok = await showConfirmDialog(context, 'Supprimer', 'Supprimer "${f.libelleFiliere}" ?');
    if (ok == true) {
      try {
        await ApiService.deleteFiliere(f.id!);
        showSnack(context, 'Filière supprimée');
        _load();
      } catch (e) {
        if (mounted) showSnack(context, 'Erreur: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading,
    child: Scaffold(
      backgroundColor: AppConstants.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle filière'),
        backgroundColor: AppConstants.primary,
        foregroundColor: Colors.white,
      ),
      body: _list.isEmpty && !_loading
          ? const EmptyState(message: 'Aucune filière. Créez-en une !',
              icon: Icons.folder_open_outlined)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final f = _list[i];
                  return AppCard(
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppConstants.infoBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text(f.codeFiliere.substring(0, 2),
                            style: const TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700, color: AppConstants.info))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.libelleFiliere,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${f.codeFiliere} · ${f.nbEtudiants ?? 0} étudiants',
                            style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                      ])),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showForm(f)),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18,
                              color: AppConstants.danger),
                          onPressed: () => _delete(f)),
                    ]),
                  );
                },
              ),
            ),
    ),
  );
}

class _FiliereForm extends StatefulWidget {
  final Filiere? filiere;
  final Function(Filiere) onSaved;
  const _FiliereForm({this.filiere, required this.onSaved});
  @override
  State<_FiliereForm> createState() => _FiliereFormState();
}

class _FiliereFormState extends State<_FiliereForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _code, _libelle, _max;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code   = TextEditingController(text: widget.filiere?.codeFiliere ?? '');
    _libelle = TextEditingController(text: widget.filiere?.libelleFiliere ?? '');
    _max    = TextEditingController(text: '${widget.filiere?.nbreEtudMax ?? 100}');
  }

  @override
  void dispose() { _code.dispose(); _libelle.dispose(); _max.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSaved(Filiere(
      codeFiliere: _code.text.trim(),
      libelleFiliere: _libelle.text.trim(),
      nbreEtudMax: int.tryParse(_max.text) ?? 100,
    ));
    if (mounted) { setState(() => _saving = false); Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
    child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.filiere == null ? 'Nouvelle filière' : 'Modifier filière',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      TextFormField(controller: _code,
          decoration: const InputDecoration(labelText: 'Code filière (ex: INFO-L1)'),
          validator: (v) => v!.isEmpty ? 'Requis' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _libelle,
          decoration: const InputDecoration(labelText: 'Libellé filière'),
          validator: (v) => v!.isEmpty ? 'Requis' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _max,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Nb d'étudiants max")),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(height: 18, width: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Enregistrer'),
      ),
    ])),
  );
}
