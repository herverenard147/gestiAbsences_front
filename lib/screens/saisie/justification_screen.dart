import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../constants.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class JustificationScreen extends StatefulWidget {
  const JustificationScreen({super.key});
  @override State<JustificationScreen> createState() => _JustificationScreenState();
}

class _JustificationScreenState extends State<JustificationScreen> {
  List<Presence> _absences = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Charger les absences non justifiées + celles en attente de validation
      final all = await ApiService.getPresences();
      setState(() {
        _absences = all.where((p) =>
          p.statut == 'absent' ||
          (p.statut == 'justifie' && p.statutJustif != 'validee')
        ).toList();
        _loading = false;
      });
    } catch (e) { setState(() => _loading = false); }
  }

  void _showJustifForm(Presence p) => showModalBottomSheet(
    context: context, isScrollControlled: true,
    backgroundColor: AppConstants.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _JustifForm(
      presence: p,
      onSaved: (motif, obs, fichier) async {
        try {
          await ApiService.justifierAbsence(
            assisterId: p.id!, motif: motif, observations: obs, fichier: fichier,
          );
          if (mounted) showSnack(context, 'Justification soumise');
          _load();
        } catch (e) { if (mounted) showSnack(context, 'Erreur: $e', error: true); }
      },
    ),
  );

  String _statutLabel(Presence p) {
    if (p.statut == 'justifie') {
      return p.statutJustif == 'validee' ? 'Justifiée'
          : p.statutJustif == 'refusee' ? 'Refusée' : 'En attente';
    }
    return 'Non justifiée';
  }

  String _statutType(Presence p) {
    if (p.statut == 'justifie') {
      return p.statutJustif == 'validee' ? 'success'
          : p.statutJustif == 'refusee' ? 'danger' : 'warning';
    }
    return 'danger';
  }

  @override
  Widget build(BuildContext context) => LoadingOverlay(
    isLoading: _loading,
    child: Scaffold(
      backgroundColor: AppConstants.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _absences.isEmpty && !_loading
            ? const EmptyState(message: 'Aucune absence à traiter', icon: Icons.check_circle_outline)
            : ListView.separated(
                padding: const EdgeInsets.all(16), itemCount: _absences.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = _absences[i];
                  return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      InitialesAvatar(
                        initiales: '${p.nom?[0] ?? '?'}${p.prenom?[0] ?? ''}',
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${p.nom} ${p.prenom}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${p.nomMatiere ?? ''} · ${p.dateEnseignement ?? ''}',
                            style: const TextStyle(fontSize: 11, color: AppConstants.secondary)),
                        if (p.motif != null)
                          Text('Motif: ${p.motif}',
                              style: const TextStyle(fontSize: 10, color: AppConstants.secondary)),
                      ])),
                      StatusBadge(label: _statutLabel(p), type: _statutType(p)),
                    ]),
                    if (p.statut == 'absent') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showJustifForm(p),
                          icon: const Icon(Icons.upload_file_outlined, size: 16),
                          label: const Text('Soumettre justification', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                    if (p.statut == 'justifie' && p.statutJustif == 'en_attente') ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: OutlinedButton(
                          onPressed: () async {
                            await ApiService.validerJustification(p.id!, 'validee');
                            if (mounted) showSnack(context, 'Justification validée');
                            _load();
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: AppConstants.success,
                              side: const BorderSide(color: AppConstants.success)),
                          child: const Text('Valider', style: TextStyle(fontSize: 12)),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(
                          onPressed: () async {
                            await ApiService.validerJustification(p.id!, 'refusee');
                            if (mounted) showSnack(context, 'Justification refusée', error: true);
                            _load();
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: AppConstants.danger,
                              side: const BorderSide(color: AppConstants.danger)),
                          child: const Text('Rejeter', style: TextStyle(fontSize: 12)),
                        )),
                      ]),
                    ],
                  ]));
                },
              ),
      ),
    ),
  );
}

class _JustifForm extends StatefulWidget {
  final Presence presence;
  final Function(String motif, String? obs, File? fichier) onSaved;
  const _JustifForm({required this.presence, required this.onSaved});
  @override State<_JustifForm> createState() => _JustifFormState();
}

class _JustifFormState extends State<_JustifForm> {
  final _obsCtrl = TextEditingController();
  String _motif = 'maladie';
  File? _fichier;
  bool _saving = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() => _fichier = File(result.files.single.path!));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSaved(_motif, _obsCtrl.text.trim(), _fichier);
    if (mounted) { setState(() => _saving = false); Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Soumettre une justification',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('${widget.presence.nom} ${widget.presence.prenom} · ${widget.presence.nomMatiere}',
          style: const TextStyle(fontSize: 12, color: AppConstants.secondary)),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _motif, decoration: const InputDecoration(labelText: 'Motif'),
        items: const [
          DropdownMenuItem(value: 'maladie', child: Text('Maladie')),
          DropdownMenuItem(value: 'deces_famille', child: Text('Décès famille')),
          DropdownMenuItem(value: 'raison_administrative', child: Text('Raison administrative')),
          DropdownMenuItem(value: 'autre', child: Text('Autre')),
        ],
        onChanged: (v) => setState(() => _motif = v!),
      ),
      const SizedBox(height: 10),
      TextFormField(controller: _obsCtrl, maxLines: 3,
          decoration: const InputDecoration(labelText: 'Observations (optionnel)')),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _pickFile,
        icon: const Icon(Icons.attach_file, size: 16),
        label: Text(_fichier != null
            ? _fichier!.path.split('/').last
            : 'Joindre un document', style: const TextStyle(fontSize: 12)),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: _saving ? const SizedBox(height: 18, width: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Soumettre'),
      ),
    ]),
  );
}
