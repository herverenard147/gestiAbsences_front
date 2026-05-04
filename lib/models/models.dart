// ============================================================
// MODELS — GestiAbsences Flutter (PostgreSQL compatible)
// ============================================================

// Helper pour parser les int retournés parfois en String par PostgreSQL
int _parseInt(dynamic v, [int fallback = 0]) =>
    v == null ? fallback : int.tryParse(v.toString()) ?? fallback;

// ─────────────────────────────────────────────────────────────
class Filiere {
  final int? id;
  final String codeFiliere;
  final String libelleFiliere;
  final int nbreEtudMax;
  final int? nbEtudiants;

  Filiere({this.id, required this.codeFiliere, required this.libelleFiliere,
      this.nbreEtudMax = 100, this.nbEtudiants});

  factory Filiere.fromJson(Map<String, dynamic> j) => Filiere(
    id:              _parseInt(j['id']),
    codeFiliere:     j['code_filiere'] ?? '',
    libelleFiliere:  j['libelle_filiere'] ?? '',
    nbreEtudMax:     _parseInt(j['nbre_etud_max'], 100),
    nbEtudiants:     j['nb_etudiants'] != null ? _parseInt(j['nb_etudiants']) : null,
  );

  Map<String, dynamic> toJson() => {
    'code_filiere': codeFiliere,
    'libelle_filiere': libelleFiliere,
    'nbre_etud_max': nbreEtudMax,
  };
}

// ─────────────────────────────────────────────────────────────
class Periode {
  final int? id;
  final String idPeriode;
  final String datePeriode;
  final String dateDebut;
  final String dateFin;
  final String statut;

  Periode({this.id, required this.idPeriode, required this.datePeriode,
      required this.dateDebut, required this.dateFin, this.statut = 'a_venir'});

  factory Periode.fromJson(Map<String, dynamic> j) => Periode(
    id:          _parseInt(j['id']),
    idPeriode:   j['id_periode'] ?? '',
    datePeriode: j['date_periode']?.toString() ?? '',
    dateDebut:   j['date_debut']?.toString() ?? '',
    dateFin:     j['date_fin']?.toString() ?? '',
    statut:      j['statut'] ?? 'a_venir',
  );

  Map<String, dynamic> toJson() => {
    'id_periode': idPeriode,
    'date_periode': datePeriode,
    'date_debut': dateDebut,
    'date_fin': dateFin,
    'statut': statut,
  };
}

// ─────────────────────────────────────────────────────────────
class Matiere {
  final int? id;
  final String codeMatiere;
  final String nomMatiere;
  final int volumeHoraire;
  final int filiereId;
  final String? libelleFiliere;

  Matiere({this.id, required this.codeMatiere, required this.nomMatiere,
      this.volumeHoraire = 0, required this.filiereId, this.libelleFiliere});

  factory Matiere.fromJson(Map<String, dynamic> j) => Matiere(
    id:             _parseInt(j['id']),
    codeMatiere:    j['code_matiere'] ?? '',
    nomMatiere:     j['nom_matiere'] ?? '',
    volumeHoraire:  _parseInt(j['volume_horaire']),
    filiereId:      _parseInt(j['filiere_id']),
    libelleFiliere: j['libelle_filiere'],
  );

  Map<String, dynamic> toJson() => {
    'code_matiere': codeMatiere,
    'nom_matiere': nomMatiere,
    'volume_horaire': volumeHoraire,
    'filiere_id': filiereId,
  };
}

// ─────────────────────────────────────────────────────────────
class Enseignant {
  final int? id;
  final String idEnseignant;
  final String nom;
  final String prenom;
  final String? mail;
  final String? specialite;
  final String? diplome;
  final String sexe;

  Enseignant({this.id, required this.idEnseignant, required this.nom,
      required this.prenom, this.mail, this.specialite, this.diplome, this.sexe = 'M'});

  String get nomComplet => '$nom $prenom';

  factory Enseignant.fromJson(Map<String, dynamic> j) => Enseignant(
    id:           _parseInt(j['id']),
    idEnseignant: j['id_enseignant'] ?? '',
    nom:          j['nom'] ?? '',
    prenom:       j['prenom'] ?? '',
    mail:         j['mail'],
    specialite:   j['specialite'],
    diplome:      j['diplome'],
    sexe:         j['sexe'] ?? 'M',
  );

  Map<String, dynamic> toJson() => {
    'id_enseignant': idEnseignant,
    'nom': nom,
    'prenom': prenom,
    'mail': mail,
    'specialite': specialite,
    'diplome': diplome,
    'sexe': sexe,
  };
}

// ─────────────────────────────────────────────────────────────
class Etudiant {
  final int? id;
  final String numeroEtudiant;
  final String nom;
  final String prenom;
  final String sexe;
  final String? contactParent;
  final String statut;
  final int filiereId;
  final String? libelleFiliere;

  Etudiant({this.id, required this.numeroEtudiant, required this.nom,
      required this.prenom, this.sexe = 'M', this.contactParent,
      this.statut = 'en_attente', required this.filiereId, this.libelleFiliere});

  String get nomComplet => '$nom $prenom';
  String get initiales => '${nom.isNotEmpty ? nom[0] : ''}${prenom.isNotEmpty ? prenom[0] : ''}';

  factory Etudiant.fromJson(Map<String, dynamic> j) => Etudiant(
    id:              _parseInt(j['id']),
    numeroEtudiant:  j['numero_etudiant'] ?? '',
    nom:             j['nom'] ?? '',
    prenom:          j['prenom'] ?? '',
    sexe:            j['sexe'] ?? 'M',
    contactParent:   j['contact_parent'],
    statut:          j['statut'] ?? 'en_attente',
    filiereId:       _parseInt(j['filiere_id']),
    libelleFiliere:  j['libelle_filiere'],
  );

  Map<String, dynamic> toJson() => {
    'numero_etudiant': numeroEtudiant,
    'nom': nom,
    'prenom': prenom,
    'sexe': sexe,
    'contact_parent': contactParent,
    'statut': statut,
    'filiere_id': filiereId,
  };
}

// ─────────────────────────────────────────────────────────────
class Enseignement {
  final int? id;
  final String idEnseignement;
  final String dateEnseignement;
  final String? horaire;
  final int enseignantId;
  final int matiereId;
  final int periodeId;
  final String? nomMatiere;
  final String? ensNom;
  final String? ensPrenom;
  final String? libelleFiliere;

  Enseignement({this.id, required this.idEnseignement, required this.dateEnseignement,
      this.horaire, required this.enseignantId, required this.matiereId,
      required this.periodeId, this.nomMatiere, this.ensNom, this.ensPrenom,
      this.libelleFiliere});

  factory Enseignement.fromJson(Map<String, dynamic> j) => Enseignement(
    id:                 _parseInt(j['id']),
    idEnseignement:     j['id_enseignement'] ?? '',
    dateEnseignement:   j['date_enseignement']?.toString() ?? '',
    horaire:            j['horaire'],
    enseignantId:       _parseInt(j['enseignant_id']),
    matiereId:          _parseInt(j['matiere_id']),
    periodeId:          _parseInt(j['periode_id']),
    nomMatiere:         j['nom_matiere'],
    ensNom:             j['ens_nom'],
    ensPrenom:          j['ens_prenom'],
    libelleFiliere:     j['libelle_filiere'],
  );

  Map<String, dynamic> toJson() => {
    'id_enseignement': idEnseignement,
    'date_enseignement': dateEnseignement,
    'horaire': horaire,
    'enseignant_id': enseignantId,
    'matiere_id': matiereId,
    'periode_id': periodeId,
  };
}

// ─────────────────────────────────────────────────────────────
class Presence {
  final int? id;
  final int etudiantId;
  final int enseignementId;
  String statut; // present | absent | justifie
  final String? nom;
  final String? prenom;
  final String? numeroEtudiant;
  final String? nomMatiere;
  final String? dateEnseignement;
  final String? motif;
  final String? statutJustif;

  Presence({this.id, required this.etudiantId, required this.enseignementId,
      this.statut = 'absent', this.nom, this.prenom, this.numeroEtudiant,
      this.nomMatiere, this.dateEnseignement, this.motif, this.statutJustif});

  factory Presence.fromJson(Map<String, dynamic> j) => Presence(
    id:               _parseInt(j['id']),
    etudiantId:       _parseInt(j['etudiant_id']),
    enseignementId:   _parseInt(j['enseignement_id']),
    statut:           j['statut'] ?? 'absent',
    nom:              j['nom'],
    prenom:           j['prenom'],
    numeroEtudiant:   j['numero_etudiant'],
    nomMatiere:       j['nom_matiere'],
    dateEnseignement: j['date_enseignement']?.toString(),
    motif:            j['motif'],
    statutJustif:     j['statut_justif'],
  );

  Map<String, dynamic> toJson() => {
    'etudiant_id': etudiantId,
    'enseignement_id': enseignementId,
    'statut': statut,
  };
}

// ─────────────────────────────────────────────────────────────
class DashboardStats {
  final int totalEtudiants;
  final int absenceMois;
  final int justifiees;
  final int nonJustifiees;
  final List<Map<String, dynamic>> tauxParFiliere;
  final List<Map<String, dynamic>> recentes;

  DashboardStats({required this.totalEtudiants, required this.absenceMois,
      required this.justifiees, required this.nonJustifiees,
      required this.tauxParFiliere, required this.recentes});

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    // PostgreSQL retourne les COUNT/SUM en String → _parseInt obligatoire
    totalEtudiants: _parseInt(j['totalEtudiants']),
    absenceMois:    _parseInt(j['absenceMois']),
    justifiees:     _parseInt(j['justifiees']),
    nonJustifiees:  _parseInt(j['nonJustifiees']),
    tauxParFiliere: (j['tauxParFiliere'] as List? ?? [])
        .map((e) => _normalizeFiliereMap(Map<String, dynamic>.from(e)))
        .toList(),
    recentes: List<Map<String, dynamic>>.from(j['recentes'] ?? []),
  );
}

// Normalise les valeurs numériques dans chaque filière
Map<String, dynamic> _normalizeFiliereMap(Map<String, dynamic> f) => {
  ...f,
  'total_absences': _parseInt(f['total_absences']),
  'nb_etudiants':   _parseInt(f['nb_etudiants'], 1),
};