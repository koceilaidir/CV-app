import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

String newId() {
  final r = Random();
  return DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
      r.nextInt(1 << 32).toRadixString(36);
}

/// Un élément de liste (expérience, formation, compétence…).
/// Les champs texte sont dans [v] ; [level] sert aux compétences (0-100).
class Entry {
  Entry({String? id, Map<String, String>? v, this.level = 70})
      : id = id ?? newId(),
        v = v ?? {};

  final String id;
  final Map<String, String> v;
  int level;

  String operator [](String k) => (v[k] ?? '').trim();
  void operator []=(String k, String value) => v[k] = value;

  bool get isEmpty => v.values.every((s) => s.trim().isEmpty);

  Entry copy() => Entry(v: Map.of(v), level: level);

  Map<String, dynamic> toJson() => {'id': id, 'v': v, 'level': level};

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as String?,
        v: (j['v'] as Map? ?? {}).map((k, val) => MapEntry('$k', '$val')),
        level: (j['level'] as num?)?.toInt() ?? 70,
      );
}

/// Toutes les sections possibles d'un CV. Chaque modèle n'en affiche qu'une partie.
class Sec {
  static const identity = 'identity';
  static const contact = 'contact';
  static const summary = 'summary';
  static const experiences = 'experiences';
  static const education = 'education';
  static const skills = 'skills';
  static const tools = 'tools';
  static const languages = 'languages';
  static const achievements = 'achievements';
  static const projects = 'projects';
  static const references = 'references';
  static const training = 'training';
  static const interests = 'interests';

  static const lists = [
    experiences, education, skills, tools, languages, achievements,
    projects, references, training, interests,
  ];
}

class CvData {
  CvData({Map<String, String>? info, this.photo, Map<String, List<Entry>>? lists})
      : info = info ?? {},
        lists = lists ?? {} {
    for (final k in Sec.lists) {
      this.lists.putIfAbsent(k, () => []);
    }
  }

  /// firstName, lastName, title, summary, phone, email, address, website, linkedin
  final Map<String, String> info;

  /// Photo JPEG compressée, ou null.
  Uint8List? photo;
  final Map<String, List<Entry>> lists;

  String operator [](String k) => (info[k] ?? '').trim();
  void operator []=(String k, String value) => info[k] = value;

  /// Éléments non vides d'une liste.
  List<Entry> items(String k) => (lists[k] ?? []).where((e) => !e.isEmpty).toList();

  String get fullName => [this['firstName'], this['lastName']].where((s) => s.isNotEmpty).join(' ');

  CvData copy() => CvData(
        info: Map.of(info),
        photo: photo,
        lists: lists.map((k, l) => MapEntry(k, l.map((e) => e.copy()).toList())),
      );

  Map<String, dynamic> toJson() => {
        'info': info,
        'photo': photo == null ? null : base64Encode(photo!),
        'lists': lists.map((k, l) => MapEntry(k, l.map((e) => e.toJson()).toList())),
      };

  factory CvData.fromJson(Map<String, dynamic> j) => CvData(
        info: (j['info'] as Map? ?? {}).map((k, v) => MapEntry('$k', '$v')),
        photo: j['photo'] == null ? null : base64Decode(j['photo'] as String),
        lists: (j['lists'] as Map? ?? {}).map((k, l) => MapEntry(
              '$k',
              (l as List).map((e) => Entry.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
            )),
      );

  factory CvData.empty() => CvData();

  /// Exemple fictif utilisé pour les vignettes et le bouton « Remplir avec l'exemple ».
  factory CvData.sample() {
    Entry e(Map<String, String> v, [int level = 70]) => Entry(v: v, level: level);
    Entry s(String text) => Entry(v: {'text': text});
    return CvData(info: {
      'firstName': 'Yanis',
      'lastName': 'Belkacem',
      'title': 'Développeur mobile Flutter',
      'summary':
          "Développeur mobile avec 6 ans d'expérience sur Flutter et Firebase. Je transforme un besoin métier en application simple, rapide et fiable, du prototype jusqu'à la publication sur les stores.",
      'phone': '+213 555 12 34 56',
      'email': 'yanis.belkacem@email.com',
      'address': 'Hydra, Alger',
      'website': 'yanisdev.com',
      'linkedin': 'linkedin.com/in/yanisbelkacem',
    }, lists: {
      Sec.experiences: [
        e({
          'role': 'Développeur Flutter senior', 'company': 'Numidia Apps', 'place': 'Alger',
          'start': '2022', 'end': 'Présent',
          'desc': 'Responsable de trois applications grand public, 400 000 téléchargements cumulés.',
          'bullets': 'Migration vers Riverpod et une architecture propre\nTemps de démarrage réduit de 40 %\nEncadrement de deux développeurs juniors',
        }),
        e({
          'role': 'Développeur mobile', 'company': 'Sahel Logistique', 'place': 'Oran',
          'start': '2019', 'end': '2022',
          'desc': 'Application de suivi des livraisons utilisée par 250 chauffeurs.',
          'bullets': 'Mode hors ligne avec synchronisation automatique\nIntégration Google Maps et notifications push',
        }),
        e({
          'role': 'Développeur web stagiaire', 'company': 'Atlas Digital', 'place': 'Tizi Ouzou',
          'start': '2018', 'end': '2019', 'desc': 'Sites vitrines et back-offices pour des PME locales.',
        }),
      ],
      Sec.education: [
        e({'degree': 'Master en génie logiciel', 'school': 'Université Mouloud Mammeri', 'place': 'Tizi Ouzou', 'start': '2016', 'end': '2018', 'details': 'Mention bien'}),
        e({'degree': 'Licence en informatique', 'school': 'Université Mouloud Mammeri', 'place': 'Tizi Ouzou', 'start': '2013', 'end': '2016'}),
      ],
      Sec.skills: [
        e({'name': 'Flutter / Dart'}, 95),
        e({'name': 'Firebase'}, 85),
        e({'name': 'Supabase'}, 70),
        e({'name': 'UI/UX mobile'}, 80),
        e({'name': 'API REST'}, 85),
        e({'name': 'Git et CI/CD'}, 65),
      ],
      Sec.tools: [s('Figma'), s('Android Studio'), s('Xcode'), s('Postman'), s('Jira')],
      Sec.languages: [
        e({'name': 'Kabyle', 'level': 'Langue maternelle'}),
        e({'name': 'Français', 'level': 'Courant'}),
        e({'name': 'Arabe', 'level': 'Courant'}),
        e({'name': 'Anglais', 'level': 'Professionnel'}),
      ],
      Sec.achievements: [
        s('Application « Souk Express » primée meilleure app locale 2023'),
        s('Intervenant au Flutter Day Alger 2024'),
        s('Contributeur à deux paquets open source sur pub.dev'),
      ],
      Sec.projects: [
        e({'name': 'Souk Express', 'desc': 'Marketplace mobile avec paiement à la livraison et suivi en temps réel.'}),
        e({'name': 'MedRDV', 'desc': 'Prise de rendez-vous médicaux pour cliniques privées.'}),
      ],
      Sec.references: [
        e({'name': 'Samir Ouali', 'role': 'CTO, Numidia Apps', 'phone': '+213 555 98 76 54', 'email': 's.ouali@numidia.dz'}),
        e({'name': 'Lina Aït Saïd', 'role': 'Cheffe de projet, Sahel Logistique', 'phone': '+213 661 22 33 44', 'email': 'l.aitsaid@sahel.dz'}),
      ],
      Sec.training: [
        e({'year': '2023', 'title': 'Certification Google Associate Android Developer'}),
        e({'year': '2021', 'title': 'Formation Scrum Master, 3 jours'}),
      ],
      Sec.interests: [s('Randonnée en Kabylie'), s('Photographie'), s('Échecs'), s('Bénévolat associatif')],
    });
  }
}

/// Un CV enregistré dans « Mes CV ».
class SavedCv {
  SavedCv({String? id, required this.name, required this.templateId, required this.data, this.color, DateTime? updatedAt})
      : id = id ?? newId(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  String templateId;
  CvData data;

  /// Couleur choisie (ARGB). null = couleur d'origine du modèle.
  int? color;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'templateId': templateId,
        'color': color,
        'updatedAt': updatedAt.toIso8601String(),
        'data': data.toJson(),
      };

  factory SavedCv.fromJson(Map<String, dynamic> j) => SavedCv(
        id: j['id'] as String?,
        name: (j['name'] as String?) ?? 'Mon CV',
        templateId: (j['templateId'] as String?) ?? 'ardoise',
        color: (j['color'] as num?)?.toInt(),
        updatedAt: DateTime.tryParse('${j['updatedAt']}') ?? DateTime.now(),
        data: CvData.fromJson(Map<String, dynamic>.from(j['data'] as Map)),
      );
}

String mention(int v) => v >= 85
    ? 'Expert'
    : v >= 65
        ? 'Avancé'
        : v >= 40
            ? 'Intermédiaire'
            : 'Débutant';
