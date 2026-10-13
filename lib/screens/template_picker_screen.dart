import 'package:flutter/material.dart';

import '../models/cv_data.dart';
import '../templates/template_def.dart';
import '../theme.dart';
import '../widgets/cv_thumbnail.dart';

/// Choix du modèle. Renvoie l'id du modèle choisi (ou null).
class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key, this.currentId, this.title = 'Choisir un modèle'});

  final String? currentId;
  final String title;

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

enum _Filter { all, photo, canada }

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  static final _sample = CvData.sample();
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final list = templates.where((t) => switch (_filter) {
          _Filter.all => true,
          _Filter.photo => t.photo,
          _Filter.canada => t.canadian,
        }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Le formulaire s\'adapte au modèle : compétences en %, avec mention ou en liste. Vos textes sont gardés si vous changez de modèle.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  for (final (f, label) in const [(_Filter.all, 'Tous'), (_Filter.photo, 'Avec photo'), (_Filter.canada, 'CV canadien')])
                    ChoiceChip(
                      label: Text(label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                ]),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: 0.53,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _TemplateCard(
                  template: list[i],
                  sample: _sample,
                  selected: list[i].id == widget.currentId,
                  onTap: () => Navigator.pop(context, list[i].id),
                ),
                childCount: list.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.sample, required this.selected, required this.onTap});

  final CvTemplate template;
  final CvData sample;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = template;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.gold : Colors.transparent, width: 2.5),
          ),
          child: CvThumbnail(cacheKey: 'tpl-${t.id}', template: t, data: sample),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(t.name, style: Theme.of(context).textTheme.titleMedium)),
          if (selected) const Icon(Icons.check_circle, color: AppColors.gold, size: 18),
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 4, runSpacing: 4, children: [
          if (t.canadian) const _Tag('CV canadien', color: AppColors.danger),
          _Tag(t.photo ? 'Photo' : 'Sans photo'),
          _Tag(switch (t.skillMode) {
            SkillMode.list => 'Liste',
            SkillMode.percent => '%',
            SkillMode.mention => 'Mention',
          }),
        ]),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.color = AppColors.muted});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, color: color)),
      );
}
