import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';

/// Outils partagés par les modèles PDF.
/// Les tailles sont en points (A4 = 595 × 842 pt).

const white = PdfColors.white;

/// Mélange une couleur avec du blanc (t = 0 : couleur, t = 1 : blanc).
PdfColor tint(PdfColor c, double t) =>
    PdfColor(c.red + (1 - c.red) * t, c.green + (1 - c.green) * t, c.blue + (1 - c.blue) * t);

/// Assombrit une couleur (t = 0 : couleur, t = 1 : noir).
PdfColor shade(PdfColor c, double t) => PdfColor(c.red * (1 - t), c.green * (1 - t), c.blue * (1 - t));

String hex(PdfColor c) {
  String h(double v) => (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${h(c.red)}${h(c.green)}${h(c.blue)}';
}

List<String> lines(String s) => s.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

String period(String a, String b, [String sep = ' – ']) => [a, b].where((s) => s.isNotEmpty).join(sep);

String joinNonEmpty(List<String> parts, String sep) => parts.where((s) => s.isNotEmpty).join(sep);

/// Description + points clés d'une expérience, en une seule liste de lignes.
List<String> expLines(Entry x) => [if (x['desc'].isNotEmpty) x['desc'], ...lines(x['bullets'])];

const _icons = {
  'phone': '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2"/>',
  'email': '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/>',
  'address': '<path d="M12 21s-7-6.2-7-11a7 7 0 0 1 14 0c0 4.8-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/>',
  'website': '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
  'linkedin': '<rect x="3" y="3" width="18" height="18" rx="3"/><path d="M8 10v7M8 7v0.01M12 17v-4a2 2 0 0 1 4 0v4M12 10v7"/>',
};

const contactLabels = {
  'phone': 'Téléphone',
  'email': 'Email',
  'address': 'Adresse',
  'website': 'Site web',
  'linkedin': 'LinkedIn',
};

pw.Widget icon(String key, PdfColor color, double size) => pw.SvgImage(
      svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="${hex(color)}" '
          'stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">${_icons[key]}</svg>',
      width: size,
      height: size,
    );

/// Icône dans une pastille ronde.
pw.Widget iconDot(String key, PdfColor bg, PdfColor fg, double size) => pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(color: bg, shape: pw.BoxShape.circle),
      alignment: pw.Alignment.center,
      child: icon(key, fg, size * 0.55),
    );

/// Coordonnées remplies, dans l'ordre du modèle.
List<MapEntry<String, String>> contacts(CvData d, List<String> keys) =>
    [for (final k in keys) if (d[k].isNotEmpty) MapEntry(k, d[k])];

/// Photo (ou silhouette grise si aucune photo).
pw.Widget photo(CvData d, double w, double h, {bool circle = true, double radius = 0, PdfColor? border, double borderWidth = 0}) {
  final pw.Widget img = d.photo != null
      ? pw.Image(pw.MemoryImage(d.photo!), width: w, height: h, fit: pw.BoxFit.cover)
      : pw.Container(
          width: w,
          height: h,
          color: const PdfColor.fromInt(0xFFC9CDD6),
          child: pw.SvgImage(
            svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"><rect width="200" height="200" fill="#C9CDD6"/>'
                '<circle cx="100" cy="80" r="38" fill="#9AA1AF"/><path d="M28 200c6-44 36-66 72-66s66 22 72 66z" fill="#9AA1AF"/></svg>',
            width: w,
            height: h,
            fit: pw.BoxFit.cover,
          ),
        );
  final clipped = circle
      ? pw.ClipOval(child: img)
      : pw.ClipRRect(horizontalRadius: radius, verticalRadius: radius, child: img);
  if (border == null || borderWidth == 0) return pw.SizedBox(width: w, height: h, child: clipped);
  return pw.Container(
    width: w + borderWidth * 2,
    height: h + borderWidth * 2,
    padding: pw.EdgeInsets.all(borderWidth),
    decoration: pw.BoxDecoration(color: border, shape: circle ? pw.BoxShape.circle : pw.BoxShape.rectangle),
    child: clipped,
  );
}

/// Liste à puces.
pw.Widget bullets(List<String> items, pw.TextStyle style,
    {PdfColor? dot, double indent = 10, double gap = 1.5, double dotSize = 2.6}) {
  final c = dot ?? style.color ?? PdfColors.black;
  final size = style.fontSize ?? 9;
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final t in items)
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: gap),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(
              width: indent,
              padding: pw.EdgeInsets.only(top: size * 0.5),
              child: pw.Container(width: dotSize, height: dotSize, decoration: pw.BoxDecoration(color: c, shape: pw.BoxShape.circle)),
            ),
            pw.Expanded(child: pw.Text(t, style: style)),
          ]),
        ),
    ],
  );
}

/// Barre de niveau en pourcentage.
pw.Widget bar(int value, PdfColor bg, PdfColor fg, {double height = 3}) {
  final v = value.clamp(0, 100);
  return pw.Container(
    height: height,
    color: bg,
    child: pw.Row(children: [
      if (v > 0) pw.Expanded(flex: v, child: pw.Container(height: height, color: fg)),
      if (v < 100) pw.Expanded(flex: 100 - v, child: pw.SizedBox(height: height)),
    ]),
  );
}

/// Élément de frise verticale : une pastille et un trait continu à gauche.
/// Les éléments posés à la suite forment une frise sans coupure.
pw.Widget timelineItem({
  required pw.Widget child,
  required PdfColor line,
  required pw.Widget dot,
  double dotSize = 8,
  double dotTop = 2,
  double lineWidth = 1,
  double gapLeft = 14,
  double bottom = 12,
  bool last = false,
}) {
  return pw.Stack(overflow: pw.Overflow.visible, children: [
    pw.Container(
      margin: pw.EdgeInsets.only(left: dotSize / 2 - lineWidth / 2),
      padding: pw.EdgeInsets.only(left: gapLeft + dotSize / 2, bottom: bottom),
      decoration: pw.BoxDecoration(
        border: last ? null : pw.Border(left: pw.BorderSide(color: line, width: lineWidth)),
      ),
      child: child,
    ),
    pw.Positioned(left: 0, top: dotTop, child: dot),
  ]);
}

pw.Widget ringDot(double size, PdfColor stroke, PdfColor fill, {double width = 1}) => pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: fill,
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: stroke, width: width),
      ),
    );

pw.Widget hRule(PdfColor c, {double h = 0.8, double? width}) => pw.Container(height: h, width: width, color: c);

/// Ajoute une marge horizontale à chaque enfant d'une colonne (utile dans les Partitions).
List<pw.Widget> padAll(List<pw.Widget> children, pw.EdgeInsets p) =>
    [for (final c in children) pw.Padding(padding: p, child: c)];

/// Fond de page pleine taille.
pw.Widget fullBackground(pw.Widget child) => pw.FullPage(ignoreMargins: true, child: child);
