import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';
import 'cv_fonts.dart';
import 'pdf_kit.dart';

/// Ingénieur : barre pleine à côté du nom, coordonnées soulignées en haut à droite,
/// expérience et projets à gauche, photo, formation, compétences en % et langues à droite.
List<pw.Page> buildIngenieur(CvData d, CvFonts f, PdfColor a) {
  const body = PdfColor.fromInt(0xFF555555);
  final dark = shade(a, 0.1);
  final faint = tint(a, 0.86);

  pw.TextStyle s(pw.Font font, double size, PdfColor c, {double ls = 0}) =>
      pw.TextStyle(font: font, fontSize: size, color: c, letterSpacing: ls, lineSpacing: 1.5);

  pw.Widget headU(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 9),
        child: pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4, right: 30),
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: a, width: 1.2))),
          child: pw.Text(t.toUpperCase(), style: s(f.montserratBold, 11, a, ls: 0.8)),
        ),
      );
  pw.Widget headL(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 9),
        child: pw.Row(children: [
          pw.Text(t.toUpperCase(), style: s(f.montserratBold, 11, a, ls: 0.8)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: hRule(a, h: 1.2)),
        ]),
      );

  const letters = {'phone': 'T', 'email': '@', 'website': 'W'};
  final ct = contacts(d, const ['phone', 'email', 'website', 'address']);
  final header = pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Expanded(
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(d['firstName'], style: s(f.montserrat, 21, dark)),
        pw.Text(d['lastName'].toUpperCase(), style: s(f.montserratBold, 25, dark)),
        pw.SizedBox(height: 6),
        pw.Text(d['title'].toUpperCase(), style: s(f.montserrat, 8.4, dark, ls: 3.6)),
      ]),
    ),
    pw.SizedBox(width: 20),
    pw.SizedBox(
      width: 190,
      child: pw.Column(children: [
        for (final c in ct)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.SizedBox(
                width: 16,
                child: c.key == 'address' ? icon('address', a, 8.5) : pw.Text(letters[c.key] ?? '', style: s(f.montserratBold, 8.4, a)),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: a, width: 0.7))),
                  child: pw.Text(c.value, style: s(f.openSans, 8.2, body)),
                ),
              ),
            ]),
          ),
      ]),
    ),
  ]);

  final left = <pw.Widget>[];
  if (d['summary'].isNotEmpty) {
    left
      ..add(headU('Résumé'))
      ..add(pw.Container(
        padding: const pw.EdgeInsets.only(left: 9),
        decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: tint(a, 0.55), width: 1.1))),
        child: pw.Text(d['summary'], style: s(f.openSans, 8.6, body)),
      ))
      ..add(pw.SizedBox(height: 18));
  }
  final ex = d.items(Sec.experiences);
  if (ex.isNotEmpty) {
    left.add(headU('Expérience professionnelle'));
    for (final x in ex) {
      left.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(x['role'].toUpperCase(), style: s(f.montserratBold, 9.4, dark)),
          pw.Text(joinNonEmpty([x['company'], period(x['start'], x['end'])], ' | '), style: s(f.openSansSemi, 8.6, dark)),
          pw.SizedBox(height: 3),
          bullets(expLines(x), s(f.openSans, 8.5, body), dot: body, dotSize: 2.2),
        ]),
      ));
    }
    left.add(pw.SizedBox(height: 6));
  }
  final pj = d.items(Sec.projects);
  if (pj.isNotEmpty) {
    left.add(headU('Projets'));
    for (final p in pj) {
      left.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(text: '${p['name']} : ', style: s(f.openSansBold, 8.5, dark)),
            pw.TextSpan(text: p['desc'], style: s(f.openSans, 8.5, body)),
          ]),
        ),
      ));
    }
  }

  final right = <pw.Widget>[
    photo(d, 158, 168, circle: false, radius: 3),
    pw.SizedBox(height: 20),
  ];
  final edu = d.items(Sec.education);
  if (edu.isNotEmpty) {
    right.add(headL('Formation'));
    for (final e in edu) {
      right.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(e['degree'], style: s(f.openSansSemi, 8.6, dark)),
          if (e['school'].isNotEmpty) pw.Text(e['school'], style: s(f.openSans, 8.2, body)),
          if (period(e['start'], e['end']).isNotEmpty)
            pw.Text(period(e['start'], e['end']), style: s(f.openSansItalic, 8.2, tint(body, 0.25))),
        ]),
      ));
    }
    right.add(pw.SizedBox(height: 10));
  }
  final sk = d.items(Sec.skills);
  if (sk.isNotEmpty) {
    right.add(headL('Compétences'));
    for (final x in sk) {
      right.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(x['name'], style: s(f.openSans, 8.2, body)),
          pw.SizedBox(height: 2),
          bar(x.level, faint, a, height: 2.4),
        ]),
      ));
    }
    right.add(pw.SizedBox(height: 10));
  }
  final lg = d.items(Sec.languages);
  if (lg.isNotEmpty) {
    right.add(headL('Langues'));
    for (final l in lg) {
      right.add(pw.Text(joinNonEmpty([l['name'], l['level']], ' : '), style: s(f.openSans, 8.2, body)));
    }
  }

  return [
    pw.MultiPage(
      maxPages: 6,
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(58, 44, 40, 36),
        theme: pw.ThemeData.withFont(base: f.openSans, bold: f.openSansBold, italic: f.openSansItalic),
        buildBackground: (ctx) => fullBackground(pw.Stack(children: [
          pw.SizedBox(width: PdfPageFormat.a4.width, height: PdfPageFormat.a4.height),
          pw.Positioned(left: 24, top: 44, bottom: 44, child: pw.Container(width: 0.8, color: a)),
          if (ctx.pageNumber == 1)
            pw.Positioned(left: 36, top: 42, child: pw.Container(width: 10, height: 66, color: a)),
        ])),
      ),
      build: (ctx) => [
        header,
        pw.SizedBox(height: 24),
        pw.Partitions(children: [
          pw.Partition(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: padAll(left, const pw.EdgeInsets.only(right: 24)),
            ),
          ),
          pw.Partition(width: 158, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: right)),
        ]),
      ],
    ),
  ];
}
