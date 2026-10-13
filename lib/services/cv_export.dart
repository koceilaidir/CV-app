import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/cv_data.dart';
import '../templates/cv_fonts.dart';
import '../templates/template_def.dart';

enum ExportFormat { pdf, jpg }

/// Génération des fichiers et des aperçus à partir des modèles PDF.
class CvExport {
  static Future<Uint8List> pdf(CvTemplate t, CvData d, {int? color}) async {
    final fonts = await CvFonts.load();
    return t.buildPdf(d, fonts, color: color);
  }

  /// Pages du PDF en images, pour l'aperçu à l'écran.
  static Future<List<ui.Image>> previewImages(Uint8List pdfBytes, {double dpi = 110}) async {
    final out = <ui.Image>[];
    await for (final page in Printing.raster(pdfBytes, dpi: dpi)) {
      out.add(await page.toImage());
    }
    return out;
  }

  /// Toutes les pages empilées dans une seule image JPG.
  static Future<Uint8List> jpg(Uint8List pdfBytes, {double dpi = 200}) async {
    final pages = <img.Image>[];
    await for (final page in Printing.raster(pdfBytes, dpi: dpi)) {
      pages.add(img.Image.fromBytes(
        width: page.width,
        height: page.height,
        bytes: page.pixels.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      ));
    }
    final width = pages.first.width;
    final height = pages.fold<int>(0, (h, p) => h + p.height);
    final sheet = img.Image(width: width, height: height);
    img.fill(sheet, color: img.ColorRgb8(255, 255, 255));
    var y = 0;
    for (final p in pages) {
      img.compositeImage(sheet, p, dstY: y);
      y += p.height;
    }
    return Uint8List.fromList(img.encodeJpg(sheet, quality: 92));
  }

  static String fileName(CvData d, CvTemplate t, ExportFormat f) {
    final base = 'cv ${d.fullName} ${t.id}'
        .toLowerCase()
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return base.isEmpty ? 'cv' : base;
  }

  static Future<Uint8List> build(ExportFormat f, CvTemplate t, CvData d, {int? color}) async {
    final bytes = await pdf(t, d, color: color);
    return f == ExportFormat.pdf ? bytes : jpg(bytes);
  }

  /// Enregistre le fichier sur le téléphone (dossier Téléchargements sur Android,
  /// dossier Documents de l'app sur iOS, visible dans l'app Fichiers).
  static Future<String> save(Uint8List bytes, String name, ExportFormat f) {
    return FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: f == ExportFormat.pdf ? 'pdf' : 'jpg',
      mimeType: f == ExportFormat.pdf ? MimeType.pdf : MimeType.jpeg,
    );
  }

  /// Ouvre la feuille de partage (WhatsApp, mail, Drive…).
  static Future<void> share(Uint8List bytes, String name, ExportFormat f) async {
    if (f == ExportFormat.pdf) {
      await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
    } else {
      await Share.shareXFiles([XFile.fromData(bytes, mimeType: 'image/jpeg', name: '$name.jpg')]);
    }
  }
}
