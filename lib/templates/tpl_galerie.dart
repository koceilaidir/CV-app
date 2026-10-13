import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';
import 'cv_fonts.dart';
import 'pdf_kit.dart';

/// Galerie : photo carrée et nom en capitales, puis deux colonnes séparées par un filet vertical.
List<pw.Page> buildGalerie(CvData d, CvFonts f, PdfColor a) {
  const bg = PdfColor.fromInt(0xFFF3F3F2);
  final ink = tint(a, 0.08);
  final body = tint(a, 0.12);
  final rule = tint(a, 0.35);

  pw.TextStyle s(pw.Font font, double size, PdfColor c, {double ls = 0}) =>
      pw.TextStyle(font: font, fontSize: size, color: c, letterSpacing: ls, lineSpacing: 1.6);

  pw.Widget head(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(t.toUpperCase(), style: s(f.archivoBold, 12.5, a)),
          pw.SizedBox(height: 8),
          hRule(rule, h: 0.8),
        ]),
      );

  final ct = contacts(d, const ['phone', 'email', 'website']);
  final header = pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
    photo(d, 150, 150, circle: false),
    pw.SizedBox(width: 40),
    pw.Expanded(
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(d.fullName.toUpperCase(), style: s(f.archivoBold, 29, a, ls: 0.4)),
        pw.SizedBox(height: 6),
        pw.Text(d['title'].toUpperCase(), style: s(f.archivo, 12.5, body, ls: 2.6)),
        pw.SizedBox(height: 14),
        for (final c in ct)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(children: [
              iconDot(c.key, a, bg, 15),
              pw.SizedBox(width: 9),
              pw.Expanded(child: pw.Text(c.value, style: s(f.archivo, 9.6, body))),
            ]),
          ),
      ]),
    ),
  ]);

  final left = <pw.Widget>[];
  if (d['summary'].isNotEmpty) {
    left
      ..add(head('Profil'))
      ..add(pw.Text(d['summary'], style: s(f.archivoItalic, 9.4, body)))
      ..add(pw.SizedBox(height: 22));
  }
  final sk = d.items(Sec.skills);
  if (sk.isNotEmpty) {
    left
      ..add(head('Compétences'))
      ..add(bullets([for (final x in sk) x['name']], s(f.archivo, 9.4, body), dot: body))
      ..add(pw.SizedBox(height: 22));
  }
  final ach = d.items(Sec.achievements);
  if (ach.isNotEmpty) {
    left
      ..add(head('Réalisations'))
      ..add(bullets([for (final x in ach) x['text']], s(f.archivo, 9.4, body), dot: body));
  }

  final right = <pw.Widget>[];
  final edu = d.items(Sec.education);
  if (edu.isNotEmpty) {
    right.add(head('Formation'));
    for (final e in edu) {
      right.add(pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(e['school'].isNotEmpty ? e['school'] : e['degree'], style: s(f.archivoBold, 10.2, ink)),
        pw.Text(joinNonEmpty([if (e['school'].isNotEmpty) e['degree'], e['end']], ', '), style: s(f.archivoItalic, 9.4, body)),
        pw.SizedBox(height: 3),
        bullets([
          if (e['start'].isNotEmpty || e['end'].isNotEmpty) 'De ${joinNonEmpty([e['start'], e['end']], ' à ')}',
          if (e['place'].isNotEmpty) e['place'],
          if (e['details'].isNotEmpty) e['details'],
        ], s(f.archivo, 9.4, body), dot: body),
        pw.SizedBox(height: 12),
      ]));
    }
    right.add(pw.SizedBox(height: 10));
  }
  final ex = d.items(Sec.experiences);
  if (ex.isNotEmpty) {
    right.add(head('Expérience'));
    for (final x in ex) {
      right.add(pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(x['role'], style: s(f.archivoBold, 10.2, ink)),
        pw.Text(joinNonEmpty([x['company'], period(x['start'], x['end'])], ', '), style: s(f.archivoItalic, 9.4, body)),
        pw.SizedBox(height: 3),
        bullets(expLines(x), s(f.archivo, 9.4, body), dot: body),
        pw.SizedBox(height: 12),
      ]));
    }
  }

  // Chaque bloc de droite porte un filet à gauche : posés bout à bout, ils forment une ligne continue.
  final rightRuled = [
    for (final w in right)
      pw.Container(
        margin: const pw.EdgeInsets.only(left: 22),
        padding: const pw.EdgeInsets.only(left: 26),
        decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: rule, width: 0.8))),
        child: w,
      ),
  ];

  return [
    pw.MultiPage(
      maxPages: 6,
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 52, 48, 40),
        theme: pw.ThemeData.withFont(base: f.archivo, bold: f.archivoBold, italic: f.archivoItalic),
        buildBackground: (ctx) => fullBackground(pw.Container(color: bg)),
      ),
      build: (ctx) => [
        header,
        pw.SizedBox(height: 34),
        pw.Partitions(children: [
          pw.Partition(width: 140, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: left)),
          pw.Partition(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: rightRuled)),
        ]),
      ],
    ),
  ];
}
