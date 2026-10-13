import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';
import 'cv_fonts.dart';
import 'pdf_kit.dart';

/// Linéa : nom en capitales très espacées, photo ronde à droite, filet vertical,
/// compétences avec mention, frises pour la formation et l'expérience.
List<pw.Page> buildLinea(CvData d, CvFonts f, PdfColor a) {
  const bg = PdfColor.fromInt(0xFFFBFBFA);
  final body = tint(a, 0.3);
  final light = tint(a, 0.5);

  pw.TextStyle s(pw.Font font, double size, PdfColor c, {double ls = 0}) =>
      pw.TextStyle(font: font, fontSize: size, color: c, letterSpacing: ls, lineSpacing: 1.5);

  pw.Widget head(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 11),
        child: pw.Text(t.toUpperCase(), style: s(f.ralewayBold, 11, a, ls: 3)),
      );

  pw.Widget dot() => pw.Container(
        width: 9,
        height: 9,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(color: bg, shape: pw.BoxShape.circle, border: pw.Border.all(color: a, width: 1.1)),
        child: pw.Container(width: 3, height: 3, decoration: pw.BoxDecoration(color: a, shape: pw.BoxShape.circle)),
      );

  pw.Widget ringItem(String text, {String? sub}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Padding(padding: const pw.EdgeInsets.only(top: 2.5), child: ringDot(6, a, bg, width: 1.1)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(text, style: s(f.raleway, 8.6, body)),
              if (sub != null) pw.Text(sub.toUpperCase(), style: s(f.ralewaySemi, 7, light, ls: 0.8)),
            ]),
          ),
        ]),
      );

  final header = pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
    pw.Expanded(
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(d['firstName'].toUpperCase(), style: s(f.raleway, 16, a, ls: 6)),
        pw.Text(d['lastName'].toUpperCase(), style: s(f.ralewayBold, 33, a, ls: 7)),
        pw.SizedBox(height: 4),
        pw.Text(d['title'].toUpperCase(), style: s(f.raleway, 8.6, body, ls: 3)),
      ]),
    ),
    pw.SizedBox(width: 16),
    photo(d, 90, 90),
  ]);

  final left = <pw.Widget>[];
  final ct = contacts(d, const ['address', 'phone', 'email']);
  if (ct.isNotEmpty) {
    left.add(head('Contact'));
    for (final c in ct) {
      left.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Row(children: [
          iconDot(c.key, a, white, 13),
          pw.SizedBox(width: 7),
          pw.Expanded(child: pw.Text(c.value, style: s(f.raleway, 8.2, body))),
        ]),
      ));
    }
    left.add(pw.SizedBox(height: 18));
  }
  final sk = d.items(Sec.skills);
  if (sk.isNotEmpty) {
    left
      ..add(head('Compétences'))
      ..add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text('PROFESSIONNELLES', style: s(f.ralewayBold, 7.8, a, ls: 1.9)),
      ));
    for (final x in sk) {
      left.add(ringItem(x['name'], sub: mention(x.level)));
    }
    left.add(pw.SizedBox(height: 16));
  }
  final edu = d.items(Sec.education);
  if (edu.isNotEmpty) {
    left.add(head('Formation'));
    for (var i = 0; i < edu.length; i++) {
      final e = edu[i];
      left.add(timelineItem(
        line: a,
        lineWidth: 1.1,
        dotSize: 9,
        dotTop: 1,
        dot: dot(),
        gapLeft: 9,
        last: i == edu.length - 1,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(e['degree'].toUpperCase(), style: s(f.ralewayBold, 8.4, a, ls: 1.2)),
          if (e['school'].isNotEmpty) pw.Text(e['school'].toUpperCase(), style: s(f.raleway, 7.8, body, ls: 0.9)),
          pw.Text(period(e['start'], e['end']), style: s(f.raleway, 7.8, body, ls: 0.9)),
        ]),
      ));
    }
  }

  final right = <pw.Widget>[];
  if (d['summary'].isNotEmpty) {
    right
      ..add(head('Profil'))
      ..add(pw.Text(d['summary'], style: s(f.raleway, 9, body)))
      ..add(pw.SizedBox(height: 20));
  }
  final ex = d.items(Sec.experiences);
  if (ex.isNotEmpty) {
    right.add(head('Expérience'));
    for (var i = 0; i < ex.length; i++) {
      final x = ex[i];
      right.add(timelineItem(
        line: a,
        lineWidth: 1.1,
        dotSize: 9,
        dotTop: 1,
        dot: dot(),
        gapLeft: 9,
        bottom: 14,
        last: i == ex.length - 1,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(
            joinNonEmpty([x['role'].toUpperCase(), period(x['start'], x['end']).toUpperCase()], '  |  '),
            style: s(f.ralewayBold, 8.6, a, ls: 1.6),
          ),
          pw.SizedBox(height: 2),
          pw.Text(x['company'].toUpperCase(), style: s(f.ralewayBold, 9.6, a)),
          pw.SizedBox(height: 3),
          if (x['desc'].isNotEmpty) pw.Text(x['desc'], style: s(f.raleway, 8.8, body)),
          bullets(lines(x['bullets']), s(f.raleway, 8.8, body), dot: a),
        ]),
      ));
    }
    right.add(pw.SizedBox(height: 16));
  }
  final ints = d.items(Sec.interests);
  final refs = d.items(Sec.references);
  if (ints.isNotEmpty || refs.isNotEmpty) {
    right.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      if (ints.isNotEmpty)
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            head('Intérêts'),
            for (final x in ints) ringItem(x['text']),
          ]),
        ),
      if (ints.isNotEmpty && refs.isNotEmpty) pw.SizedBox(width: 22),
      if (refs.isNotEmpty)
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            head('Références'),
            for (final r in refs)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 9),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(r['name'].toUpperCase(), style: s(f.ralewayBold, 8.4, a, ls: 1.1)),
                  for (final t in [r['role'], r['phone'], r['email']])
                    if (t.isNotEmpty) pw.Text(t, style: s(f.raleway, 8, body)),
                ]),
              ),
          ]),
        ),
    ]));
  }

  return [
    pw.MultiPage(
      maxPages: 6,
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(52, 44, 44, 36),
        theme: pw.ThemeData.withFont(base: f.raleway, bold: f.ralewayBold),
        buildBackground: (ctx) => fullBackground(pw.Stack(children: [
          pw.Container(width: PdfPageFormat.a4.width, height: PdfPageFormat.a4.height, color: bg),
          if (ctx.pageNumber == 1)
            pw.Positioned(left: 34, top: 32, child: pw.Container(width: 1.2, height: 112, color: a)),
        ])),
      ),
      build: (ctx) => [
        header,
        pw.SizedBox(height: 30),
        pw.Partitions(children: [
          pw.Partition(width: 140, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: left)),
          pw.Partition(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: padAll(right, const pw.EdgeInsets.only(left: 28)),
            ),
          ),
        ]),
      ],
    ),
  ];
}
