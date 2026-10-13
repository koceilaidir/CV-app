import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';
import 'cv_fonts.dart';
import 'pdf_kit.dart';

/// Ardoise : bandeau latéral coloré (photo, contact, formation, compétences),
/// colonne principale avec frise d'expériences et références.
List<pw.Page> buildArdoise(CvData d, CvFonts f, PdfColor a) {
  const sideW = 196.0;
  const ink = PdfColor.fromInt(0xFF363B47);
  const dark = PdfColor.fromInt(0xFF22283A);
  final sideText = tint(a, 0.82);
  final sideRule = tint(a, 0.5);

  pw.TextStyle s(pw.Font font, double size, PdfColor c, {double ls = 0}) =>
      pw.TextStyle(font: font, fontSize: size, color: c, letterSpacing: ls, lineSpacing: 1.6);

  pw.Widget sideHead(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 10),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 26),
            child: pw.Text(t.toUpperCase(), style: s(f.ralewayBold, 11, white, ls: 1.9)),
          ),
          pw.SizedBox(height: 5),
          pw.Padding(padding: const pw.EdgeInsets.only(left: 26), child: hRule(sideRule, h: 0.7)),
        ]),
      );

  pw.EdgeInsets sp([double b = 0]) => pw.EdgeInsets.fromLTRB(26, 0, 20, b);
  final side = <pw.Widget>[
    pw.Center(child: photo(d, 108, 108, border: const PdfColor.fromInt(0xFFF2F4F8), borderWidth: 4.5)),
    pw.SizedBox(height: 8),
  ];

  final ct = contacts(d, const ['address', 'phone', 'email', 'website']);
  if (ct.isNotEmpty) {
    side.add(sideHead('Contact'));
    for (final c in ct) {
      side.add(pw.Padding(
        padding: sp(6),
        child: pw.Row(children: [
          iconDot(c.key, sideText, a, 14),
          pw.SizedBox(width: 7),
          pw.Expanded(child: pw.Text(c.value, style: s(f.raleway, 8.4, sideText))),
        ]),
      ));
    }
  }

  final edu = d.items(Sec.education);
  if (edu.isNotEmpty) {
    side.add(sideHead('Formation'));
    for (final e in edu) {
      side.add(pw.Padding(
        padding: sp(9),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(e['degree'], style: s(f.ralewayBold, 9.6, white)),
          if (e['school'].isNotEmpty || e['place'].isNotEmpty)
            pw.Text(joinNonEmpty([e['school'], e['place']], ' / '), style: s(f.raleway, 8.4, sideText)),
          if (period(e['start'], e['end']).isNotEmpty) pw.Text(period(e['start'], e['end']), style: s(f.raleway, 8.4, sideText)),
        ]),
      ));
    }
  }

  final sk = d.items(Sec.skills);
  final tools = d.items(Sec.tools);
  if (sk.isNotEmpty || tools.isNotEmpty) {
    side.add(sideHead('Compétences'));
    void group(String title, List<String> items) {
      side.add(pw.Padding(padding: sp(3), child: pw.Text('// $title', style: s(f.ralewayBold, 9.6, white))));
      for (final t in items) {
        side.add(pw.Padding(padding: sp(), child: pw.Text(t, style: s(f.raleway, 8.4, sideText))));
      }
      side.add(pw.SizedBox(height: 8));
    }

    if (sk.isNotEmpty) group('Professionnelles', [for (final x in sk) x['name']]);
    if (tools.isNotEmpty) group('Techniques', [for (final x in tools) x['text']]);
  }

  // Colonne principale
  pw.Widget head(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20, bottom: 12),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(t.toUpperCase(), style: s(f.ralewayBold, 11, a, ls: 1.5)),
          pw.SizedBox(height: 4),
          hRule(a, h: 1.1),
        ]),
      );

  final main = <pw.Widget>[
    pw.SizedBox(height: 10),
    pw.RichText(
      text: pw.TextSpan(children: [
        pw.TextSpan(text: '${d['firstName'].toUpperCase()} ', style: s(f.ralewayXBold, 28, a, ls: 1.5)),
        pw.TextSpan(text: d['lastName'].toUpperCase(), style: s(f.raleway, 28, a, ls: 1.5)),
      ]),
    ),
    pw.SizedBox(height: 6),
    pw.Text(d['title'].toUpperCase(), style: s(f.ralewaySemi, 8.6, a, ls: 2.2)),
    pw.SizedBox(height: 10),
    if (d['summary'].isNotEmpty) pw.Text(d['summary'], style: s(f.raleway, 9, ink)),
  ];

  final ex = d.items(Sec.experiences);
  if (ex.isNotEmpty) {
    main.add(head('Expérience professionnelle'));
    for (var i = 0; i < ex.length; i++) {
      final x = ex[i];
      main.add(timelineItem(
        line: a,
        lineWidth: 1.1,
        dotSize: 9,
        dot: ringDot(9, a, white, width: 1.5),
        last: i == ex.length - 1,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(text: x['company'], style: s(f.ralewayBold, 10, dark)),
              if (x['role'].isNotEmpty) pw.TextSpan(text: '  /  ${x['role']}', style: s(f.raleway, 10, dark)),
            ]),
          ),
          pw.Text(joinNonEmpty([period(x['start'], x['end']), x['place']], ' · '), style: s(f.ralewaySemi, 8.6, a)),
          pw.SizedBox(height: 3),
          if (x['desc'].isNotEmpty) pw.Text(x['desc'], style: s(f.raleway, 8.8, ink)),
          if (lines(x['bullets']).isNotEmpty) pw.SizedBox(height: 3),
          bullets(lines(x['bullets']), s(f.raleway, 8.8, ink), dot: a),
        ]),
      ));
    }
  }

  final refs = d.items(Sec.references);
  if (refs.isNotEmpty) {
    main.add(head('Références'));
    main.add(pw.Wrap(spacing: 16, runSpacing: 10, children: [
      for (final r in refs)
        pw.SizedBox(
          width: 160,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(r['name'], style: s(f.ralewayBold, 9.8, dark)),
            if (r['role'].isNotEmpty) pw.Text(r['role'], style: s(f.raleway, 8.6, ink)),
            if (r['phone'].isNotEmpty) pw.Text('Tél : ${r['phone']}', style: s(f.raleway, 8.6, ink)),
            if (r['email'].isNotEmpty) pw.Text('Email : ${r['email']}', style: s(f.raleway, 8.6, ink)),
          ]),
        ),
    ]));
  }

  return [
    pw.MultiPage(
      maxPages: 6,
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(0, 36, 0, 30),
        theme: pw.ThemeData.withFont(base: f.raleway, bold: f.ralewayBold),
        buildBackground: (ctx) => fullBackground(pw.Align(
          alignment: pw.Alignment.topLeft,
          child: pw.Container(width: sideW, height: PdfPageFormat.a4.height, color: a),
        )),
      ),
      build: (ctx) => [
        pw.Partitions(children: [
          pw.Partition(width: sideW, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: side)),
          pw.Partition(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: padAll(main, const pw.EdgeInsets.fromLTRB(28, 0, 34, 0)),
            ),
          ),
        ]),
      ],
    ),
  ];
}
