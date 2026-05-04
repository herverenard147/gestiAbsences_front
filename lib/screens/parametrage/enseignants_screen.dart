import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class EnseignantsScreen extends StatefulWidget {
  const EnseignantsScreen({super.key});
  @override State<EnseignantsScreen> createState() => _EnseignantsScreenState();
}

class _EnseignantsScreenState extends State<EnseignantsScreen> {
  List<Enseignant> _list = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getEnseignants();
      setState(() { _list = data; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  void _showForm([Enseignant? e]) => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: AppConstants.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _EnseignantForm(
      enseignant: e,
      onSaved: (newE) async {
        try {
          if (e == null) await ApiService.createEnseignant(newE);
          else await ApiService.updateEnseignant(e.id!, newE);
          if (mounted) showSnack(context, e == null ? 'Enseignant créé' : 'Mis à jour');
          _load();
        } catch (err) { if (mounted) showSnack(context, 'Erreur: $err', error: true); }
      },
    ),
  );

  Future<void> _delete(Enseignant e) async {
    final ok = await showConfirmDialog(context, 'Supprimer', 'Supprimer "${e.nomComplet}" ?');
    if (ok == true) {
      try {
        await ApiService.deleteEnseignant(e.id!);
        if (mounted) showSnack(context, 'Enseignant supprimé');
        _load();
      } catch (err) { if (mounted) showSnack(context, 'Erreur: $err', error: true); }
    }
  }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading,
    child: Scaffold(
      backgroundColor: AppConstants.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        label: const Text('Nouvel enseignant'), icon: const Icon(Icons.add),
        backgroundColor: AppConstants.primary, foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _list.isEmpty && !_loading
            ? const EmptyState(message: 'Aucun enseignant')
            : ListView.separated(
                padding: const EdgeInsets.all(16), itemCount: _list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final e = _list[i];
                  return AppCard(child: Row(children: [
                    InitialesAvatar(initiales: '${e.nom[0]}${e.prenom[0]}'),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.nomComplet, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${e.specialite ?? ''} · ${e.mail ?? ''}',
                          style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                    ])),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showForm(e)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppConstants.danger),
                        onPressed: () => _delete(e)),
                  ]));
                },
              ),
      ),
    ),
  );
}

class _EnseignantForm extends StatefulWidget {
  final Enseignant? enseignant;
  final Function(Enseignant) onSaved;
  const _EnseignantForm({this.enseignant, required this.onSaved});
  @override State<_EnseignantForm> createState() => _EnseignantFormState();
}

class _EnseignantFormState extends State<_EnseignantForm> {
  final _fk = GlobalKey<FormState>();
  late TextEditingController _id, _nom, _prenom, _mail, _spec, _diplome;
  String _sexe = 'M';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.enseignant;
    _id     = TextEditingController(text: e?.idEnseignant ?? '');
    _nom    = TextEditingController(text: e?.nom ?? '');
    _prenom = TextEditingController(text: e?.prenom ?? '');
    _mail   = TextEditingController(text: e?.mail ?? '');
    _spec   = TextEditingController(text: e?.specialite ?? '');
    _diplome = TextEditingController(text: e?.diplome ?? '');
    _sexe   = e?.sexe ?? 'M';
  }

  @override
  void dispose() {
    _id.dispose(); _nom.dispose(); _prenom.dispose();
    _mail.dispose(); _spec.dispose(); _diplome.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSaved(Enseignant(
      idEnseignant: _id.text.trim(), nom: _nom.text.trim(),
      prenom: _prenom.text.trim(), mail: _mail.text.trim(),
      specialite: _spec.text.trim(), diplome: _diplome.text.trim(), sexe: _sexe,
    ));
    if (mounted) { setState(() => _saving = false); Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
    child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.enseignant == null ? 'Nouvel enseignant' : 'Modifier enseignant',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      TextFormField(controller: _id, decoration: const InputDecoration(labelText: 'ID (ex: ENS-001)'),
          validator: (v) => v!.isEmpty ? 'Requis' : null),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextFormField(controller: _nom,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (v) => v!.isEmpty ? 'Requis' : null)),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(controller: _prenom,
            decoration: const InputDecoration(labelText: 'Prénom'),
            validator: (v) => v!.isEmpty ? 'Requis' : null)),
      ]),
      const SizedBox(height: 10),
      TextFormField(controller: _mail, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email')),
      const SizedBox(height: 10),
      TextFormField(controller: _spec, decoration: const InputDecoration(labelText: 'Spécialité')),
      const SizedBox(height: 10),
      TextFormField(controller: _diplome, decoration: const InputDecoration(labelText: 'Diplôme')),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _sexe,
        decoration: const InputDecoration(labelText: 'Sexe'),
        items: const [
          DropdownMenuItem(value: 'M', child: Text('Masculin')),
          DropdownMenuItem(value: 'F', child: Text('Féminin')),
        ],
        onChanged: (v) => setState(() => _sexe = v!),
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
