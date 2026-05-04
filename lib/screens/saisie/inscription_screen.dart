import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});
  @override State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  List<Etudiant> _list = [];
  List<Filiere> _filieres = [];
  Filiere? _selectedFiliere;
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getEtudiants(filiereId: _selectedFiliere?.id),
        ApiService.getFilieres(),
      ]);
      setState(() {
        _list = results[0] as List<Etudiant>;
        _filieres = results[1] as List<Filiere>;
        _loading = false;
      });
    } catch (e) { setState(() => _loading = false); }
  }

  void _showForm([Etudiant? et]) => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: AppConstants.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _EtudiantForm(
      etudiant: et, filieres: _filieres,
      onSaved: (newE) async {
        try {
          if (et == null) await ApiService.createEtudiant(newE);
          else await ApiService.updateEtudiant(et.id!, newE);
          if (mounted) showSnack(context, et == null ? 'Étudiant inscrit' : 'Mis à jour');
          _load();
        } catch (e) { if (mounted) showSnack(context, 'Erreur: $e', error: true); }
      },
    ),
  );

  Future<void> _delete(Etudiant e) async {
    final ok = await showConfirmDialog(context, 'Retirer', 'Retirer "${e.nomComplet}" ?');
    if (ok == true) {
      try {
        await ApiService.deleteEtudiant(e.id!);
        if (mounted) showSnack(context, 'Étudiant retiré');
        _load();
      } catch (err) { if (mounted) showSnack(context, 'Erreur: $err', error: true); }
    }
  }

  String _statutLabel(String s) =>
      s == 'inscrit' ? 'Inscrit' : s == 'en_attente' ? 'En attente' : 'Retiré';
  String _statutType(String s) =>
      s == 'inscrit' ? 'success' : s == 'en_attente' ? 'warning' : 'danger';

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading,
    child: Scaffold(
      backgroundColor: AppConstants.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        label: const Text('Inscrire'), icon: const Icon(Icons.person_add_outlined),
        backgroundColor: AppConstants.primary, foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // Filière filter
        Container(
          padding: const EdgeInsets.all(12),
          color: AppConstants.surface,
          child: DropdownButtonFormField<Filiere?>(
            value: _selectedFiliere,
            decoration: const InputDecoration(labelText: 'Filtrer par filière', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('Toutes les filières')),
              ..._filieres.map((f) => DropdownMenuItem(value: f, child: Text(f.libelleFiliere))),
            ],
            onChanged: (v) {
              setState(() => _selectedFiliere = v);
              _load();
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _list.isEmpty && !_loading
                ? const EmptyState(message: 'Aucun étudiant inscrit', icon: Icons.people_outline)
                : ListView.separated(
                    padding: const EdgeInsets.all(16), itemCount: _list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = _list[i];
                      return AppCard(child: Row(children: [
                        InitialesAvatar(initiales: e.initiales),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.nomComplet,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${e.numeroEtudiant} · ${e.libelleFiliere ?? ''}',
                              style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                          if (e.contactParent != null)
                            Text(e.contactParent!,
                                style: const TextStyle(fontSize: 10, color: AppConstants.secondary)),
                        ])),
                        StatusBadge(label: _statutLabel(e.statut), type: _statutType(e.statut)),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: (v) {
                            if (v == 'edit') _showForm(e);
                            if (v == 'delete') _delete(e);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Modifier')),
                            PopupMenuItem(value: 'delete',
                                child: Text('Retirer', style: TextStyle(color: AppConstants.danger))),
                          ],
                        ),
                      ]));
                    },
                  ),
          ),
        ),
      ]),
    ),
  );
}

class _EtudiantForm extends StatefulWidget {
  final Etudiant? etudiant;
  final List<Filiere> filieres;
  final Function(Etudiant) onSaved;
  const _EtudiantForm({this.etudiant, required this.filieres, required this.onSaved});
  @override State<_EtudiantForm> createState() => _EtudiantFormState();
}

class _EtudiantFormState extends State<_EtudiantForm> {
  final _fk = GlobalKey<FormState>();
  late TextEditingController _num, _nom, _prenom, _contact;
  String _sexe = 'M';
  String _statut = 'en_attente';
  int? _filiereId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.etudiant;
    _num     = TextEditingController(text: e?.numeroEtudiant ?? '');
    _nom     = TextEditingController(text: e?.nom ?? '');
    _prenom  = TextEditingController(text: e?.prenom ?? '');
    _contact = TextEditingController(text: e?.contactParent ?? '');
    _sexe    = e?.sexe ?? 'M';
    _statut  = e?.statut ?? 'en_attente';
    _filiereId = e?.filiereId ?? (widget.filieres.isNotEmpty ? widget.filieres[0].id : null);
  }

  @override
  void dispose() { _num.dispose(); _nom.dispose(); _prenom.dispose(); _contact.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_fk.currentState!.validate() || _filiereId == null) return;
    setState(() => _saving = true);
    await widget.onSaved(Etudiant(
      numeroEtudiant: _num.text.trim(), nom: _nom.text.trim(),
      prenom: _prenom.text.trim(), sexe: _sexe,
      contactParent: _contact.text.trim(), statut: _statut, filiereId: _filiereId!,
    ));
    if (mounted) { setState(() => _saving = false); Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
    child: Form(key: _fk, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.etudiant == null ? 'Inscrire un étudiant' : 'Modifier étudiant',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      TextFormField(controller: _num, decoration: const InputDecoration(labelText: 'N° étudiant'),
          validator: (v) => v!.isEmpty ? 'Requis' : null),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: TextFormField(controller: _nom, decoration: const InputDecoration(labelText: 'Nom'),
            validator: (v) => v!.isEmpty ? 'Requis' : null)),
        const SizedBox(width: 10),
        Expanded(child: TextFormField(controller: _prenom, decoration: const InputDecoration(labelText: 'Prénom'),
            validator: (v) => v!.isEmpty ? 'Requis' : null)),
      ]),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _sexe, decoration: const InputDecoration(labelText: 'Sexe'),
        items: const [
          DropdownMenuItem(value: 'M', child: Text('Masculin')),
          DropdownMenuItem(value: 'F', child: Text('Féminin')),
        ],
        onChanged: (v) => setState(() => _sexe = v!),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<int>(
        value: _filiereId, decoration: const InputDecoration(labelText: 'Filière'),
        items: widget.filieres.map((f) =>
            DropdownMenuItem(value: f.id, child: Text(f.libelleFiliere))).toList(),
        onChanged: (v) => setState(() => _filiereId = v),
        validator: (v) => v == null ? 'Requis' : null,
      ),
      const SizedBox(height: 10),
      TextFormField(controller: _contact, keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Contact parent/tuteur')),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _statut, decoration: const InputDecoration(labelText: 'Statut'),
        items: const [
          DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
          DropdownMenuItem(value: 'inscrit', child: Text('Inscrit')),
          DropdownMenuItem(value: 'retire', child: Text('Retiré')),
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
