# 🔐 Guide de Signature Android - SALAM

## 📋 Création du Keystore

### 1. **Créer le Keystore**

Ouvrez PowerShell et exécutez :

```powershell
keytool -genkey -v -keystore C:\Users\USER\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Ou placer dans le dossier du projet :
keytool -genkey -v -keystore .\android\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Questions posées :**
- Mot de passe du keystore : `[CHOISIR UN MOT DE PASSE FORT]`
- Nom et prénom : `SALAM Team`
- Nom de l'organisation : `SALAM Agri`
- Ville : `Dakar`
- État/Province : `Dakar`
- Code pays (2 lettres) : `SN`

**⚠️ IMPORTANT : Sauvegardez ces informations en lieu sûr !**

---

## 📝 Configuration du Keystore

### 2. **Créer le fichier `key.properties`**

Créez `android/key.properties` :

```properties
storePassword=[VOTRE_MOT_DE_PASSE]
keyPassword=[VOTRE_MOT_DE_PASSE]
keyAlias=upload
storeFile=C:/Users/USER/upload-keystore.jks
# Ou si dans le projet :
# storeFile=../app/upload-keystore.jks
```

**⚠️ Ne JAMAIS commiter ce fichier dans Git !**

---

### 3. **Configurer `build.gradle.kts`**

Le fichier `android/app/build.gradle.kts` doit contenir :

```kotlin
// Au début du fichier, après les plugins
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... configuration existante ...

    // Ajouter avant buildTypes
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword = keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            
            // Réduire la taille de l'APK
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

---

### 4. **Mettre à jour `.gitignore`**

Assurez-vous que `.gitignore` contient :

```
# Fichiers de signature Android
*.jks
*.keystore
key.properties
android/key.properties
```

---

## 🏗️ Build APK Signé

### **APK Release (pour tests)**

```powershell
flutter build apk --release
```

📦 **Sortie** : `build/app/outputs/flutter-apk/app-release.apk`

### **App Bundle (pour Play Store)**

```powershell
flutter build appbundle --release
```

📦 **Sortie** : `build/app/outputs/bundle/release/app-release.aab`

---

## 📱 Formats de Distribution

### **APK vs AAB**

| Format | Usage | Taille | Compatibilité |
|--------|-------|--------|---------------|
| **APK** | Distribution directe, tests | Plus grande | Tous appareils |
| **AAB** | Google Play Store | Optimisée | Play Store uniquement |

**Recommandation** : Utilisez AAB pour Play Store, APK pour tests manuels

---

## ✅ Vérification de la Signature

### Vérifier l'APK signé

```powershell
# Extraire les infos de signature
keytool -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk

# Vérifier avec apksigner (Android SDK requis)
apksigner verify --verbose build\app\outputs\flutter-apk\app-release.apk
```

---

## 📤 Upload sur Play Store

### Étapes :

1. **Créer un compte développeur**
   - https://play.google.com/console
   - Frais unique : $25 USD

2. **Créer une nouvelle application**
   - Nom : SALAM
   - Langue par défaut : Français
   - Type : Application
   - Gratuite/Payante : Gratuite

3. **Remplir le contenu du store**
   - Description courte (80 caractères max)
   - Description complète (4000 caractères max)
   - Captures d'écran (min 2, format 16:9)
   - Icône haute résolution (512x512 px)
   - Bannière (1024x500 px)

4. **Informations techniques**
   - Catégorie : Productivité / Outils
   - Tags : agriculture, location, équipement
   - Public cible : Tous publics
   - Politique de confidentialité : [VOTRE URL]

5. **Upload de l'App Bundle**
   - Aller dans "Production" → "Créer une version"
   - Upload `app-release.aab`
   - Notes de version
   - Soumettre pour révision

### Temps de révision : 1-7 jours

---

## 🔒 Sécurité du Keystore

### **Sauvegardes Essentielles**

1. **Keystore file** (`.jks`)
2. **key.properties** (mots de passe)
3. **Informations d'identité**

⚠️ **Si vous perdez le keystore, vous NE POURREZ PLUS mettre à jour votre app !**

### **Où sauvegarder**

- ✅ Cloud sécurisé (Drive crypté, AWS S3)
- ✅ Disque dur externe
- ✅ Gestionnaire de mots de passe
- ❌ Dépôt Git public

---

## 🐛 Troubleshooting

### **Erreur : "keystore not found"**

Vérifiez le chemin dans `key.properties` :
```properties
# Windows
storeFile=C:/Users/USER/upload-keystore.jks

# Relatif au projet
storeFile=../app/upload-keystore.jks
```

### **Erreur : "incorrect keystore password"**

Recréez le keystore avec le bon mot de passe.

### **APK trop grande**

Activez le shrinking :
```kotlin
isMinifyEnabled = true
isShrinkResources = true
```

---

## 📊 Tailles Recommandées

| Version | Taille Max Recommandée |
|---------|------------------------|
| APK | < 100 MB |
| AAB | < 150 MB |
| Download (après optimisation Play Store) | < 50 MB |

---

## 🚀 Checklist Finale

Avant de publier :

- [ ] Keystore créé et sauvegardé
- [ ] `key.properties` configuré
- [ ] `.gitignore` mis à jour
- [ ] APK/AAB build avec succès
- [ ] Signature vérifiée
- [ ] Tests sur plusieurs appareils
- [ ] Icônes et assets configurés
- [ ] Descriptions et captures d'écran prêtes
- [ ] Politique de confidentialité publiée
- [ ] Compte développeur Play Store actif

---

## 📞 Support

Pour toute question :
- Email : dapy@gmail.com
- Tel : +221 707 45 87

---

**✨ Bonne chance avec votre publication sur Play Store !**
