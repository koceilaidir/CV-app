import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/cv_data.dart';
import '../templates/template_def.dart';
import '../theme.dart';

/// Champ d'un élément de liste : clé, libellé, type.
class _F {
  const _F(this.key, this.label, {this.multi = false, this.half = false, this.hint, this.kb});
  final String key;
  final String label;
  final bool multi;
  final bool half;
  final String? hint;
  final TextInputType? kb;
}

const _itemFields = <String, List<_F>>{
  Sec.experiences: [
    _F('role', 'Poste'),
    _F('company', 'Entreprise'),
    _F('place', 'Lieu'),
    _F('start', 'Début', half: true, hint: '2022'),
    _F('end', 'Fin', half: true, hint: 'Présent'),
    _F('desc', 'Description', multi: true),
    _F('bullets', 'Points clés', multi: true, hint: 'Un point par ligne'),
  ],
  Sec.education: [
    _F('degree', 'Diplôme'),
    _F('school', 'Établissement'),
    _F('place', 'Lieu'),
    _F('start', 'Début', half: true),
    _F('end', 'Fin', half: true),
    _F('details', 'Détails', hint: 'Mention, spécialité…'),
  ],
  Sec.projects: [_F('name', 'Nom du projet'), _F('desc', 'Description', multi: true)],
  Sec.references: [
    _F('name', 'Nom'),
    _F('role', 'Poste, entreprise'),
    _F('phone', 'Téléphone', half: true, kb: TextInputType.phone),
    _F('email', 'Email', half: true, kb: TextInputType.emailAddress),
  ],
  Sec.training: [_F('year', 'Année', half: true), _F('title', 'Intitulé')],
};

const _itemName = <String, String>{
  Sec.experiences: 'Expérience',
  Sec.education: 'Formation',
  Sec.projects: 'Projet',
  Sec.references: 'Référence',
  Sec.training: 'Formation continue',
  Sec.skills: 'Compétence',
  Sec.languages: 'Langue',
  Sec.tools: 'Outil ou logiciel',
  Sec.achievements: 'Réalisation',
  Sec.interests: "Centre d'intérêt",
};

const _contactFields = <String, (String, TextInputType)>{
  'phone': ('Téléphone', TextInputType.phone),
  'email': ('Email', TextInputType.emailAddress),
  'address': ('Adresse (ville)', TextInputType.streetAddress),
  'website': ('Site web', TextInputType.url),
  'linkedin': ('LinkedIn', TextInputType.url),
};

const _languageLevels = ['Langue maternelle', 'Courant', 'Professionnel', 'Intermédiaire', 'Notions'];
const _mentions = [('Débutant', 30), ('Intermédiaire', 55), ('Avancé', 75), ('Expert', 95)];

/// Formulaire du CV : n'affiche que les sections du modèle choisi.
class CvForm extends StatefulWidget {
  const CvForm({super.key, required this.template, required this.data, required this.version, required this.onChanged});

  final CvTemplate template;
  final CvData data;

  /// Change quand les données sont remplacées en bloc (exemple, vider) pour recréer les champs.
  final int version;

  /// Appelé à chaque modification. [structure] = true si des éléments ont été ajoutés ou retirés.
  final void Function({bool structure}) onChanged;

  @override
  State<CvForm> createState() => _CvFormState();
}

class _CvFormState extends State<CvForm> {
  CvData get d => widget.data;
  CvTemplate get t => widget.template;

  void _touch() => widget.onChanged(structure: false);
  void _restructure() {
    setState(() {});
    widget.onChanged(structure: true);
  }

  Widget _field({
    required String id,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool multi = false,
    String? hint,
    TextInputType? kb,
  }) {
    return TextFormField(
      key: ValueKey('${widget.version}-$id'),
      initialValue: value,
      onChanged: onChanged,
      minLines: multi ? 2 : 1,
      maxLines: multi ? 6 : 1,
      keyboardType: multi ? TextInputType.multiline : kb,
      textCapitalization: kb == null || kb == TextInputType.text ? TextCapitalization.sentences : TextCapitalization.none,
      decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: multi),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        for (var i = 0; i < t.sections.length; i++) _section(t.sections[i], initiallyExpanded: i < 2),
      ],
    );
  }

  Widget _section(String k, {required bool initiallyExpanded}) {
    final isList = Sec.lists.contains(k);
    final count = isList ? d.items(k).length : null;
    return Card(
      key: ValueKey('${t.id}-$k'),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.line)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          title: Text(t.label(k), style: Theme.of(context).textTheme.titleMedium),
          subtitle: count == null ? null : Text(count == 0 ? 'Vide' : '$count élément${count > 1 ? 's' : ''}', style: Theme.of(context).textTheme.bodySmall),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: _body(k),
        ),
      ),
    );
  }

  List<Widget> _body(String k) {
    const gap = SizedBox(height: 10);
    switch (k) {
      case Sec.identity:
        return [
          Row(children: [
            Expanded(child: _field(id: 'firstName', label: 'Prénom', value: d['firstName'], onChanged: (v) => _set('firstName', v))),
            const SizedBox(width: 10),
            Expanded(child: _field(id: 'lastName', label: 'Nom', value: d['lastName'], onChanged: (v) => _set('lastName', v))),
          ]),
          gap,
          _field(id: 'title', label: 'Titre du poste', value: d['title'], hint: 'Ex. Comptable, Chauffeur poids lourd…', onChanged: (v) => _set('title', v)),
          gap,
          if (t.photo) _photoRow() else const _Hint('Format canadien : pas de photo, ni âge, ni situation familiale.'),
        ];
      case Sec.contact:
        return [
          for (final c in t.contact) ...[
            _field(id: c, label: _contactFields[c]!.$1, kb: _contactFields[c]!.$2, value: d[c], onChanged: (v) => _set(c, v)),
            gap,
          ],
        ];
      case Sec.summary:
        return [
          _field(id: 'summary', label: t.label(k), multi: true, value: d['summary'], hint: 'Deux ou trois phrases sur votre profil', onChanged: (v) => _set('summary', v)),
        ];
      case Sec.skills:
        return [
          _Hint(switch (t.skillMode) {
            SkillMode.percent => 'Réglez le niveau en pourcentage : il s\'affiche en barre sur le CV.',
            SkillMode.mention => 'Choisissez une mention : elle s\'affiche sous la compétence.',
            SkillMode.list => 'Ce modèle affiche les compétences en simple liste.',
          }),
          gap,
          ..._listItems(k, (e, i) => _skillRow(e)),
        ];
      case Sec.languages:
        return _listItems(k, (e, i) => Row(children: [
              Expanded(child: _field(id: '${e.id}-name', label: 'Langue', value: e['name'], onChanged: (v) => _setE(e, 'name', v))),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('${widget.version}-${e.id}-lvl'),
                  value: _languageLevels.contains(e['level']) ? e['level'] : 'Courant',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Niveau'),
                  items: [for (final l in _languageLevels) DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis))],
                  onChanged: (v) => _setE(e, 'level', v ?? 'Courant'),
                ),
              ),
            ]), blank: () => Entry(v: {'name': '', 'level': 'Courant'}));
      case Sec.tools:
      case Sec.achievements:
      case Sec.interests:
        return _listItems(k, (e, i) => _field(id: '${e.id}-text', label: _itemName[k]!, value: e['text'], onChanged: (v) => _setE(e, 'text', v)),
            compact: true);
      default:
        final fields = _itemFields[k]!;
        return _listItems(k, (e, i) {
          final rows = <Widget>[];
          for (var j = 0; j < fields.length; j++) {
            final f = fields[j];
            Widget w(_F f) => _field(
                  id: '${e.id}-${f.key}',
                  label: f.label,
                  hint: f.hint,
                  kb: f.kb,
                  multi: f.multi,
                  value: e[f.key],
                  onChanged: (v) => _setE(e, f.key, v),
                );
            if (f.half && j + 1 < fields.length && fields[j + 1].half) {
              rows.add(Row(children: [Expanded(child: w(f)), const SizedBox(width: 10), Expanded(child: w(fields[j + 1]))]));
              j++;
            } else if (f.half) {
              rows.add(Row(children: [Expanded(child: w(f)), const SizedBox(width: 10), const Spacer()]));
            } else {
              rows.add(w(f));
            }
            rows.add(const SizedBox(height: 10));
          }
          rows.removeLast();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
        });
    }
  }

  void _set(String k, String v) {
    d[k] = v;
    _touch();
  }

  void _setE(Entry e, String k, String v) {
    e[k] = v;
    _touch();
  }

  Widget _skillRow(Entry e) {
    final name = _field(id: '${e.id}-name', label: 'Compétence', value: e['name'], onChanged: (v) => _setE(e, 'name', v));
    switch (t.skillMode) {
      case SkillMode.list:
        return name;
      case SkillMode.percent:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          name,
          Row(children: [
            Expanded(
              child: Slider(
                value: e.level.clamp(0, 100).toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '${e.level} %',
                activeColor: AppColors.gold,
                onChanged: (v) {
                  setState(() => e.level = v.round());
                  _touch();
                },
              ),
            ),
            SizedBox(
              width: 46,
              child: Text('${e.level} %', textAlign: TextAlign.right, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
            ),
          ]),
        ]);
      case SkillMode.mention:
        final current = mention(e.level);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          name,
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final (label, value) in _mentions)
              ChoiceChip(
                label: Text(label),
                selected: current == label,
                onSelected: (_) {
                  setState(() => e.level = value);
                  _touch();
                },
              ),
          ]),
        ]);
    }
  }

  List<Widget> _listItems(String k, Widget Function(Entry e, int i) build, {Entry Function()? blank, bool compact = false}) {
    final list = d.lists[k]!;
    final name = _itemName[k]!;
    return [
      for (var i = 0; i < list.length; i++)
        Container(
          key: ValueKey(list[i].id),
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.fromLTRB(compact ? 10 : 12, compact ? 10 : 6, 6, compact ? 10 : 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: compact
              ? Row(children: [
                  Expanded(child: build(list[i], i)),
                  _iconBtn(Icons.close, 'Supprimer', () => _remove(k, i)),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(
                      child: Text('${name.toUpperCase()} ${i + 1}',
                          style: const TextStyle(fontSize: 11.5, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: AppColors.muted)),
                    ),
                    if (i > 0) _iconBtn(Icons.arrow_upward, 'Monter', () => _moveUp(k, i)),
                    _iconBtn(Icons.close, 'Supprimer', () => _remove(k, i)),
                  ]),
                  Padding(padding: const EdgeInsets.only(right: 6), child: build(list[i], i)),
                ]),
        ),
      OutlinedButton.icon(
        onPressed: () {
          list.add(blank?.call() ?? Entry(level: 70));
          _restructure();
        },
        icon: const Icon(Icons.add, size: 18),
        label: Text('Ajouter : ${name.toLowerCase()}'),
      ),
    ];
  }

  Widget _iconBtn(IconData icon, String tip, VoidCallback onTap) => IconButton(
        tooltip: tip,
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        color: AppColors.muted,
        onPressed: onTap,
        icon: Icon(icon),
      );

  void _moveUp(String k, int i) {
    final l = d.lists[k]!;
    final e = l.removeAt(i);
    l.insert(i - 1, e);
    _restructure();
  }

  void _remove(String k, int i) {
    final l = d.lists[k]!;
    final removed = l.removeAt(i);
    _restructure();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: const Text('Élément supprimé'),
      action: SnackBarAction(
        label: 'Annuler',
        onPressed: () {
          l.insert(i.clamp(0, l.length), removed);
          if (mounted) _restructure();
        },
      ),
    ));
  }

  Widget _photoRow() {
    return Row(children: [
      CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.line,
        backgroundImage: d.photo != null ? MemoryImage(d.photo!) : null,
        child: d.photo == null ? const Icon(Icons.person, color: AppColors.muted, size: 30) : null,
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Wrap(spacing: 8, runSpacing: 6, children: [
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(d.photo == null ? 'Ajouter une photo' : 'Changer'),
          ),
          if (d.photo != null)
            TextButton(
              onPressed: () {
                d.photo = null;
                _restructure();
              },
              child: const Text('Retirer'),
            ),
        ]),
      ),
    ]);
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 700, maxHeight: 700, imageQuality: 85);
      if (file == null) return;
      d.photo = await file.readAsBytes();
      _restructure();
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accès aux photos refusé. Autorisez-le dans les réglages du téléphone.")),
      );
    }
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.bodySmall);
}
