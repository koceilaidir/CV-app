import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/cv_data.dart';
import '../services/cv_export.dart';
import '../templates/template_def.dart';
import '../theme.dart';

/// Miniature de la première page d'un CV, mise en cache par clé.
class CvThumbnail extends StatefulWidget {
  const CvThumbnail({super.key, required this.cacheKey, required this.template, required this.data, this.color});

  final String cacheKey;
  final CvTemplate template;
  final CvData data;
  final int? color;

  static final Map<String, ui.Image> _cache = {};
  static void evict(String prefix) => _cache.removeWhere((k, _) => k.startsWith(prefix));

  @override
  State<CvThumbnail> createState() => _CvThumbnailState();
}

class _CvThumbnailState extends State<CvThumbnail> {
  ui.Image? _img;

  @override
  void initState() {
    super.initState();
    _img = CvThumbnail._cache[widget.cacheKey];
    if (_img == null) _load();
  }

  @override
  void didUpdateWidget(CvThumbnail old) {
    super.didUpdateWidget(old);
    if (old.cacheKey != widget.cacheKey) {
      _img = CvThumbnail._cache[widget.cacheKey];
      if (_img == null) _load();
    }
  }

  Future<void> _load() async {
    try {
      final bytes = await CvExport.pdf(widget.template, widget.data, color: widget.color);
      final pages = await CvExport.previewImages(bytes, dpi: 45);
      if (pages.isEmpty) return;
      CvThumbnail._cache[widget.cacheKey] = pages.first;
      if (mounted) setState(() => _img = pages.first);
    } catch (_) {
      // La miniature reste vide ; l'éditeur affichera l'erreur s'il y en a une.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 210 / 297,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.line),
          boxShadow: const [BoxShadow(color: Color(0x1A17203A), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _img == null
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : RawImage(image: _img, fit: BoxFit.cover, alignment: Alignment.topCenter),
        ),
      ),
    );
  }
}
