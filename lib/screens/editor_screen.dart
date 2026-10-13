import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/cv_data.dart';
import '../services/cv_export.dart';
import '../services/storage.dart';
import '../templates/template_def.dart';
import '../theme.dart';
import '../widgets/cv_form.dart';
import 'home_screen.dart' show askName;
import 'template_picker_screen.dart';

/// Éditeur d'un CV : onglet « Remplir » (formulaire du modèle) et onglet « Aperçu » (rendu A4).
/// Tout est enregistré automatiquement sur le téléphone.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.cv});
  final SavedCv cv;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  SavedCv get cv => widget.cv;
  CvTemplate get tpl => templateById(cv.templateId);

  int _formVersion = 0;
  Timer? _saveTimer;
  Timer? _previewTimer;
  bool _dirty = false;

  List<ui.Image> _pages = [];
  bool _rendering = false;
  String? _renderError;
  int _renderToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _renderPreview());
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      CvStorage.instance.save(cv);
    }
    _tabs.dispose();
    super.dispose();
  }

  void _changed({bool structure = false}) {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _saveNow);
    _previewTimer?.cancel();
    _previewTimer = Timer(Duration(milliseconds: structure ? 50 : 450), _renderPreview);
  }

  Future<void> _saveNow() async {
    _dirty = false;
    await CvStorage.instance.save(cv);
  }

  Future<void> _renderPreview() async {
    final token = ++_renderToken;
    setState(() => _rendering = true);
    try {
      final bytes = await CvExport.pdf(tpl, cv.data, color: cv.color);
      final pages = await CvExport.previewImages(bytes, dpi: 110);
      if (!mounted || token != _renderToken) return;
      setState(() {
        _pages = pages;
        _renderError = null;
        _rendering = false;
      });
    } catch (e) {
      if (!mounted || token != _renderToken) return;
      setState(() {
        _renderError = "L'aperçu n'a pas pu être généré.";
        _rendering = false;
      });
    }
  }

  // ---------- Actions de la barre ----------

  Future<void> _rename() async {
    final name = await askName(context, cv.name);
    if (name == null) return;
    setState(() => cv.name = name);
    _changed();
  }

  Future<void> _changeTemplate() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => TemplatePickerScreen(currentId: cv.templateId, title: 'Changer de modèle')),
    );
    if (id == null || id == cv.templateId) return;
    setState(() {
      cv.templateId = id;
      _formVersion++;
    });
    _changed(structure: true);
  }

  Future<void> _fillSample() async {
    final ok = await _confirm(
      "Remplir avec l'exemple ?",
      "Les champs seront remplacés par un CV d'exemple que vous pourrez modifier. Votre photo est conservée.",
      'Remplir',
    );
    if (!ok) return;
    final photo = cv.data.photo;
    setState(() {
      cv.data = CvData.sample()..photo = photo;
      _formVersion++;
    });
    _changed(structure: true);
  }

  Future<void> _clearAll() async {
    final ok = await _confirm('Tout vider ?', 'Tous les champs de ce CV seront effacés, photo comprise.', 'Vider', danger: true);
    if (!ok) return;
    setState(() {
      cv.data = CvData.empty();
      _formVersion++;
    });
    _changed(structure: true);
  }

  Future<bool> _confirm(String title, String body, String action, {bool danger = false}) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(
            style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return r == true;
  }

  void _pickColor() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Couleur du CV', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Appliquée aux titres, filets, icônes et bandeaux du modèle.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ColorPalette(
              templateColor: tpl.defaultColor,
              selected: cv.color,
              onSelected: (v) {
                Navigator.pop(c);
                _setColor(v);
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _setColor(int? v) {
    setState(() => cv.color = v);
    _changed(structure: true);
  }

  void _generate() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _GenerateSheet(cv: cv, template: tpl),
    );
  }

  // ---------- Construction ----------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _dirty) {
          _saveTimer?.cancel();
          CvStorage.instance.save(cv);
          _dirty = false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            onTap: _rename,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cv.name, overflow: TextOverflow.ellipsis),
              Text('Modèle ${tpl.name} · touchez pour renommer', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          actions: [
            IconButton(tooltip: 'Couleur', onPressed: _pickColor, icon: Icon(Icons.palette_outlined, color: Color(cv.color ?? tpl.defaultColor))),
            IconButton(tooltip: 'Changer de modèle', onPressed: _changeTemplate, icon: const Icon(Icons.view_quilt_outlined)),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'sample' ? _fillSample() : _clearAll(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'sample', child: Text("Remplir avec l'exemple")),
                PopupMenuItem(value: 'clear', child: Text('Tout vider')),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            labelColor: AppColors.navy,
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            tabs: const [Tab(text: 'Remplir'), Tab(text: 'Aperçu')],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            CvForm(
              key: ValueKey('form-${cv.templateId}-$_formVersion'),
              template: tpl,
              data: cv.data,
              version: _formVersion,
              onChanged: _changed,
            ),
            _preview(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.line))),
            child: FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Générer le CV'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    return Container(
      color: const Color(0xFFD9DEE8),
      child: Column(children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: ColorPalette(templateColor: tpl.defaultColor, selected: cv.color, onSelected: _setColor, compact: true),
        ),
        SizedBox(height: 3, child: _rendering ? const LinearProgressIndicator(minHeight: 3) : null),
        Expanded(
          child: _renderError != null && _pages.isEmpty
              ? Center(child: Text(_renderError!, style: Theme.of(context).textTheme.bodySmall))
              : _pages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _pages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (_pages.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('Page ${i + 1} sur ${_pages.length}', style: Theme.of(context).textTheme.bodySmall),
                          ),
                        AspectRatio(
                          aspectRatio: 210 / 297,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
                            ),
                            child: RawImage(image: _pages[i], fit: BoxFit.contain),
                          ),
                        ),
                      ]),
                    ),
        ),
      ]),
    );
  }
}

/// Pastilles de couleur : la couleur d'origine du modèle puis la palette.
class ColorPalette extends StatelessWidget {
  const ColorPalette({super.key, required this.templateColor, required this.selected, required this.onSelected, this.compact = false});

  final int templateColor;
  final int? selected;
  final ValueChanged<int?> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 40.0;
    final swatches = <(int?, int)>[
      (null, templateColor),
      for (final c in cvPalette)
        if (c != templateColor) (c, c),
    ];
    final items = [
      for (final (value, color) in swatches)
        Semantics(
          label: value == null ? "Couleur d'origine du modèle" : 'Couleur',
          selected: selected == value,
          button: true,
          child: InkResponse(
            onTap: () => onSelected(value),
            radius: size / 2 + 4,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Color(color),
                shape: BoxShape.circle,
                border: Border.all(color: selected == value ? AppColors.gold : Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 3)],
              ),
              child: value == null
                  ? Icon(Icons.auto_awesome, size: size * 0.42, color: Colors.white)
                  : (selected == value ? Icon(Icons.check, size: size * 0.5, color: Colors.white) : null),
            ),
          ),
        ),
    ];
    if (compact) {
      return SizedBox(
        height: size + 4,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => Center(child: items[i]),
        ),
      );
    }
    return Wrap(spacing: 12, runSpacing: 12, children: items);
  }
}

/// Feuille « Générer » : format puis enregistrer ou partager.
class _GenerateSheet extends StatefulWidget {
  const _GenerateSheet({required this.cv, required this.template});
  final SavedCv cv;
  final CvTemplate template;

  @override
  State<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<_GenerateSheet> {
  ExportFormat _format = ExportFormat.pdf;
  final Map<ExportFormat, Uint8List> _cache = {};
  bool _busy = false;

  Future<Uint8List> _bytes() async =>
      _cache[_format] ??= await CvExport.build(_format, widget.template, widget.cv.data, color: widget.cv.color);

  Future<void> _run(bool share) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final name = CvExport.fileName(widget.cv.data, widget.template, _format);
    try {
      final bytes = await _bytes();
      if (share) {
        await CvExport.share(bytes, name, _format);
      } else {
        await CvExport.save(bytes, name, _format);
        messenger.showSnackBar(SnackBar(content: Text('Enregistré : $name.${_format == ExportFormat.pdf ? 'pdf' : 'jpg'}')));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text("La génération a échoué. Réessayez, ou retirez la photo si elle est très lourde.")));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Générer le CV', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Modèle ${widget.template.name}, format A4.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          SegmentedButton<ExportFormat>(
            segments: const [
              ButtonSegment(value: ExportFormat.pdf, label: Text('PDF'), icon: Icon(Icons.picture_as_pdf_outlined)),
              ButtonSegment(value: ExportFormat.jpg, label: Text('JPG'), icon: Icon(Icons.image_outlined)),
            ],
            selected: {_format},
            onSelectionChanged: _busy ? null : (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _format == ExportFormat.pdf
                ? 'Pour envoyer une candidature ou imprimer.'
                : 'Image haute définition, pratique pour WhatsApp ou les réseaux. Plusieurs pages sont empilées.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          if (_busy)
            const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: CircularProgressIndicator()))
          else ...[
            FilledButton.icon(
              onPressed: () => _run(false),
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Enregistrer sur le téléphone'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _run(true),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Partager'),
            ),
          ],
        ]),
      ),
    );
  }
}
