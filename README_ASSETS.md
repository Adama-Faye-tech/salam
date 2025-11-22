# 🎨 Guide Rapide : Génération des Assets

## ✅ Configuration Terminée !

Le fichier `pubspec.yaml` a été configuré avec :
- ✅ `flutter_launcher_icons` pour les icônes
- ✅ `flutter_native_splash` pour les splash screens
- ✅ Couleur verte SALAM (#4CAF50)
- ✅ Configuration Android 12+
- ✅ Support iOS, Android, et Web

---

## 📋 Ce qu'il Vous Faut Maintenant

Avant de générer les assets, vous devez créer **3 images** :

| Fichier | Taille | Description |
|---------|--------|-------------|
| `assets/icons/app_icon.png` | 1024x1024 | Icône principale de l'app |
| `assets/icons/foreground.png` | 432x432 | Icône adaptative Android |
| `assets/icons/splash_logo.png` | 1152x1152 | Logo du splash screen |

**📖 Consultez `PREPARATION_IMAGES.md` pour les spécifications détaillées !**

---

## 🚀 Méthode Rapide (Recommandée)

### **Option 1 : Utiliser le Script Automatique**

```powershell
# Exécuter le script PowerShell
.\generer_assets.ps1
```

Le script va :
1. ✅ Vérifier que Flutter est installé
2. ✅ Vérifier que les images existent
3. ✅ Proposer d'utiliser temporairement logo.jpg si images manquantes
4. ✅ Nettoyer le projet
5. ✅ Installer les dépendances
6. ✅ Générer toutes les icônes
7. ✅ Générer tous les splash screens

---

### **Option 2 : Commandes Manuelles**

Si vous préférez exécuter les commandes une par une :

```powershell
# 1. Nettoyer le projet
flutter clean

# 2. Installer les dépendances
flutter pub get

# 3. Générer les icônes
flutter pub run flutter_launcher_icons

# 4. Générer les splash screens
flutter pub run flutter_native_splash:create

# 5. Tester
flutter run
```

---

## 🎨 Vous N'avez Pas d'Images Encore ?

### **Solution Temporaire**

Utilisez le logo existant pour tester :

```powershell
# Copier le logo existant
Copy-Item "assets/images/logo.jpg" "assets/icons/app_icon.png"
Copy-Item "assets/images/logo.jpg" "assets/icons/foreground.png"
Copy-Item "assets/images/logo.jpg" "assets/icons/splash_logo.png"

# Puis générer
.\generer_assets.ps1
```

⚠️ **Note** : Remplacez ces fichiers JPG par de vrais PNG avec transparence avant la production !

---

### **Créer Vos Images**

**Outils Recommandés** :

1. **Canva** (Gratuit) - <https://www.canva.com>
   - Template "Logo" 1024x1024
   - Cherchez "agriculture icon"
   - Téléchargez en PNG transparent

2. **Figma** (Gratuit) - <https://www.figma.com>
   - Créez un frame 1024x1024
   - Design simple avec vert #4CAF50
   - Exportez en PNG @2x

3. **IA Générative** (DALL-E, Midjourney)
   ```
   Prompt: "Simple flat design app icon for agricultural 
   equipment rental, green #4CAF50, wheat symbol, 
   1024x1024, transparent background, minimalist"
   ```

---

## ✅ Vérification

Après génération, vérifiez que ces fichiers ont été créés :

### **Android**
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `android/app/src/main/res/drawable/launch_background.xml`

### **iOS**
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (plusieurs fichiers)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/` (plusieurs fichiers)

---

## 🧪 Tester

```powershell
# Lancer l'app
flutter run

# Sur émulateur Android
flutter run -d emulator-5554

# Sur appareil physique Android
flutter run -d <device-id>
```

Vérifiez :
- ✅ L'icône apparaît correctement sur l'écran d'accueil
- ✅ Le splash screen s'affiche au démarrage
- ✅ Les couleurs sont correctes (vert #4CAF50)
- ✅ L'icône est nette, pas floue

---

## 🔧 Problèmes Courants

### **Erreur : "Image not found"**

```powershell
# Solution : Vérifiez que les images existent
Get-ChildItem "assets/icons/"

# Créez-les si manquantes ou utilisez logo.jpg temporairement
```

### **Icônes Floues**

```
Solution : 
- Vérifiez que les images sources sont en haute résolution
- app_icon.png doit être exactement 1024x1024
- splash_logo.png doit être exactement 1152x1152
```

### **Splash Screen Ne S'affiche Pas**

```powershell
# Réinstallez l'app complètement
flutter clean
flutter pub get
flutter run --uninstall-first
```

---

## 📖 Documentation Complète

Pour plus de détails, consultez :

1. **PREPARATION_IMAGES.md** - Spécifications des images
2. **GUIDE_ASSETS.md** - Guide complet des assets
3. **GUIDE_BUILD_PRODUCTION.md** - Prochaine étape (build release)
4. **GUIDE_SIGNATURE_ANDROID.md** - Signature Android

---

## 🎯 Prochaine Étape

Une fois les assets générés et testés :

➡️ **Créer le Keystore Android** pour la signature

```powershell
# Voir GUIDE_SIGNATURE_ANDROID.md
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

---

## 📞 Support

**Développeur** : Adama Kâ  
**Email** : dapy@gmail.com  
**Tel** : +221 707 45 87

---

**✨ Bonne génération d'assets pour SALAM !**
