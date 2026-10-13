import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';
import 'cv_fonts.dart';
import 'pdf_kit.dart';

/// Horizon : photo ronde et « Bonjour, je suis », frise horizontale des formations,
/// contact et expertise en pourcentage à gauche, frise d'expériences à droite.
List<pw.Page> buildHorizon(CvData d, CvFonts f, PdfColor a) {
  const bg = PdfColor.fromInt(0xFFF1F1F1);
  const grey = PdfColor.fromInt(0xFF666666);
  const dark = PdfColor.fromInt(0xFF222222);
  final rule = tint(a, 0.6);

  pw.TextStyle s(pw.Font font, double size, PdfColor c, {double ls = 0}) =>
      pw.TextStyle(font: font, fontSize: size, color: c, letterSpacing: ls, lineSpacing: 1.5);

  pw.Widget head(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Text(t, style: s(f.lato, 12, a, ls: 0.8)),
      );

  final header = pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
    photo(d, 112, 112),
    pw.SizedBox(width: 26),
    pw.Expanded(
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(d['title'], style: s(f.lato, 8, grey, ls: 0.4)),
        pw.Text('Bonjour, je suis', style: s(f.latoLight, 18, dark)),
        pw.Text(d.fullName, style: s(f.latoBold, 18, a, ls: 0.4)),
        if (d['summary'].isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(d['summary'], style: s(f.lato, 8.6, grey)),
        ],
      ]),
    ),
  ]);

  final top = <pw.Widget>[header, pw.SizedBox(height: 26)];

  final edu = d.items(Sec.education).take(3).toList();
  if (edu.isNotEmpty) {
    top
      ..add(head('Formation'))
      ..add(pw.Stack(children: [
        pw.Positioned(left: 0, right: 0, top: 4, child: hRule(rule, h: 0.8)),
        pw.Row(children: [
          for (var i = 0; i < 3; i++)
            pw.Expanded(
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: i < edu.length ? ringDot(9, a, bg, width: 0.9) : pw.SizedBox(height: 9),
              ),
            ),
        ]),
      ]))
      ..add(pw.SizedBox(height: 8))
      ..add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        for (var i = 0; i < 3; i++)
          pw.Expanded(
            child: i < edu.length
                ? pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 14),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(edu[i]['degree'], style: s(f.latoBold, 9.4, dark)),
                      pw.Text(joinNonEmpty([edu[i]['school'], edu[i]['place']], ' | '), style: s(f.lato, 8.2, grey)),
                      pw.Text(period(edu[i]['start'], edu[i]['end']), style: s(f.lato, 8.2, grey)),
                    ]),
                  )
                : pw.SizedBox(),
          ),
      ]))
      ..add(pw.SizedBox(height: 26));
  }

  final left = <pw.Widget>[];
  final ct = contacts(d, const ['address', 'phone', 'email', 'website']);
  if (ct.isNotEmpty) {
    left.add(head('Contact'));
    for (final c in ct) {
      left.add(pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: rule, width: 0.7))),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Padding(padding: const pw.EdgeInsets.only(top: 1.5), child: icon(c.key, a, 10)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(contactLabels[c.key]!, style: s(f.latoBold, 8.6, dark)),
              pw.Text(c.value, style: s(f.lato, 8.2, grey)),
            ]),
          ),
        ]),
      ));
    }
    left.add(pw.SizedBox(height: 22));
  }
  final sk = d.items(Sec.skills);
  if (sk.isNotEmpty) {
    left.add(head('Expertise'));
    for (final x in sk) {
      left.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Expanded(child: pw.Text(x['name'], style: s(f.lato, 8.6, dark))),
            pw.Text('${x.level} %', style: s(f.lato, 8.6, dark)),
          ]),
          pw.SizedBox(height: 2),
          bar(x.level, tint(a, 0.78), a, height: 3),
        ]),
      ));
    }
  }

  final right = <pw.Widget>[];
  final ex = d.items(Sec.experiences);
  if (ex.isNotEmpty) {
    right.add(head('Expérience professionnelle'));
    for (var i = 0; i < ex.length; i++) {
      final x = ex[i];
      right.add(timelineItem(
        line: rule,
        lineWidth: 0.8,
        dotSize: 9,
        dot: ringDot(9, a, bg, width: 0.9),
        last: i == ex.length - 1,
        bottom: 13,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(x['role'], style: s(f.latoBold, 9.8, dark)),
          pw.Text(joinNonEmpty([x['company'], x['place']], ' | '), style: s(f.lato, 8.2, grey)),
          pw.Text(period(x['start'], x['end']), style: s(f.lato, 8.2, grey)),
          pw.SizedBox(height: 3),
          if (x['desc'].isNotEmpty) pw.Text(x['desc'], style: s(f.lato, 8.6, grey)),
          bullets(lines(x['bullets']), s(f.lato, 8.6, grey), dot: a),
        ]),
      ));
    }
  }

  return [
    pw.MultiPage(
      maxPages: 6,
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(44, 42, 44, 36),
        theme: pw.ThemeData.withFont(base: f.lato, bold: f.latoBold, italic: f.latoItalic),
        buildBackground: (ctx) => fullBackground(pw.Container(color: bg)),
      ),
      build: (ctx) => [
        ...top,
        pw.Partitions(children: [
          pw.Partition(width: 158, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: left)),
          pw.Partition(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: padAll(right, const pw.EdgeInsets.only(left: 33)),
            ),
          ),
        ]),
      ],
    ),
  ];
}
