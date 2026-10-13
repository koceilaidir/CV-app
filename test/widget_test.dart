import 'package:flutter_test/flutter_test.dart';

import 'package:cv_minerva/models/cv_data.dart';
import 'package:cv_minerva/templates/template_def.dart';

void main() {
  test('Les données du CV survivent à un aller-retour JSON', () {
    final cv = SavedCv(name: 'Test', templateId: 'linea', data: CvData.sample(), color: 0xFF6B2737);
    final back = SavedCv.fromJson(cv.toJson());
    expect(back.name, 'Test');
    expect(back.color, 0xFF6B2737);
    expect(back.data.fullName, 'Yanis Belkacem');
    expect(back.data.items(Sec.experiences).length, 3);
    expect(back.data.items(Sec.skills).first.level, 95);
  });

  test('Chaque modèle a un id unique et des sections connues', () {
    final ids = templates.map((t) => t.id).toSet();
    expect(ids.length, templates.length);
    for (final t in templates) {
      for (final s in t.sections) {
        expect([Sec.identity, Sec.contact, Sec.summary, ...Sec.lists].contains(s), isTrue, reason: '${t.id}: $s');
      }
    }
  });

  test('Mentions de niveau', () {
    expect(mention(95), 'Expert');
    expect(mention(75), 'Avancé');
    expect(mention(55), 'Intermédiaire');
    expect(mention(20), 'Débutant');
  });
}
