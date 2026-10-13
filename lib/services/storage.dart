import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cv_data.dart';

/// Sauvegarde locale des CV sur le téléphone (aucun compte, aucun serveur).
/// Chaque CV est stocké sous sa propre clé pour qu'une écriture ne réécrive pas tout.
class CvStorage {
  CvStorage._();
  static final instance = CvStorage._();

  static const _indexKey = 'cvminerva.index';
  static String _key(String id) => 'cvminerva.cv.$id';

  Future<List<SavedCv>> loadAll() async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList(_indexKey) ?? [];
    final out = <SavedCv>[];
    for (final id in ids) {
      final raw = p.getString(_key(id));
      if (raw == null) continue;
      try {
        out.add(SavedCv.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // CV illisible : on l'ignore plutôt que de bloquer toute la liste.
      }
    }
    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  Future<void> save(SavedCv cv) async {
    final p = await SharedPreferences.getInstance();
    cv.updatedAt = DateTime.now();
    await p.setString(_key(cv.id), jsonEncode(cv.toJson()));
    final ids = p.getStringList(_indexKey) ?? [];
    if (!ids.contains(cv.id)) {
      ids.add(cv.id);
      await p.setStringList(_indexKey, ids);
    }
  }

  Future<void> delete(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(id));
    final ids = p.getStringList(_indexKey) ?? [];
    ids.remove(id);
    await p.setStringList(_indexKey, ids);
  }
}
