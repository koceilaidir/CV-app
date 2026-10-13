import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Polices embarquées dans les PDF (fichiers TTF statiques dans assets/fonts).
/// Chargées une seule fois puis gardées en mémoire.
class CvFonts {
  CvFonts._(this._f);
  final Map<String, pw.Font> _f;

  static CvFonts? _cache;

  static const _files = [
    'Raleway_300Light', 'Raleway_400Regular', 'Raleway_600SemiBold', 'Raleway_700Bold', 'Raleway_800ExtraBold',
    'Archivo_400Regular', 'Archivo_400Regular_Italic', 'Archivo_700Bold',
    'Lato_300Light', 'Lato_400Regular', 'Lato_400Regular_Italic', 'Lato_700Bold',
    'Marcellus_400Regular',
    'Montserrat_400Regular', 'Montserrat_700Bold',
    'OpenSans_400Regular', 'OpenSans_400Regular_Italic', 'OpenSans_600SemiBold', 'OpenSans_700Bold',
  ];

  static Future<CvFonts> load() async {
    if (_cache != null) return _cache!;
    final map = <String, pw.Font>{};
    for (final name in _files) {
      final data = await rootBundle.load('assets/fonts/$name.ttf');
      map[name] = pw.Font.ttf(data);
    }
    return _cache = CvFonts._(map);
  }

  pw.Font get ralewayLight => _f['Raleway_300Light']!;
  pw.Font get raleway => _f['Raleway_400Regular']!;
  pw.Font get ralewaySemi => _f['Raleway_600SemiBold']!;
  pw.Font get ralewayBold => _f['Raleway_700Bold']!;
  pw.Font get ralewayXBold => _f['Raleway_800ExtraBold']!;
  pw.Font get archivo => _f['Archivo_400Regular']!;
  pw.Font get archivoItalic => _f['Archivo_400Regular_Italic']!;
  pw.Font get archivoBold => _f['Archivo_700Bold']!;
  pw.Font get latoLight => _f['Lato_300Light']!;
  pw.Font get lato => _f['Lato_400Regular']!;
  pw.Font get latoItalic => _f['Lato_400Regular_Italic']!;
  pw.Font get latoBold => _f['Lato_700Bold']!;
  pw.Font get marcellus => _f['Marcellus_400Regular']!;
  pw.Font get montserrat => _f['Montserrat_400Regular']!;
  pw.Font get montserratBold => _f['Montserrat_700Bold']!;
  pw.Font get openSans => _f['OpenSans_400Regular']!;
  pw.Font get openSansItalic => _f['OpenSans_400Regular_Italic']!;
  pw.Font get openSansSemi => _f['OpenSans_600SemiBold']!;
  pw.Font get openSansBold => _f['OpenSans_700Bold']!;
}
