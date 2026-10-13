# CV Minerva

Application mobile Flutter (Android et iOS) pour créer un CV sans logiciel de mise en page :

1. on choisit un **modèle** parmi 8 (dont 2 CV canadiens sans photo) ;
2. l'app affiche **les sections de ce modèle** sous forme de champs simples, avec un bouton **+ Ajouter** pour les expériences, formations, compétences… ;
3. on choisit la **couleur** du CV ;
4. on clique sur **Générer le CV** : **PDF** ou **JPG**, à enregistrer sur le téléphone ou à partager.

Les CV sont **enregistrés automatiquement sur le téléphone** (écran « Mes CV ») : renommer, dupliquer, supprimer, reprendre plus tard.

## Les modèles

| Modèle | Photo | Compétences | Particularité |
|---|---|---|---|
| Ardoise | oui | liste (pro + techniques) | bandeau latéral coloré, frise d'expériences, références |
| Galerie | carrée | liste | deux colonnes avec filet vertical, réalisations |
| Horizon | ronde | **en %** | frise horizontale des formations |
| Linéa | ronde | **avec mention** | nom très espacé, intérêts et références |
| Atelier | ronde | liste | titres Marcellus, style architecte |
| Ingénieur | rectangle | **en %** | projets, langues |
| Québec | non | liste | CV canadien classique, perfectionnement |
| Toronto | non | liste | CV canadien moderne, bandeau coloré |

Le formulaire change selon le modèle : un modèle « en % » affiche un curseur, un modèle « avec mention » affiche Débutant / Intermédiaire / Avancé / Expert. Les textes saisis sont conservés quand on change de modèle.

## Installation (Windows)

Prérequis : Flutter installé (`flutter doctor` sans erreur bloquante) et Git.

Dans ce dossier, double-cliquez sur **`setup.bat`**, ou lancez à la main :

```bash
flutter create . --org com.minerva --project-name cv_minerva --platforms=android,ios
flutter pub get
dart run flutter_launcher_icons
flutter run
```

`flutter create .` ajoute seulement les dossiers `android/` et `ios/` : il ne remplace pas `lib/`, `pubspec.yaml` ni ce README.

### Envoi sur GitHub

`setup.bat` le fait à la fin. À la main :

```bash
git init
git branch -M main
git remote add origin https://github.com/koceilaidir/CV-app.git
git add .
git commit -m "CV Minerva : première version de l'app mobile"
git push -u origin main
```

### Réglages par plateforme (après `flutter create`)

**iOS**, dans `ios/Runner/Info.plist` :

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Pour ajouter votre photo sur le CV.</string>
<!-- Rend les CV enregistrés visibles dans l'app Fichiers -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

**Android** : rien d'obligatoire. Les fichiers sont enregistrés dans **Téléchargements**. Pour les très vieux téléphones (Android 9 et moins), ajoutez dans `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
```

## Organisation du code

```
lib/
  main.dart                      point d'entrée
  theme.dart                     couleurs et polices de l'app
  models/cv_data.dart            données du CV, CV enregistré, exemple
  services/storage.dart          sauvegarde locale (shared_preferences)
  services/cv_export.dart        PDF, aperçu, JPG, enregistrer, partager
  templates/template_def.dart    liste des modèles + palette de couleurs
  templates/tpl_*.dart           un fichier par modèle (dessin du PDF)
  templates/pdf_kit.dart         briques communes (icônes, frises, barres…)
  templates/cv_fonts.dart        polices embarquées dans les PDF
  screens/home_screen.dart       « Mes CV »
  screens/template_picker_screen.dart   galerie des modèles
  screens/editor_screen.dart     formulaire, aperçu, couleur, génération
  widgets/cv_form.dart           formulaire adapté au modèle
  widgets/cv_thumbnail.dart      miniatures
assets/
  fonts/                         polices TTF (licence OFL, voir OFL.txt)
  icon/                          icône de l'app (SVG + PNG)
```

Chaque modèle est dessiné une seule fois avec le paquet `pdf` : l'aperçu à l'écran, le PDF et le JPG sortent du même code, donc ils sont identiques. Le JPG est le rendu du PDF à 200 dpi ; si le CV fait plusieurs pages, elles sont empilées dans une seule image.

### Ajouter un modèle

1. Créer `lib/templates/tpl_nom.dart` avec une fonction `List<pw.Page> buildNom(CvData d, CvFonts f, PdfColor accent)`.
2. L'ajouter dans la liste `templates` de `template_def.dart` (sections, libellés, mode des compétences, couleur d'origine).

## Tests

```bash
flutter test
```
