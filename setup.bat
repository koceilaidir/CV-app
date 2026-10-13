@echo off
chcp 65001 >nul
REM ============================================================
REM  CV Minerva : installation du projet Flutter + envoi sur GitHub
REM  A lancer une seule fois, depuis ce dossier.
REM ============================================================

echo.
echo [1/4] Creation des dossiers Android et iOS...
call flutter create . --org com.minerva --project-name cv_minerva --platforms=android,ios
if errorlevel 1 goto erreur

echo.
echo [2/4] Telechargement des paquets...
call flutter pub get
if errorlevel 1 goto erreur

echo.
echo [3/4] Generation de l'icone de l'app...
call dart run flutter_launcher_icons
if errorlevel 1 goto erreur

echo.
echo [4/4] Envoi sur GitHub...
if not exist ".git" (
  git init
  git branch -M main
  git remote add origin https://github.com/koceilaidir/CV-app.git
)
git add .
git commit -m "CV Minerva : premiere version de l'app mobile"
git push -u origin main
if errorlevel 1 goto erreur

echo.
echo Termine. Lancez l'app avec :  flutter run
goto fin

:erreur
echo.
echo Une etape a echoue. Lisez le message ci-dessus, corrigez puis relancez setup.bat.

:fin
pause
