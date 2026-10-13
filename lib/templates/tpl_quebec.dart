import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';
import 'cv_fonts.dart';
import 'pdf_kit.dart';

/// Québec : CV canadien classique, une colonne, sans photo.
/// Sommaire, expérience de travail, formation, compétences, perfectionnement.
List<pw.Page> buildQuebec(CvData d, CvFonts f, PdfColor a) {
  const body = PdfColor.fromInt(0xFF3D3D3D);
  const grey = PdfColor.fromInt(0xFF666666);
  final dark = shade(a, 0.2);

  pw.TextStyle s(pw.Font font, double size, PdfColor c, {double ls = 0}) =>
      pw.TextStyle(font: font, fontSize: size, color: c, letterSpacing: ls, lineSpacing: 1.6);

  pw.Widget head(String t) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 14, bottom: 8),
        padding: const pw.EdgeInsets.only(bottom: 2),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: a, width: 1.5))),
        child: pw.Text(t.toUpperCase(), style: s(f.openSansSemi, 14, dark)),
      );
  final txt = s(f.openSans, 9.2, body);

  final out = <pw.Widget>[
    pw.Center(child: pw.Text(d.fullName, style: s(f.openSansSemi, 25, dark))),
    if (d['title'].isNotEmpty) pw.Center(child: pw.Text(d['title'], style: s(f.openSans, 11.5, grey))),
    pw.SizedBox(height: 12),
    pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 7),
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: a, width: 1.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final c in contacts(d, const ['address', 'phone', 'email']))
            pw.Flexible(child: pw.Padding(padding: const pw.EdgeInsets.only(right: 10), child: pw.Text(c.value, style: s(f.openSans, 9, body)))),
        ],
      ),
    ),
    if (d['summary'].isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 12), child: pw.Text(d['summary'], style: txt)),
  ];

  final ex = d.items(Sec.experiences);
  if (ex.isNotEmpty) {
    out.add(head('Expérience de travail'));
    for (final x in ex) {
      out.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 9),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(x['role'].toUpperCase(), style: s(f.openSansSemi, 9.6, dark)),
          pw.RichText(
            text: pw.TextSpan(style: txt, children: [
              pw.TextSpan(text: period(x['start'], x['end'])),
              if (x['company'].isNotEmpty) ...[
                pw.TextSpan(text: ' | '),
                pw.TextSpan(text: x['company'], style: s(f.openSansItalic, 9.2, body)),
              ],
              if (x['place'].isNotEmpty) pw.TextSpan(text: ', ${x['place']}'),
            ]),
          ),
          pw.SizedBox(height: 3),
          bullets(expLines(x), txt, dot: body, indent: 22),
        ]),
      ));
    }
  }

  final edu = d.items(Sec.education);
  if (edu.isNotEmpty) {
    out.add(head('Formation'));
    for (final e in edu) {
      out.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(e['degree'], style: s(f.openSansSemi, 9.4, dark)),
          pw.Text(
            joinNonEmpty([period(e['start'], e['end']), joinNonEmpty([e['school'], e['place']], ', ')], ' | '),
            style: s(f.openSans, 9.2, grey),
          ),
        ]),
      ));
    }
  }

  final sk = d.items(Sec.skills);
  final lg = d.items(Sec.languages);
  if (sk.isNotEmpty || lg.isNotEmpty) {
    out
      ..add(head('Compétences'))
      ..add(bullets([
        for (final x in sk) x['name'],
        if (lg.isNotEmpty)
          'Langues : ${lg.map((l) => l['level'].isEmpty ? l['name'] : '${l['name']} (${l['level'].toLowerCase()})').join(', ')}',
      ], txt, dot: body, indent: 22));
  }

  final tr = d.items(Sec.training);
  if (tr.isNotEmpty) {
    out
      ..add(head('Perfectionnement'))
      ..add(bullets([for (final t in tr) joinNonEmpty([t['year'], t['title']], ' : ')], txt, dot: body, indent: 22));
  }

  return [
    pw.MultiPage(
      maxPages: 6,
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(46, 44, 46, 36),
        theme: pw.ThemeData.withFont(base: f.openSans, bold: f.openSansBold, italic: f.openSansItalic),
      ),
      build: (ctx) => out,
    ),
  ];
}
