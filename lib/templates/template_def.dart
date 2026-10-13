import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_data.dart';
import 'cv_fonts.dart';
import 'tpl_ardoise.dart';
import 'tpl_atelier.dart';
import 'tpl_galerie.dart';
import 'tpl_horizon.dart';
import 'tpl_ingenieur.dart';
import 'tpl_linea.dart';
import 'tpl_quebec.dart';
import 'tpl_toronto.dart';

/// Comment un modèle affiche les compétences.
enum SkillMode {
  list('Compétences en liste'),
  percent('Compétences en %'),
  mention('Compétences avec mention');

  const SkillMode(this.label);
  final String label;
}

typedef CvBuilder = List<pw.Page> Function(CvData d, CvFonts f, PdfColor accent);

class CvTemplate {
  const CvTemplate({
    required this.id,
    required this.name,
    required this.photo,
    required this.skillMode,
    required this.canadian,
    required this.defaultColor,
    required this.contact,
    required this.sections,
    required this.labels,
    required this.builder,
  });

  final String id;
  final String name;
  final bool photo;
  final SkillMode skillMode;
  final bool canadian;

  /// Couleur d'origine du modèle (ARGB).
  final int defaultColor;

  /// Coordonnées affichées, dans l'ordre.
  final List<String> contact;

  /// Sections du formulaire, dans l'ordre.
  final List<String> sections;

  /// Titre de chaque section tel qu'il apparaît dans le CV.
  final Map<String, String> labels;
  final CvBuilder builder;

  Color get color => Color(defaultColor);

  String label(String section) =>
      labels[section] ??
      const {
        'identity': 'Identité',
        'contact': 'Coordonnées',
        'summary': 'Présentation',
      }[section] ??
      section;

  Future<Uint8List> buildPdf(CvData d, CvFonts f, {int? color}) async {
    final doc = pw.Document(title: d.fullName.isEmpty ? 'CV' : 'CV ${d.fullName}', creator: 'CV Minerva');
    for (final p in builder(d, f, PdfColor.fromInt(color ?? defaultColor))) {
      doc.addPage(p);
    }
    return doc.save();
  }
}

/// Palette proposée dans l'éditeur.
const cvPalette = <int>[
  0xFF2E3A55, // ardoise
  0xFF2B2B2B, // charbon
  0xFF1E4E5A, // pétrole
  0xFF1F4E9C, // bleu roi
  0xFF2F5D50, // sapin
  0xFF6B2737, // bordeaux
  0xFFA4563B, // terracotta
  0xFF4E3A63, // prune
  0xFF9A7418, // moutarde
  0xFF5A6472, // gris bleuté
];

final templates = <CvTemplate>[
  CvTemplate(
    id: 'ardoise',
    name: 'Ardoise',
    photo: true,
    skillMode: SkillMode.list,
    canadian: false,
    defaultColor: 0xFF2E3A55,
    contact: const ['address', 'phone', 'email', 'website'],
    sections: const [Sec.identity, Sec.contact, Sec.summary, Sec.education, Sec.skills, Sec.tools, Sec.experiences, Sec.references],
    labels: const {
      Sec.summary: 'Présentation',
      Sec.education: 'Formation',
      Sec.skills: 'Compétences professionnelles',
      Sec.tools: 'Compétences techniques',
      Sec.experiences: 'Expérience professionnelle',
      Sec.references: 'Références',
    },
    builder: buildArdoise,
  ),
  CvTemplate(
    id: 'galerie',
    name: 'Galerie',
    photo: true,
    skillMode: SkillMode.list,
    canadian: false,
    defaultColor: 0xFF474747,
    contact: const ['phone', 'email', 'website'],
    sections: const [Sec.identity, Sec.contact, Sec.summary, Sec.skills, Sec.achievements, Sec.education, Sec.experiences],
    labels: const {
      Sec.summary: 'Profil',
      Sec.skills: 'Compétences',
      Sec.achievements: 'Réalisations',
      Sec.education: 'Formation',
      Sec.experiences: 'Expérience',
    },
    builder: buildGalerie,
  ),
  CvTemplate(
    id: 'horizon',
    name: 'Horizon',
    photo: true,
    skillMode: SkillMode.percent,
    canadian: false,
    defaultColor: 0xFF3A3A3A,
    contact: const ['address', 'phone', 'email', 'website'],
    sections: const [Sec.identity, Sec.summary, Sec.education, Sec.contact, Sec.skills, Sec.experiences],
    labels: const {
      Sec.summary: 'Présentation',
      Sec.education: 'Formation (3 affichées)',
      Sec.skills: 'Expertise',
      Sec.experiences: 'Expérience professionnelle',
    },
    builder: buildHorizon,
  ),
  CvTemplate(
    id: 'linea',
    name: 'Linéa',
    photo: true,
    skillMode: SkillMode.mention,
    canadian: false,
    defaultColor: 0xFF222222,
    contact: const ['address', 'phone', 'email'],
    sections: const [Sec.identity, Sec.contact, Sec.summary, Sec.skills, Sec.education, Sec.experiences, Sec.interests, Sec.references],
    labels: const {
      Sec.summary: 'Profil',
      Sec.skills: 'Compétences',
      Sec.education: 'Formation',
      Sec.experiences: 'Expérience',
      Sec.interests: "Centres d'intérêt",
      Sec.references: 'Références',
    },
    builder: buildLinea,
  ),
  CvTemplate(
    id: 'atelier',
    name: 'Atelier',
    photo: true,
    skillMode: SkillMode.list,
    canadian: false,
    defaultColor: 0xFF111111,
    contact: const ['phone', 'email', 'linkedin', 'address'],
    sections: const [Sec.identity, Sec.summary, Sec.contact, Sec.education, Sec.skills, Sec.experiences],
    labels: const {
      Sec.summary: 'Présentation',
      Sec.education: 'Formation',
      Sec.skills: 'Compétences',
      Sec.experiences: 'Expérience',
    },
    builder: buildAtelier,
  ),
  CvTemplate(
    id: 'ingenieur',
    name: 'Ingénieur',
    photo: true,
    skillMode: SkillMode.percent,
    canadian: false,
    defaultColor: 0xFF111111,
    contact: const ['phone', 'email', 'website', 'address'],
    sections: const [Sec.identity, Sec.contact, Sec.summary, Sec.experiences, Sec.projects, Sec.education, Sec.skills, Sec.languages],
    labels: const {
      Sec.summary: 'Résumé',
      Sec.experiences: 'Expérience professionnelle',
      Sec.projects: 'Projets',
      Sec.education: 'Formation',
      Sec.skills: 'Compétences',
      Sec.languages: 'Langues',
    },
    builder: buildIngenieur,
  ),
  CvTemplate(
    id: 'quebec',
    name: 'Québec',
    photo: false,
    skillMode: SkillMode.list,
    canadian: true,
    defaultColor: 0xFF333333,
    contact: const ['address', 'phone', 'email'],
    sections: const [Sec.identity, Sec.contact, Sec.summary, Sec.experiences, Sec.education, Sec.skills, Sec.languages, Sec.training],
    labels: const {
      Sec.summary: 'Sommaire professionnel',
      Sec.experiences: 'Expérience de travail',
      Sec.education: 'Formation',
      Sec.skills: 'Compétences',
      Sec.languages: 'Langues',
      Sec.training: 'Perfectionnement',
    },
    builder: buildQuebec,
  ),
  CvTemplate(
    id: 'toronto',
    name: 'Toronto',
    photo: false,
    skillMode: SkillMode.list,
    canadian: true,
    defaultColor: 0xFF1E4E5A,
    contact: const ['address', 'phone', 'email', 'linkedin'],
    sections: const [Sec.identity, Sec.contact, Sec.summary, Sec.skills, Sec.experiences, Sec.education, Sec.languages, Sec.achievements, Sec.training],
    labels: const {
      Sec.summary: 'Profil professionnel',
      Sec.skills: 'Compétences clés',
      Sec.experiences: 'Expérience professionnelle',
      Sec.education: 'Formation',
      Sec.languages: 'Langues',
      Sec.achievements: 'Réalisations',
      Sec.training: 'Perfectionnement',
    },
    builder: buildToronto,
  ),
];

CvTemplate templateById(String id) => templates.firstWhere((t) => t.id == id, orElse: () => templates.first);
