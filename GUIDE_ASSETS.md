# 🎨 Guide des Assets - SALAM

## 📱 Icônes d'Application

### **Exigences**

| Plateforme | Tailles Requises | Format |
|------------|------------------|---------|
| **Android** | 192x192, 144x144, 96x96, 72x72, 48x48 | PNG |
| **iOS** | 1024x1024 (App Store), 180x180, 120x120, 87x87, 80x80, 76x76, 60x60, 58x58, 40x40, 29x29, 20x20 | PNG |
| **Adaptive (Android)** | 432x432 (foreground + background) | PNG/XML |

---

## 🛠️ Génération Automatique des Icônes

### **Option 1 : flutter_launcher_icons (Recommandé)**

#### 1. Installer le package

Ajoutez à `pubspec.yaml` :

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"  # Votre icône 1024x1024
  min_sdk_android: 21
  
  # Adaptive icon pour Android (optionnel)
  adaptive_icon_background: "#4CAF50"  # Ou chemin vers image
  adaptive_icon_foreground: "assets/icons/foreground.png"
  
  # Configuration web (optionnel)
  web:
    generate: true
    image_path: "assets/icons/app_icon.png"
    background_color: "#4CAF50"
    theme_color: "#4CAF50"
```

#### 2. Préparer votre icône

Créez une icône **1024x1024 px** :
- Format : PNG avec transparence
- Design : Simple, reconnaissable
- Marges : Laissez 10% d'espace autour
- Couleurs : Cohérentes avec votre marque

**Recommandation pour SALAM** :
- Icône : Symbole agricole (tracteur, plant, épi de blé)
- Couleur principale : Vert (#4CAF50)
- Style : Flat design moderne

#### 3. Générer les icônes

```powershell
flutter pub get
flutter pub run flutter_launcher_icons
```

✅ Les icônes seront automatiquement créées pour toutes les tailles !

---

### **Option 2 : Outils en Ligne**

1. **AppIcon.co** (Gratuit)
   - Upload votre icône 1024x1024
   - Télécharge un ZIP avec toutes les tailles
   - https://appicon.co/

2. **MakeAppIcon** (Gratuit)
   - Génère pour iOS, Android, et autres
   - https://makeappicon.com/

3. **Icon Kitchen** (Android Studio)
   - Intégré dans Android Studio
   - Tools → Image Asset Studio

---

## 🎨 Splash Screen (Écran de Démarrage)

### **Configuration Native**

#### **Android**

1. **Créer le drawable**

`android/app/src/main/res/drawable/launch_background.xml` :

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Couleur de fond -->
    <item android:drawable="@color/splash_background"/>
    
    <!-- Logo centré -->
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_logo"/>
    </item>
</layer-list>
```

2. **Définir les couleurs**

`android/app/src/main/res/values/colors.xml` :

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_background">#4CAF50</color>
</resources>
```

3. **Ajouter le logo**

Placez votre logo dans :
- `android/app/src/main/res/drawable-hdpi/splash_logo.png` (432x432)
- `android/app/src/main/res/drawable-mdpi/splash_logo.png` (288x288)
- `android/app/src/main/res/drawable-xhdpi/splash_logo.png` (576x576)
- `android/app/src/main/res/drawable-xxhdpi/splash_logo.png` (864x864)
- `android/app/src/main/res/drawable-xxxhdpi/splash_logo.png` (1152x1152)

#### **iOS**

1. **Utiliser Xcode**

Ouvrez `ios/Runner.xcworkspace` dans Xcode :
- Sélectionnez `Runner` → `Assets.xcassets`
- Click droit → New Image Set → Nommez "SplashLogo"
- Drag & drop vos images (1x, 2x, 3x)

2. **Configurer LaunchScreen.storyboard**

Dans Xcode :
- Ouvrez `LaunchScreen.storyboard`
- Ajoutez une Image View
- Définissez l'image sur "SplashLogo"
- Centrez et contraignez

---

### **Package flutter_native_splash (Automatique)**

#### 1. Installation

```yaml
dev_dependencies:
  flutter_native_splash: ^2.3.10

flutter_native_splash:
  color: "#4CAF50"
  image: assets/icons/splash_logo.png
  
  android: true
  ios: true
  web: true
  
  android_12:
    color: "#4CAF50"
    image: assets/icons/splash_logo.png
```

#### 2. Génération

```powershell
flutter pub get
flutter pub run flutter_native_splash:create
```

✅ Splash screens créés automatiquement !

---

## 📐 Dimensions Recommandées

### **Icône Principale**
- **Taille source** : 1024x1024 px
- **Format** : PNG avec transparence
- **Zone de sécurité** : 924x924 px (marges de 50px)

### **Splash Logo**
- **Taille source** : 1152x1152 px
- **Format** : PNG avec transparence
- **Rapport** : Carré ou légèrement rectangulaire

### **Captures d'Écran (Play Store/App Store)**

| Type | Dimensions | Quantité |
|------|-----------|----------|
| **Téléphone** | 1080x1920 ou 1080x2340 | 2-8 |
| **Tablette 7"** | 1200x1920 | 1-8 (optionnel) |
| **Tablette 10"** | 1600x2560 | 1-8 (optionnel) |
| **Bannière** | 1024x500 (Play Store) | 1 |
| **Icon Store** | 512x512 (Play Store), 1024x1024 (App Store) | 1 |

---

## 🎨 Conseils de Design

### **Icône d'Application**

✅ **À faire** :
- Design simple et reconnaissable
- Utiliser 2-3 couleurs maximum
- Éviter les détails fins
- Tester en petite taille (48x48)
- Assurer un bon contraste

❌ **À éviter** :
- Texte trop petit
- Dégradés complexes
- Photos réalistes
- Bordures épaisses
- Trop de détails

### **Splash Screen**

✅ **À faire** :
- Affichage instantané (<1 sec)
- Design cohérent avec l'app
- Centré et simple
- Fond uni ou dégradé simple

❌ **À éviter** :
- Animations complexes
- Texte long
- Images lourdes
- Logos trop détaillés

---

## 📦 Structure des Fichiers

```
android/app/src/main/res/
├── mipmap-hdpi/
│   └── ic_launcher.png (72x72)
├── mipmap-mdpi/
│   └── ic_launcher.png (48x48)
├── mipmap-xhdpi/
│   └── ic_launcher.png (96x96)
├── mipmap-xxhdpi/
│   └── ic_launcher.png (144x144)
├── mipmap-xxxhdpi/
│   └── ic_launcher.png (192x192)
├── drawable/
│   ├── launch_background.xml
│   └── splash_logo.png
└── values/
    └── colors.xml

ios/Runner/Assets.xcassets/
├── AppIcon.appiconset/
│   ├── Icon-App-20x20@1x.png
│   ├── Icon-App-20x20@2x.png
│   ├── ... (toutes les tailles)
│   └── Contents.json
└── LaunchImage.imageset/
    ├── LaunchImage.png
    ├── LaunchImage@2x.png
    ├── LaunchImage@3x.png
    └── Contents.json
```

---

## 🚀 Workflow Complet

### **1. Préparer les Assets**

```powershell
# Créer les dossiers
New-Item -ItemType Directory -Force -Path "assets/icons"
New-Item -ItemType Directory -Force -Path "assets/images"

# Placer vos fichiers
# - assets/icons/app_icon.png (1024x1024)
# - assets/icons/splash_logo.png (1152x1152)
```

### **2. Configurer pubspec.yaml**

```yaml
flutter:
  assets:
    - assets/icons/
    - assets/images/

dev_dependencies:
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.10

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"

flutter_native_splash:
  color: "#4CAF50"
  image: assets/icons/splash_logo.png
  android: true
  ios: true
```

### **3. Générer**

```powershell
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

### **4. Vérifier**

```powershell
# Tester sur émulateur
flutter run

# Build et vérifier
flutter build apk --release
```

---

## 🎯 Checklist Assets

Avant de publier :

- [ ] Icône 1024x1024 créée
- [ ] Splash logo 1152x1152 créé
- [ ] Icônes générées pour Android (toutes tailles)
- [ ] Icônes générées pour iOS (toutes tailles)
- [ ] Splash screen configuré Android
- [ ] Splash screen configuré iOS
- [ ] Captures d'écran prises (min 2)
- [ ] Bannière Play Store créée (1024x500)
- [ ] Icône haute résolution Play Store (512x512)
- [ ] Icône App Store (1024x1024)
- [ ] Testé sur plusieurs appareils
- [ ] Testé sur différentes tailles d'écran

---

## 🛠️ Outils Recommandés

### **Design**
- **Figma** (Gratuit) - Design UI/UX
- **Canva** (Gratuit) - Templates icônes
- **Adobe Illustrator** (Payant) - Design vectoriel
- **Inkscape** (Gratuit) - Alternative à Illustrator

### **Génération Assets**
- **flutter_launcher_icons** - Icônes multi-plateformes
- **flutter_native_splash** - Splash screens
- **AppIcon.co** - Génération en ligne
- **Android Asset Studio** - Outils Google

### **Captures d'Écran**
- **Shotty** (macOS) - Annotations
- **Screely** - Mockups navigateur
- **MockUPhone** - Mockups téléphones
- **Previewed** - Templates marketing

---

## 📞 Support

Pour toute question :
- Email : dapy@gmail.com
- Tel : +221 707 45 87

---

**✨ Créez des assets professionnels pour SALAM !**
