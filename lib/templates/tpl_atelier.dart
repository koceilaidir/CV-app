import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';
import 'cv_fonts.dart';
import 'pdf_kit.dart';

/// Atelier : titres en Marcellus, photo ronde en haut de la colonne gauche,
/// filet vertical, expériences sobres à droite.
List<pw.Page> buildAtelier(CvData d, CvFonts f, PdfColor a) {
  const bg = PdfColor.fromInt(0xFFF4F4F3);
  final body = tint(a, 0.28);
  final rule = tint(a, 0.5);

  pw.TextStyle s(pw.Font font, double size, PdfColor c, {double ls = 0}) =>
      pw.TextStyle(font: font, fontSize: size, color: c, letterSpacing: ls, lineSpacing: 1.5);

  pw.Widget head(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 11),
        child: pw.Text(t.toUpperCase(), style: s(f.marcellus, 11.2, a, ls: 2.6)),
      );
  pw.Widget shortRule([double w = 76]) =>
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 18), child: hRule(rule, h: 0.7, width: w));

  final left = <pw.Widget>[
    pw.Center(child: photo(d, 126, 126)),
    pw.SizedBox(height: 28),
  ];
  final ct = contacts(d, const ['phone', 'email', 'linkedin', 'address']);
  if (ct.isNotEmpty) {
    left.add(head('Contact'));
    for (final c in ct) {
      left.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Row(children: [
          iconDot(c.key, a, white, 15),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Text(c.value, style: s(f.lato, 8.6, body))),
        ]),
      ));
    }
    left.add(shortRule());
  }
  final edu = d.items(Sec.education);
  if (edu.isNotEmpty) {
    left.add(head('Formation'));
    for (final e in edu) {
      left.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 9),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(e['school'].toUpperCase(), style: s(f.lato, 8.6, body)),
          for (final t in [e['place'], e['degree'], period(e['start'], e['end'])])
            if (t.isNotEmpty) pw.Text(t, style: s(f.lato, 8.6, body)),
        ]),
      ));
    }
    left.add(shortRule());
  }
  final sk = d.items(Sec.skills);
  if (sk.isNotEmpty) {
    left.add(head('Compétences'));
    for (final x in sk) {
      left.add(pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: pw.Text(x['name'], style: s(f.lato, 8.6, body))));
    }
  }

  final right = <pw.Widget>[
    pw.SizedBox(height: 8),
    pw.Text(d.fullName.toUpperCase(), style: s(f.marcellus, 30, a, ls: 1.1)),
    pw.SizedBox(height: 6),
    pw.Text(d['title'], style: s(f.marcellus, 15, a, ls: 2.2)),
    pw.SizedBox(height: 9),
    if (d['summary'].isNotEmpty) pw.Text(d['summary'], style: s(f.lato, 9, body)),
    shortRule(130),
  ];
  final ex = d.items(Sec.experiences);
  if (ex.isNotEmpty) {
    right.add(head('Expérience'));
    for (final x in ex) {
      right.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 15),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(x['role'].toUpperCase(), style: s(f.latoBold, 8.8, a)),
          pw.Text(joinNonEmpty([x['company'], x['place'], period(x['start'], x['end'])], ' | '), style: s(f.lato, 8.2, body)),
          pw.SizedBox(height: 4),
          if (x['desc'].isNotEmpty) pw.Text(x['desc'], style: s(f.lato, 8.8, body)),
          bullets(lines(x['bullets']), s(f.lato, 8.8, body), dot: a),
        ]),
      ));
    }
  }

  final rightRuled = [
    for (final w in right)
      pw.Container(
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
        margin: const pw.EdgeInsets.fromLTRB(34, 40, 38, 34),
        theme: pw.ThemeData.withFont(base: f.lato, bold: f.latoBold, italic: f.latoItalic),
        buildBackground: (ctx) => fullBackground(pw.Container(color: bg)),
      ),
      build: (ctx) => [
        pw.Partitions(children: [
          pw.Partition(
            width: 180,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: padAll(left, const pw.EdgeInsets.only(right: 22)),
            ),
          ),
          pw.Partition(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: rightRuled)),
        ]),
      ],
    ),
  ];
}
