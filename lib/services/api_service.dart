import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/models.dart';

class ApiService {
  static String get base => AppConstants.baseUrl;

  // ── Token ──────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Generic helpers ────────────────────────────────────
  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$base$path'), headers: await _headers());
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> _post(String path, Map body) async {
    final res = await http.post(Uri.parse('$base$path'),
        headers: await _headers(), body: jsonEncode(body));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> _put(String path, Map body) async {
    final res = await http.put(Uri.parse('$base$path'),
        headers: await _headers(), body: jsonEncode(body));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> _delete(String path) async {
    final res = await http.delete(Uri.parse('$base$path'), headers: await _headers());
    return jsonDecode(res.body);
  }

  // ── AUTH ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String username, String password) async {
    return _post('/auth/login', {'username': username, 'password': password});
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  static Future<void> saveSession(String token, Map user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString('user');
    return u != null ? jsonDecode(u) : null;
  }

  // ── FILIERES ────────────────────────────────────────────
  static Future<List<Filiere>> getFilieres() async {
    final r = await _get('/filieres');
    return (r['data'] as List).map((e) => Filiere.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createFiliere(Filiere f) =>
      _post('/filieres', f.toJson());

  static Future<Map<String, dynamic>> updateFiliere(int id, Filiere f) =>
      _put('/filieres/$id', f.toJson());

  static Future<Map<String, dynamic>> deleteFiliere(int id) =>
      _delete('/filieres/$id');

  // ── PERIODES ────────────────────────────────────────────
  static Future<List<Periode>> getPeriodes() async {
    final r = await _get('/periodes');
    return (r['data'] as List).map((e) => Periode.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createPeriode(Periode p) =>
      _post('/periodes', p.toJson());

  static Future<Map<String, dynamic>> updatePeriode(int id, Periode p) =>
      _put('/periodes/$id', p.toJson());

  static Future<Map<String, dynamic>> deletePeriode(int id) =>
      _delete('/periodes/$id');

  // ── MATIERES ────────────────────────────────────────────
  static Future<List<Matiere>> getMatieres({int? filiereId}) async {
    final q = filiereId != null ? '?filiere_id=$filiereId' : '';
    final r = await _get('/matieres$q');
    return (r['data'] as List).map((e) => Matiere.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createMatiere(Matiere m) =>
      _post('/matieres', m.toJson());

  static Future<Map<String, dynamic>> updateMatiere(int id, Matiere m) =>
      _put('/matieres/$id', m.toJson());

  static Future<Map<String, dynamic>> deleteMatiere(int id) =>
      _delete('/matieres/$id');

  // ── ENSEIGNANTS ─────────────────────────────────────────
  static Future<List<Enseignant>> getEnseignants() async {
    final r = await _get('/enseignants');
    return (r['data'] as List).map((e) => Enseignant.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createEnseignant(Enseignant e) =>
      _post('/enseignants', e.toJson());

  static Future<Map<String, dynamic>> updateEnseignant(int id, Enseignant e) =>
      _put('/enseignants/$id', e.toJson());

  static Future<Map<String, dynamic>> deleteEnseignant(int id) =>
      _delete('/enseignants/$id');

  // ── ETUDIANTS ───────────────────────────────────────────
  static Future<List<Etudiant>> getEtudiants({int? filiereId}) async {
    final q = filiereId != null ? '?filiere_id=$filiereId' : '';
    final r = await _get('/etudiants$q');
    return (r['data'] as List).map((e) => Etudiant.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createEtudiant(Etudiant e) =>
      _post('/etudiants', e.toJson());

  static Future<Map<String, dynamic>> updateEtudiant(int id, Etudiant e) =>
      _put('/etudiants/$id', e.toJson());

  static Future<Map<String, dynamic>> deleteEtudiant(int id) =>
      _delete('/etudiants/$id');

  // ── ENSEIGNEMENTS ───────────────────────────────────────
  static Future<List<Enseignement>> getEnseignements({
    int? filiereId, int? matiereId, int? enseignantId, int? periodeId,
  }) async {
    final params = <String>[];
    if (filiereId != null) params.add('filiere_id=$filiereId');
    if (matiereId != null) params.add('matiere_id=$matiereId');
    if (enseignantId != null) params.add('enseignant_id=$enseignantId');
    if (periodeId != null) params.add('periode_id=$periodeId');
    final q = params.isNotEmpty ? '?${params.join('&')}' : '';
    final r = await _get('/enseignements$q');
    return (r['data'] as List).map((e) => Enseignement.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> createEnseignement(Enseignement e) =>
      _post('/enseignements', e.toJson());

  // ── PRESENCES ───────────────────────────────────────────
  static Future<List<Presence>> getPresences({
    int? enseignementId, int? etudiantId, int? filiereId, int? periodeId,
  }) async {
    final params = <String>[];
    if (enseignementId != null) params.add('enseignement_id=$enseignementId');
    if (etudiantId != null) params.add('etudiant_id=$etudiantId');
    if (filiereId != null) params.add('filiere_id=$filiereId');
    if (periodeId != null) params.add('periode_id=$periodeId');
    final q = params.isNotEmpty ? '?${params.join('&')}' : '';
    final r = await _get('/presences$q');
    return (r['data'] as List).map((e) => Presence.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> savePresence(Presence p) =>
      _post('/presences', p.toJson());

  static Future<List<Presence>> getPresencesBySeance(int seanceId) async {
    final r = await _get('/presences/seance/$seanceId');
    return (r['data'] as List? ?? []).map((e) => Presence.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> saveBulkPresences(
    int enseignementId, List<Map<String, dynamic>> presences,
  ) =>
      _post('/presences/save', {
        'enseignement_id': enseignementId,
        'presences': presences,
      });

  static Future<Map<String, dynamic>> updatePresence(int id, String statut) =>
      _put('/presences/$id', {'statut': statut});

  // Upload justificatif avec fichier — POST /api/justifications (multipart/form-data)
  static Future<Map<String, dynamic>> justifierAbsence({
    required int assisterId,
    required String motif,
    String? observations,
    File? fichier,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$base/justifications');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['presence_id'] = assisterId.toString();
    request.fields['motif'] = motif;
    if (observations != null) request.fields['observations'] = observations;
    if (fichier != null) {
      request.files.add(await http.MultipartFile.fromPath('fichier', fichier.path));
    }
    final stream = await request.send();
    final res = await http.Response.fromStream(stream);
    return jsonDecode(res.body);
  }

  // PUT /api/justifications/:id/valider — valider ou refuser une justification
  static Future<Map<String, dynamic>> validerJustification(int id, String statut) =>
      _put('/justifications/$id/valider', {'statut': statut});

  // ── STATS ───────────────────────────────────────────────
  static Future<DashboardStats> getDashboardStats() async {
    final r = await _get('/dashboard');
    return DashboardStats.fromJson(r['data']);
  }

  static Future<Map<String, dynamic>> getRapportEtudiant(int etudiantId, {int? periodeId}) async {
    final q = periodeId != null ? '?periode_id=$periodeId' : '';
    return _get('/etudiants/$etudiantId/absences$q');
  }

  static Future<Map<String, dynamic>> getRapportFiliere(int filiereId, {int? periodeId}) async {
    final params = ['filiere_id=$filiereId'];
    if (periodeId != null) params.add('periode_id=$periodeId');
    return _get('/presences/rapport?${params.join("&")}');
  }

  static Future<Map<String, dynamic>> getEditionMatieres(int filiereId, {int? periodeId}) async {
    final params = ['filiere_id=$filiereId'];
    if (periodeId != null) params.add('periode_id=$periodeId');
    return _get('/dashboard/edition-matieres?${params.join("&")}');
  }
}
