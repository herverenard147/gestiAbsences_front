import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/models.dart';

class ApiService {
  static String get base => AppConstants.baseUrl;

  // ── Token ──────────────────────────────────────────────────
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

  // ── Helpers génériques avec gestion d'erreurs HTTP ─────────
  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$base$path'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 401) throw Exception('Session expirée, reconnectez-vous');
      if (res.statusCode >= 400) {
        throw Exception(body['message'] ?? 'Erreur serveur (${res.statusCode})');
      }
      return body;
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  static Future<Map<String, dynamic>> _post(String path, Map body) async {
    try {
      final res = await http.post(
        Uri.parse('$base$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 401) throw Exception('Session expirée, reconnectez-vous');
      if (res.statusCode >= 400) {
        throw Exception(decoded['message'] ?? 'Erreur serveur (${res.statusCode})');
      }
      return decoded;
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  static Future<Map<String, dynamic>> _put(String path, Map body) async {
    try {
      final res = await http.put(
        Uri.parse('$base$path'),
        headers: await _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 401) throw Exception('Session expirée, reconnectez-vous');
      if (res.statusCode >= 400) {
        throw Exception(decoded['message'] ?? 'Erreur serveur (${res.statusCode})');
      }
      return decoded;
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  static Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final res = await http.delete(
        Uri.parse('$base$path'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 401) throw Exception('Session expirée, reconnectez-vous');
      if (res.statusCode >= 400) {
        throw Exception(decoded['message'] ?? 'Erreur serveur (${res.statusCode})');
      }
      return decoded;
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // Helper sécurisé pour extraire une List depuis la réponse
  static List<T> _parseList<T>(
    Map<String, dynamic> r,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = r['data'];
    if (data == null) return [];
    if (data is! List) return [];
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── AUTH ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String username, String password) =>
      _post('/auth/login', {'username': username, 'password': password});

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
    return u != null ? jsonDecode(u) as Map<String, dynamic> : null;
  }

  // ── FILIÈRES ───────────────────────────────────────────────
  static Future<List<Filiere>> getFilieres() async {
    final r = await _get('/filieres');
    return _parseList(r, Filiere.fromJson);
  }

  static Future<Map<String, dynamic>> createFiliere(Filiere f) =>
      _post('/filieres', f.toJson());

  static Future<Map<String, dynamic>> updateFiliere(int id, Filiere f) =>
      _put('/filieres/$id', f.toJson());

  static Future<Map<String, dynamic>> deleteFiliere(int id) =>
      _delete('/filieres/$id');

  // ── PÉRIODES ───────────────────────────────────────────────
  static Future<List<Periode>> getPeriodes() async {
    final r = await _get('/periodes');
    return _parseList(r, Periode.fromJson);
  }

  static Future<Map<String, dynamic>> createPeriode(Periode p) =>
      _post('/periodes', p.toJson());

  static Future<Map<String, dynamic>> updatePeriode(int id, Periode p) =>
      _put('/periodes/$id', p.toJson());

  static Future<Map<String, dynamic>> deletePeriode(int id) =>
      _delete('/periodes/$id');

  // ── MATIÈRES ───────────────────────────────────────────────
  static Future<List<Matiere>> getMatieres({int? filiereId}) async {
    final q = filiereId != null ? '?filiere_id=$filiereId' : '';
    final r = await _get('/matieres$q');
    return _parseList(r, Matiere.fromJson);
  }

  static Future<Map<String, dynamic>> createMatiere(Matiere m) =>
      _post('/matieres', m.toJson());

  static Future<Map<String, dynamic>> updateMatiere(int id, Matiere m) =>
      _put('/matieres/$id', m.toJson());

  static Future<Map<String, dynamic>> deleteMatiere(int id) =>
      _delete('/matieres/$id');

  // ── ENSEIGNANTS ────────────────────────────────────────────
  static Future<List<Enseignant>> getEnseignants() async {
    final r = await _get('/enseignants');
    return _parseList(r, Enseignant.fromJson);
  }

  static Future<Map<String, dynamic>> createEnseignant(Enseignant e) =>
      _post('/enseignants', e.toJson());

  static Future<Map<String, dynamic>> updateEnseignant(int id, Enseignant e) =>
      _put('/enseignants/$id', e.toJson());

  static Future<Map<String, dynamic>> deleteEnseignant(int id) =>
      _delete('/enseignants/$id');

  // ── ÉTUDIANTS ──────────────────────────────────────────────
  static Future<List<Etudiant>> getEtudiants({int? filiereId}) async {
    final q = filiereId != null ? '?filiere_id=$filiereId' : '';
    final r = await _get('/etudiants$q');
    return _parseList(r, Etudiant.fromJson);
  }

  static Future<Map<String, dynamic>> createEtudiant(Etudiant e) =>
      _post('/etudiants', e.toJson());

  static Future<Map<String, dynamic>> updateEtudiant(int id, Etudiant e) =>
      _put('/etudiants/$id', e.toJson());

  static Future<Map<String, dynamic>> deleteEtudiant(int id) =>
      _delete('/etudiants/$id');

  // ── ENSEIGNEMENTS ──────────────────────────────────────────
  static Future<List<Enseignement>> getEnseignements({
    int? filiereId,
    int? matiereId,
    int? enseignantId,
    int? periodeId,
  }) async {
    final params = <String>[];
    if (filiereId    != null) params.add('filiere_id=$filiereId');
    if (matiereId    != null) params.add('matiere_id=$matiereId');
    if (enseignantId != null) params.add('enseignant_id=$enseignantId');
    if (periodeId    != null) params.add('periode_id=$periodeId');
    final q = params.isNotEmpty ? '?${params.join('&')}' : '';
    final r = await _get('/enseignements$q');
    return _parseList(r, Enseignement.fromJson);
  }

  static Future<Map<String, dynamic>> createEnseignement(Enseignement e) =>
      _post('/enseignements', e.toJson());

  // ── PRÉSENCES ──────────────────────────────────────────────
  static Future<List<Presence>> getPresences({
    int? enseignementId,
    int? etudiantId,
    int? filiereId,
    int? periodeId,
  }) async {
    final params = <String>[];
    if (enseignementId != null) params.add('enseignement_id=$enseignementId');
    if (etudiantId     != null) params.add('etudiant_id=$etudiantId');
    if (filiereId      != null) params.add('filiere_id=$filiereId');
    if (periodeId      != null) params.add('periode_id=$periodeId');
    final q = params.isNotEmpty ? '?${params.join('&')}' : '';
    final r = await _get('/presences$q');
    return _parseList(r, Presence.fromJson);
  }

  static Future<Map<String, dynamic>> savePresence(Presence p) =>
      _post('/presences', p.toJson());

  // POST /api/presences/bulk
  static Future<Map<String, dynamic>> saveBulkPresences(
    int enseignementId,
    List<Map<String, dynamic>> presences,
  ) =>
      _post('/presences/bulk', {
        'enseignement_id': enseignementId,
        'presences': presences,
      });

  // PUT /api/presences/:id
  static Future<Map<String, dynamic>> updatePresence(int id, String statut) =>
      _put('/presences/$id', {'statut': statut});

  // ── JUSTIFICATIONS ─────────────────────────────────────────
  // POST /api/presences/justifier  (multipart/form-data)
  static Future<Map<String, dynamic>> justifierAbsence({
    required int assisterId,
    required String motif,
    String? observations,
    File? fichier,
  }) async {
    final token = await getToken();
    final uri   = Uri.parse('$base/presences/justifier');
    final req   = http.MultipartRequest('POST', uri);
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.fields['assister_id'] = assisterId.toString();
    req.fields['motif']       = motif;
    if (observations != null) req.fields['observations'] = observations;
    if (fichier != null) {
      req.files.add(await http.MultipartFile.fromPath('fichier', fichier.path));
    }
    try {
      final stream = await req.send().timeout(const Duration(seconds: 30));
      final res    = await http.Response.fromStream(stream);
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 400) {
        throw Exception(decoded['message'] ?? 'Erreur envoi justification');
      }
      return decoded;
    } on SocketException {
      throw Exception('Pas de connexion réseau');
    }
  }

  // PUT /api/presences/justifier/:id
  static Future<Map<String, dynamic>> validerJustification(int id, String statut) =>
      _put('/presences/justifier/$id', {'statut_justif': statut});

  // ── DASHBOARD ──────────────────────────────────────────────
  // GET /api/presences/stats/dashboard
  static Future<DashboardStats> getDashboardStats() async {
    final r = await _get('/presences/stats/dashboard');
    // Sécurisation : r['data'] peut être null si le back échoue silencieusement
    final data = r['data'];
    if (data == null) throw Exception('Données dashboard indisponibles');
    return DashboardStats.fromJson(data as Map<String, dynamic>);
  }

  // ── RAPPORTS / ÉDITIONS ────────────────────────────────────
  // GET /api/presences/rapport/filiere?filiere_id=X&periode_id=Y
  // ⚠️ Vraie route backend (presences.js), pas /editions/
  static Future<Map<String, dynamic>> getRapportFiliere(
    int filiereId, {
    int? periodeId,
  }) async {
    final params = ['filiere_id=$filiereId'];
    if (periodeId != null) params.add('periode_id=$periodeId');
    return _get('/presences/rapport/filiere?${params.join('&')}');
  }

  // GET /api/presences/rapport/etudiant/:id?periode_id=Y
  // ⚠️ Vraie route backend (presences.js), pas /editions/
  static Future<Map<String, dynamic>> getRapportEtudiant(
    int etudiantId, {
    int? periodeId,
  }) async {
    final q = periodeId != null ? '?periode_id=$periodeId' : '';
    return _get('/presences/rapport/etudiant/$etudiantId$q');
  }
}
