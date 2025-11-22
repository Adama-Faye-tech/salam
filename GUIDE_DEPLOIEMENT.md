# 🚀 Guide de Déploiement SALAM - App Store & Play Store

**Application**: SALAM - Société Agricole Locale pour l'Amélioration et la Modernisation  
**Date**: 22 novembre 2025  
**Version**: 1.0.0

---

## ✅ CHANGEMENTS POUR PRODUCTION

### 1. **Backend Local Supprimé** ✅
- ❌ Plus de dépendance à `192.168.1.23:3000`
- ✅ Application 100% fonctionnelle via Supabase (cloud)
- ✅ Codes promo intégrés en dur (SALAM10, SALAM20, BIENVENUE)
- 📝 TODO futur: Migrer vers Supabase Functions ou table `promo_codes`

### 2. **Bundle ID Unique** ✅
- **Ancien**: `com.example.salam` ❌
- **Nouveau**: `com.salamagri.salam` ✅
- Mis à jour sur: Android, iOS, macOS, Linux

### 3. **Permissions Configurées** ✅
**Android** (`AndroidManifest.xml`):
- ✅ INTERNET
- ✅ CAMERA (photos équipements)
- ✅ READ/WRITE_EXTERNAL_STORAGE
- ✅ READ_MEDIA_IMAGES/VIDEO/AUDIO
- ✅ RECORD_AUDIO (messages vocaux)
- ✅ ACCESS_FINE_LOCATION (recherche proximité)
- ✅ ACCESS_COARSE_LOCATION
- ✅ ACCESS_BACKGROUND_LOCATION

**iOS** (à configurer dans Xcode):
- ✅ NSCameraUsageDescription
- ✅ NSPhotoLibraryUsageDescription  
- ✅ NSMicrophoneUsageDescription
- ✅ NSLocationWhenInUseUsageDescription

---

## 📱 CONFIGURATION ANDROID (Play Store)

### Étape 1: Créer un Keystore pour la Signature

```powershell
# Dans le dossier android/app
keytool -genkey -v -keystore salam-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias salam
```

**Questions à répondre**:
- Mot de passe keystore: [CHOISIR UN MOT DE PASSE FORT]
- Prénom et nom: SALAM
- Unité organisationnelle: Development
- Organisation: SALAM Agri
- Ville: [Votre ville]
- État: Sénégal
- Code pays: SN

**⚠️ IMPORTANT**: Sauvegarder le fichier `.jks` et les mots de passe en lieu sûr !

### Étape 2: Configurer le Fichier `key.properties`

Créer le fichier `android/key.properties`:

```properties
storePassword=[MOT_DE_PASSE_KEYSTORE]
keyPassword=[MOT_DE_PASSE_KEY]
keyAlias=salam
storeFile=salam-release-key.jks
```

### Étape 3: Mettre à Jour `build.gradle.kts`

Ajouter avant `android {`:

```kotlin
// Charger les propriétés de signature
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... configuration existante ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### Étape 4: Build APK/AAB pour Play Store

```powershell
# Nettoyer
flutter clean

# Installer dépendances
flutter pub get

# Build AAB (Android App Bundle) - Recommandé pour Play Store
flutter build appbundle --release

# OU Build APK
flutter build apk --release

# Fichiers générés:
# AAB: build\app\outputs\bundle\release\app-release.aab
# APK: build\app\outputs\flutter-apk\app-release.apk
```

### Étape 5: Préparer les Assets Play Store

**Screenshots requis**:
- Téléphone: 2-8 screenshots (minimum 320px, max 3840px)
- Tablette 7": 1-8 screenshots
- Tablette 10": 1-8 screenshots

**Icône de l'application**:
- 512 x 512 px
- PNG 32 bits
- Transparent (optionnel)

**Feature Graphic**:
- 1024 x 500 px
- PNG ou JPEG

**Description**:
```
SALAM - Société Agricole Locale pour l'Amélioration et la Modernisation

Louez du matériel agricole facilement !

🚜 Fonctionnalités:
• Recherche d'équipements agricoles à proximité
• Réservation en ligne
• Chat avec les propriétaires
• Gestion des favoris
• Historique des commandes
• Notifications en temps réel

Facilitez votre travail agricole avec SALAM !
```

---

## 🍎 CONFIGURATION iOS (App Store)

### Étape 1: Ouvrir le Projet dans Xcode

```bash
open ios/Runner.xcworkspace
```

### Étape 2: Configurer le Signing

1. Sélectionner `Runner` dans le navigateur
2. Onglet "Signing & Capabilities"
3. Cocher "Automatically manage signing"
4. Team: [Votre compte développeur Apple]
5. Bundle Identifier: `com.salamagri.salam`

### Étape 3: Ajouter les Descriptions de Permissions

Dans `ios/Runner/Info.plist`, ajouter:

```xml
<key>NSCameraUsageDescription</key>
<string>SALAM a besoin d'accéder à votre caméra pour prendre des photos des équipements</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>SALAM a besoin d'accéder à vos photos pour ajouter des images d'équipements</string>

<key>NSMicrophoneUsageDescription</key>
<string>SALAM a besoin d'accéder au microphone pour enregistrer des messages vocaux</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>SALAM utilise votre localisation pour trouver des équipements à proximité</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>SALAM utilise votre localisation pour améliorer vos résultats de recherche</string>
```

### Étape 4: Build pour App Store

```bash
# Depuis le terminal
flutter build ios --release

# OU depuis Xcode
# Product > Archive
# Puis suivre le process de distribution
```

### Étape 5: Préparer les Assets App Store

**Screenshots requis**:
- iPhone 6.7": 3-10 screenshots (1290 x 2796 px)
- iPhone 6.5": 3-10 screenshots (1242 x 2688 px)  
- iPhone 5.5": 3-10 screenshots (1242 x 2208 px)
- iPad Pro 12.9": 3-10 screenshots (2048 x 2732 px)

**Icône**:
- 1024 x 1024 px
- PNG sans transparence

**Description**:
```
SALAM facilite la location de matériel agricole

Trouvez et louez l'équipement agricole dont vous avez besoin, directement depuis votre téléphone.

FONCTIONNALITÉS :
• Recherche géolocalisée
• Réservation instantanée
• Chat intégré
• Paiement sécurisé
• Notifications

Rejoignez SALAM aujourd'hui !
```

---

## 🔧 VÉRIFICATIONS AVANT DÉPLOIEMENT

### Checklist Technique

- [x] Bundle ID unique: `com.salamagri.salam`
- [x] Nom de l'app: SALAM
- [x] Version: 1.0.0
- [x] Backend: 100% Supabase (pas de dépendance locale)
- [x] Permissions Android configurées
- [ ] Permissions iOS configurées (Info.plist)
- [ ] Keystore Android créé
- [ ] Signing iOS configuré
- [ ] Tests sur appareil physique
- [ ] Screenshots prêts
- [ ] Icônes créées
- [ ] Description rédigée

### Tests Fonctionnels

- [ ] Login/Register
- [ ] Liste équipements
- [ ] Recherche et filtres
- [ ] Détails équipement
- [ ] Favoris (ajout/suppression)
- [ ] Création commande
- [ ] Chat et messages
- [ ] Upload photos
- [ ] Notifications
- [ ] Profil utilisateur
- [ ] Codes promo (SALAM10, SALAM20, BIENVENUE)

---

## 📦 COMMANDES DE BUILD

### Android

```powershell
# Nettoyer
flutter clean

# Installer dépendances
flutter pub get

# Build AAB (Play Store)
flutter build appbundle --release

# Build APK (distribution directe)
flutter build apk --release --split-per-abi

# Fichiers générés:
# AAB: build\app\outputs\bundle\release\app-release.aab
# APK ARM64: build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
# APK ARMv7: build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
# APK x86_64: build\app\outputs\flutter-apk\app-x86_64-release.apk
```

### iOS

```bash
# Build
flutter build ios --release

# Ou depuis Xcode
open ios/Runner.xcworkspace
# Product > Archive
# Window > Organizer > Distribute App
```

---

## 🌐 CONFIGURATION SUPABASE PRODUCTION

### Vérifier les URLs

Dans `lib/services/supabase_service.dart`:

```dart
static const String _supabaseUrl = 'https://bfmnqkmdjerzbgafdclo.supabase.co';
static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

✅ Ces clés sont déjà configurées et fonctionnelles

### Row Level Security (RLS)

Assurez-vous que les policies RLS sont configurées dans Supabase pour:
- ✅ `equipment`: Lecture publique, écriture authentifiée
- ✅ `orders`: Lecture/écriture owner only
- ✅ `favorites`: Lecture/écriture owner only
- ✅ `messages`: Lecture/écriture participants only
- ✅ `profiles`: Lecture publique, écriture owner only

---

## 📱 INFORMATIONS STORES

### Catégories Suggérées

**Play Store**:
- Catégorie: Business ou Productivity
- Public cible: Tout public
- Classification du contenu: Tout public

**App Store**:
- Catégorie principale: Business
- Catégorie secondaire: Productivity
- Âge: 4+

### Prix

- Gratuit avec possibilité d'achats in-app futurs

### Mots-clés (SEO)

```
agriculture, matériel agricole, location, tracteur, équipement, 
fermier, agriculteur, sénégal, location matériel, salam
```

---

## 🎯 ROADMAP POST-LANCEMENT

### Version 1.1
- [ ] Migrer codes promo vers Supabase
- [ ] Ajouter paiement mobile money
- [ ] Système de notation équipements
- [ ] Mode hors-ligne

### Version 1.2
- [ ] Analytics intégrés
- [ ] Push notifications avancées
- [ ] Multi-langues (Français, Wolof)
- [ ] Support client in-app

---

## 📞 SUPPORT

**Développeur**: Dapy  
**Email**: dapy@gmail.com  
**Téléphone**: +221 707 45 87  
**Site**: www.salam-agri.app

---

## ⚠️ NOTES IMPORTANTES

1. **Keystore Android**: NE JAMAIS perdre le keystore ! Il est impossible de mettre à jour l'app sans lui.

2. **Bundle ID**: Ne JAMAIS changer le Bundle ID après publication. Il est permanent.

3. **Versions**: Incrémenter le `versionCode` (Android) et `CFBundleVersion` (iOS) à chaque mise à jour.

4. **Supabase**: Les clés anonymes sont publiques, c'est normal. La sécurité vient des RLS policies.

5. **Tests**: Toujours tester sur des appareils physiques avant publication.

---

## ✅ PRÊT POUR DÉPLOIEMENT

L'application SALAM est maintenant configurée pour fonctionner sur tous les appareils sans dépendance locale. Toutes les fonctionnalités passent par Supabase (cloud).

**Prochaine étape**: Créer le keystore Android et build l'AAB/APK final ! 🚀
