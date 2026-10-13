import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';
import 'cv_fonts.dart';
import 'pdf_kit.dart';

/// Toronto : CV canadien moderne, sans photo. Bandeau coloré, compétences clés sur deux colonnes,
/// dates alignées à droite.
List<pw.Page> buildToronto(CvData d, CvFonts f, PdfColor a) {
  const body = PdfColor.fromInt(0xFF33383F);
  const dark = PdfColor.fromInt(0xFF1B1F25);
  const muted = PdfColor.fromInt(0xFF5A6068);
  final onA = tint(a, 0.72);

  pw.TextStyle s(pw.Font font, double size, PdfColor c, {double ls = 0}) =>
      pw.TextStyle(font: font, fontSize: size, color: c, letterSpacing: ls, lineSpacing: 1.6);

  pw.Widget head(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
        child: pw.Row(children: [
          pw.Text(t.toUpperCase(), style: s(f.latoBold, 9.4, a, ls: 1.9)),
          pw.SizedBox(width: 9),
          pw.Expanded(child: hRule(tint(a, 0.55), h: 0.7)),
        ]),
      );
  final txt = s(f.lato, 9, body);

  pw.Widget dated(String title, String date, String sub, List<String> items) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(child: pw.Text(title, style: s(f.latoBold, 9.8, dark))),
            if (date.isNotEmpty) pw.Text(date, style: s(f.latoBold, 8.6, a)),
          ]),
          if (sub.isNotEmpty) pw.Text(sub, style: s(f.latoItalic, 9, muted)),
          if (items.isNotEmpty) pw.SizedBox(height: 3),
          bullets(items, txt, dot: a),
        ]),
      );

  final ct = contacts(d, const ['address', 'phone', 'email', 'linkedin']);
  final band = pw.Container(
    width: PdfPageFormat.a4.width,
    margin: const pw.EdgeInsets.only(bottom: 4),
    color: a,
    padding: const pw.EdgeInsets.fromLTRB(42, 36, 42, 20),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(d.fullName, style: s(f.latoBold, 25, white, ls: 0.4)),
      if (d['title'].isNotEmpty) pw.Text(d['title'].toUpperCase(), style: s(f.lato, 10.5, onA, ls: 1.5)),
      pw.SizedBox(height: 12),
      pw.Wrap(spacing: 16, runSpacing: 4, children: [
        for (final c in ct)
          pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
            icon(c.key, onA, 9),
            pw.SizedBox(width: 4),
            pw.Text(c.value, style: s(f.lato, 8.6, tint(a, 0.9))),
          ]),
      ]),
    ]),
  );

  final out = <pw.Widget>[];
  if (d['summary'].isNotEmpty) {
    out
      ..add(head('Profil professionnel'))
      ..add(pw.Text(d['summary'], style: txt));
  }
  final sk = d.items(Sec.skills);
  if (sk.isNotEmpty) {
    out.add(head('Compétences clés'));
    final names = [for (final x in sk) x['name']];
    final half = (names.length / 2).ceil();
    out.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Expanded(child: bullets(names.sublist(0, half), txt, dot: a)),
      pw.SizedBox(width: 20),
      pw.Expanded(child: bullets(names.sublist(half), txt, dot: a)),
    ]));
  }
  final ex = d.items(Sec.experiences);
  if (ex.isNotEmpty) {
    out.add(head('Expérience professionnelle'));
    for (final x in ex) {
      out.add(dated(x['role'], period(x['start'], x['end']), joinNonEmpty([x['company'], x['place']], ', '), expLines(x)));
    }
  }
  final edu = d.items(Sec.education);
  if (edu.isNotEmpty) {
    out.add(head('Formation'));
    for (final e in edu) {
      out.add(dated(
        e['degree'],
        period(e['start'], e['end']),
        joinNonEmpty([joinNonEmpty([e['school'], e['place']], ', '), e['details']], ' · '),
        const [],
      ));
    }
  }
  final lg = d.items(Sec.languages);
  if (lg.isNotEmpty) {
    out
      ..add(head('Langues'))
      ..add(pw.Wrap(spacing: 22, runSpacing: 4, children: [
        for (final l in lg)
          pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(text: l['name'], style: s(f.latoBold, 9, dark)),
              pw.TextSpan(text: '  ${l['level']}', style: txt),
            ]),
          ),
      ]));
  }
  final ach = d.items(Sec.achievements);
  if (ach.isNotEmpty) {
    out
      ..add(head('Réalisations'))
      ..add(bullets([for (final x in ach) x['text']], txt, dot: a));
  }
  final tr = d.items(Sec.training);
  if (tr.isNotEmpty) {
    out
      ..add(head('Perfectionnement'))
      ..add(bullets([for (final t in tr) joinNonEmpty([t['year'], t['title']], ' : ')], txt, dot: a));
  }

  return [
    pw.MultiPage(
      maxPages: 6,
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(bottom: 36),
        theme: pw.ThemeData.withFont(base: f.lato, bold: f.latoBold, italic: f.latoItalic),
      ),
      header: (ctx) => ctx.pageNumber == 1 ? band : pw.SizedBox(height: 36),
      build: (ctx) => padAll(out, const pw.EdgeInsets.symmetric(horizontal: 42)),
    ),
  ];
}
