import 'package:flutter/material.dart';

import '../models/cv_data.dart';
import '../services/storage.dart';
import '../templates/template_def.dart';
import '../theme.dart';
import '../widgets/cv_thumbnail.dart';
import 'editor_screen.dart';
import 'template_picker_screen.dart';

/// « Mes CV » : la liste des CV enregistrés sur le téléphone.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SavedCv>? _cvs;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await CvStorage.instance.loadAll();
    if (mounted) setState(() => _cvs = list);
  }

  Future<void> _create() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const TemplatePickerScreen(title: 'Nouveau CV : choisir un modèle')),
    );
    if (id == null || !mounted) return;
    final n = (_cvs?.length ?? 0) + 1;
    final cv = SavedCv(name: n == 1 ? 'Mon CV' : 'Mon CV $n', templateId: id, data: CvData.empty());
    await CvStorage.instance.save(cv);
    await _open(cv);
  }

  Future<void> _open(SavedCv cv) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(cv: cv)));
    _reload();
  }

  Future<void> _rename(SavedCv cv) async {
    final name = await askName(context, cv.name);
    if (name == null) return;
    cv.name = name;
    await CvStorage.instance.save(cv);
    _reload();
  }

  Future<void> _duplicate(SavedCv cv) async {
    final copy = SavedCv(name: '${cv.name} (copie)', templateId: cv.templateId, data: cv.data.copy(), color: cv.color);
    await CvStorage.instance.save(copy);
    _reload();
  }

  Future<void> _delete(SavedCv cv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Supprimer ce CV ?'),
        content: Text('« ${cv.name} » sera supprimé du téléphone. Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await CvStorage.instance.delete(cv.id);
    CvThumbnail.evict(cv.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final cvs = _cvs;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/icon/icon_rounded.png', width: 32, height: 32),
          ),
          const SizedBox(width: 10),
          const Text('CV Minerva'),
        ]),
      ),
      floatingActionButton: cvs == null || cvs.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau CV'),
            ),
      body: cvs == null
          ? const Center(child: CircularProgressIndicator())
          : cvs.isEmpty
              ? _Empty(onCreate: _create)
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.55,
                    ),
                    itemCount: cvs.length,
                    itemBuilder: (context, i) {
                      final cv = cvs[i];
                      final t = templateById(cv.templateId);
                      return InkWell(
                        onTap: () => _open(cv),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          CvThumbnail(
                            cacheKey: '${cv.id}-${cv.updatedAt.millisecondsSinceEpoch}',
                            template: t,
                            data: cv.data,
                            color: cv.color,
                          ),
                          const SizedBox(height: 6),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(cv.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                                Text('${t.name} · ${_date(cv.updatedAt)}', style: Theme.of(context).textTheme.bodySmall),
                              ]),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Options',
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (v) => switch (v) {
                                'rename' => _rename(cv),
                                'dup' => _duplicate(cv),
                                _ => _delete(cv),
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'rename', child: Text('Renommer')),
                                PopupMenuItem(value: 'dup', child: Text('Dupliquer')),
                                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                              ],
                            ),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }

  static String _date(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return "aujourd'hui ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    }
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset('assets/icon/icon_rounded.png', width: 112, height: 112),
          ),
          const SizedBox(height: 24),
          Text('Aucun CV pour le moment', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Choisissez un modèle, remplissez les champs, puis générez votre CV en PDF ou en JPG. Vos CV restent enregistrés sur ce téléphone.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Créer mon premier CV')),
        ]),
      ),
    );
  }
}

/// Boîte de dialogue pour nommer un CV.
Future<String?> askName(BuildContext context, String current) {
  final ctrl = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Nom du CV'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Ex. CV développeur 2026'),
        onSubmitted: (v) => Navigator.pop(c, v.trim().isEmpty ? null : v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(c, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
          child: const Text('Enregistrer'),
        ),
      ],
    ),
  );
}
