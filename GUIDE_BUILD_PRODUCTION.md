# 🚀 Guide de Build Production - SALAM

## 📋 Prérequis

Avant de commencer le build :

- [ ] Tous les tests fonctionnels passent
- [ ] Bundle ID configuré : `com.salamagri.salam`
- [ ] Icônes et splash screens générés
- [ ] Keystore Android créé (si première fois)
- [ ] Certificats iOS configurés (si déploiement iOS)
- [ ] Supabase configuré en production
- [ ] Variables d'environnement vérifiées

---

## 🔧 Configuration Finale

### **1. Vérifier pubspec.yaml**

```yaml
name: salam
description: Société Agricole Locale pour l'Amélioration et la Modernisation
publish_to: 'none'

version: 1.0.0+1  # ⚠️ Incrémenter à chaque release

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # ... vos dépendances
```

**Version Format** :
- `1.0.0` = Version name (visible utilisateurs)
- `+1` = Version code (incrémentation interne)

### **2. Nettoyer le Projet**

```powershell
# Supprimer builds précédents
flutter clean

# Réinstaller les dépendances
flutter pub get

# Vérifier qu'il n'y a pas d'erreurs
flutter doctor -v
```

---

## 🤖 Build Android

### **Étape 1 : Créer le Keystore** (Première fois uniquement)

Si vous n'avez pas encore de keystore :

```powershell
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Informations à fournir** :
- **Mot de passe** : Notez-le précieusement !
- **Nom et prénom** : Adama Kâ
- **Organisation** : SALAM
- **Ville** : Dakar
- **Pays** : SN

⚠️ **IMPORTANT** : Sauvegardez `upload-keystore.jks` en lieu sûr !

### **Étape 2 : Configurer key.properties**

Créez `android/key.properties` :

```properties
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE
keyAlias=upload
storeFile=upload-keystore.jks
```

⚠️ Ajoutez à `.gitignore` :

```gitignore
# Fichiers de signature
android/key.properties
android/app/upload-keystore.jks
```

### **Étape 3 : Configurer build.gradle.kts**

Vérifiez `android/app/build.gradle.kts` :

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Charger key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.salamagri.salam"
    compileSdk = 34
    ndkVersion = "25.1.8937393"

    defaultConfig {
        applicationId = "com.salamagri.salam"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode()
        versionName = flutter.versionName()
    }

    // Configuration de signature
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### **Étape 4 : Créer proguard-rules.pro**

Créez `android/app/proguard-rules.pro` :

```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# PostgreSQL
-keep class org.postgresql.** { *; }
-dontwarn org.postgresql.**

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
```

### **Étape 5 : Build APK**

```powershell
# Build APK signé
flutter build apk --release

# Emplacement du fichier :
# build/app/outputs/flutter-apk/app-release.apk
```

### **Étape 6 : Build App Bundle (Pour Play Store)**

```powershell
# Build AAB (Recommandé pour Play Store)
flutter build appbundle --release

# Emplacement du fichier :
# build/app/outputs/bundle/release/app-release.aab
```

### **Étape 7 : Vérifier la Signature**

```powershell
# Vérifier APK
cd build/app/outputs/flutter-apk
keytool -printcert -jarfile app-release.apk

# Vérifier AAB
cd build/app/outputs/bundle/release
jarsigner -verify -verbose -certs app-release.aab
```

---

## 🍎 Build iOS

### **Prérequis**

- macOS avec Xcode installé
- Compte Apple Developer (99$/an)
- Certificats de signature configurés

### **Étape 1 : Ouvrir dans Xcode**

```bash
open ios/Runner.xcworkspace
```

### **Étape 2 : Configurer Signing**

Dans Xcode :

1. Sélectionnez **Runner** dans le navigateur
2. Onglet **Signing & Capabilities**
3. Cochez **Automatically manage signing**
4. Sélectionnez votre **Team** (Apple Developer)
5. Vérifiez le **Bundle Identifier** : `com.salamagri.salam`

### **Étape 3 : Sélectionner le Device**

Dans Xcode :
- Barre du haut : Sélectionnez **Any iOS Device (arm64)**

### **Étape 4 : Build Archive**

```bash
# Via Flutter (recommandé)
flutter build ipa --release

# OU via Xcode
# Product → Archive
```

### **Étape 5 : Upload vers App Store Connect**

Dans Xcode :
1. **Window** → **Organizer**
2. Sélectionnez votre archive
3. Click **Distribute App**
4. Choisissez **App Store Connect**
5. Suivez l'assistant

---

## 🧪 Tests Avant Publication

### **1. Tests Fonctionnels**

Vérifiez sur un appareil physique :

- [ ] Inscription / Connexion
- [ ] Navigation entre écrans
- [ ] Ajout d'équipement aux favoris
- [ ] Création de commande
- [ ] Chat fonctionnel
- [ ] Notifications reçues
- [ ] Géolocalisation
- [ ] Upload d'images
- [ ] Partage
- [ ] Déconnexion

### **2. Tests de Performance**

```powershell
# Profiler l'application
flutter run --profile

# Analyser la taille
flutter build apk --analyze-size
flutter build appbundle --analyze-size
```

### **3. Tests de Compatibilité**

Testez sur :
- [ ] Android 5.0 (minSdk 21)
- [ ] Android 10
- [ ] Android 13/14 (dernières versions)
- [ ] iOS 12+ (si applicable)
- [ ] Tablettes (optionnel)

---

## 📊 Analyse du Build

### **Taille de l'Application**

```powershell
# Analyser APK
flutter build apk --release --analyze-size

# Analyser AAB
flutter build appbundle --release --analyze-size
```

**Tailles typiques acceptables** :
- APK : 15-50 MB
- AAB : 10-30 MB (après compression Play Store)

### **Réduire la Taille**

Si trop volumineux :

1. **Activer la compression** (déjà fait avec ProGuard)
2. **Supprimer assets inutilisés**
3. **Optimiser les images**
4. **Utiliser WebP au lieu de PNG**

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/  # Uniquement ce qui est utilisé
```

---

## 📦 Structure des Fichiers de Release

```
build/
├── app/
│   └── outputs/
│       ├── flutter-apk/
│       │   └── app-release.apk        # ✅ APK signé
│       └── bundle/
│           └── release/
│               └── app-release.aab    # ✅ App Bundle
│
└── ios/
    └── ipa/
        └── salam.ipa                  # ✅ IPA iOS
```

---

## 🚀 Publication Play Store

### **1. Créer une Application**

1. Allez sur [Play Console](https://play.google.com/console)
2. **Créer une application**
3. Remplissez les informations :
   - Nom : **SALAM**
   - Langue par défaut : **Français**
   - Application / Jeu : **Application**
   - Gratuite / Payante : **Gratuite**

### **2. Remplir la Fiche Store**

**Page principale** :
- Titre : SALAM - Location Agricole
- Brève description (80 caractères max)
- Description complète (4000 caractères max)

**Assets graphiques** :
- Icône : 512x512 PNG
- Bannière : 1024x500 JPG
- Captures d'écran téléphone : min 2 (1080x1920)
- Captures d'écran tablette : optionnel

**Catégorisation** :
- Application : **Business** ou **Productivité**
- Tags : Agriculture, Location, Sénégal

**Coordonnées** :
- Email : dapy@gmail.com
- Téléphone : +221 707 45 87

### **3. Configurer la Version**

**Production** → **Créer une version** :

1. Upload `app-release.aab`
2. Nom de la version : `1.0.0 (1)`
3. Notes de version (en français) :

```
🎉 Première version de SALAM !

✨ Fonctionnalités :
- Location d'équipements agricoles
- Chat avec les propriétaires
- Géolocalisation des équipements
- Favoris et notifications
- Profil utilisateur complet

📧 Support : dapy@gmail.com
```

### **4. Formulaire de Contenu**

Remplissez :
- [ ] Déclaration de contenu
- [ ] Classification (PEGI, ESRB)
- [ ] Public cible
- [ ] Politique de confidentialité (URL requise)

### **5. Soumettre pour Examen**

1. Vérifiez tous les éléments
2. Click **Envoyer pour examen**
3. Délai : 1-7 jours

---

## 🍎 Publication App Store

### **1. Créer une Application**

1. Allez sur [App Store Connect](https://appstoreconnect.apple.com)
2. **Mes apps** → **+** → **Nouvelle app**
3. Remplissez :
   - Plateformes : iOS
   - Nom : SALAM
   - Langue principale : Français
   - Bundle ID : com.salamagri.salam
   - SKU : SALAM-001

### **2. Informations sur l'App**

**Page principale** :
- Nom : SALAM - Location Agricole
- Sous-titre (30 caractères)
- Description (4000 caractères max)
- Mots-clés : agriculture,location,senegal,equipement

**Captures d'écran** :
- iPhone 6.7" : min 3 (1284x2778)
- iPhone 6.5" : min 3 (1242x2688)
- iPad Pro 12.9" : optionnel

**Icône** : 1024x1024 PNG

**Catégorie** : Business ou Productivité

### **3. Configurer la Build**

1. Upload via Xcode Organizer (voir étape iOS)
2. Sélectionnez la build dans App Store Connect
3. Notes de version

### **4. Informations Légales**

- [ ] Politique de confidentialité (URL)
- [ ] Accord de licence (optionnel)
- [ ] Classification

### **5. Soumettre**

1. Click **Soumettre pour examen**
2. Délai : 1-3 jours

---

## ✅ Checklist Finale

Avant de soumettre :

### **Code**
- [ ] Version incrémentée dans pubspec.yaml
- [ ] Toutes les fonctionnalités testées
- [ ] Pas d'erreurs de console
- [ ] Permissions configurées correctement
- [ ] URLs de production configurées

### **Assets**
- [ ] Icônes générées (toutes tailles)
- [ ] Splash screens configurés
- [ ] Captures d'écran prises (min 2)
- [ ] Bannière Play Store (1024x500)
- [ ] Icône haute résolution (512x512 / 1024x1024)

### **Signature**
- [ ] Keystore Android créé et sauvegardé
- [ ] key.properties configuré
- [ ] Certificats iOS configurés (si applicable)
- [ ] Builds signés vérifiés

### **Stores**
- [ ] Compte développeur actif
- [ ] Fiche store complète
- [ ] Description et captures cohérentes
- [ ] Politique de confidentialité publiée
- [ ] Contact support renseigné

### **Tests**
- [ ] Testé sur Android physique
- [ ] Testé sur iOS physique (si applicable)
- [ ] Testé sur différentes versions d'OS
- [ ] Performance acceptable
- [ ] Taille d'app raisonnable (<50MB)

---

## 🔄 Mises à Jour Futures

Pour chaque nouvelle version :

1. **Incrémenter la version**

```yaml
# pubspec.yaml
version: 1.0.1+2  # Version name + Version code
```

2. **Build et test**

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

3. **Upload sur Play Store / App Store**

4. **Notes de version claires** :

```
📱 Version 1.0.1

🐛 Corrections :
- Correction du bug de connexion
- Amélioration de la vitesse

✨ Nouveautés :
- Nouveau design de profil
- Support des tablettes
```

---

## 📞 Support

**Développeur** : Adama Kâ  
**Email** : dapy@gmail.com  
**Téléphone** : +221 707 45 87

---

## 📚 Ressources

- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

---

**🎉 Bon déploiement avec SALAM !**
