# 📸 Préparation des Images Sources - SALAM

## 🎯 Images Nécessaires

Vous devez créer **3 images** avant de générer les assets :

| Fichier | Emplacement | Dimensions | Usage |
|---------|-------------|------------|-------|
| **app_icon.png** | `assets/icons/` | 1024x1024 px | Icône principale de l'app |
| **foreground.png** | `assets/icons/` | 432x432 px | Icône adaptative Android (premier plan) |
| **splash_logo.png** | `assets/icons/` | 1152x1152 px | Logo du splash screen |

---

## 🎨 Spécifications Détaillées

### **1. app_icon.png** (Icône Principale)

**Dimensions** : 1024x1024 px  
**Format** : PNG avec transparence  
**Zone de sécurité** : Laissez 50px de marge (924x924 px pour le contenu)

**Recommandations pour SALAM** :
- Symbole agricole simple (tracteur, plant, épi de blé)
- Fond transparent ou vert (#4CAF50)
- Design flat moderne
- Lisible en petite taille (48x48)
- Maximum 2-3 couleurs

**Exemple de design** :
```
┌────────────────┐
│  🌾           │  Marge 50px
│     ┌────┐    │
│     │ICON│    │  Contenu 924x924
│     └────┘    │
│   "SALAM"     │  Texte optionnel
└────────────────┘
```

---

### **2. foreground.png** (Android Adaptive Icon)

**Dimensions** : 432x432 px  
**Format** : PNG avec transparence  
**Zone de sécurité** : 288x288 px centrée (72px de marge)

**Important** :
- Doit être centré dans l'image
- Peut être rogné en cercle, carré arrondi, ou autre forme
- Pas de texte près des bords
- Contenu principal au centre

**Astuce** : Vous pouvez réutiliser `app_icon.png` redimensionné à 432x432

---

### **3. splash_logo.png** (Splash Screen)

**Dimensions** : 1152x1152 px  
**Format** : PNG avec transparence  
**Style** : Logo simple et reconnaissable

**Recommandations** :
- Plus simple que l'icône d'app
- Fond transparent (la couleur #4CAF50 sera appliquée)
- Pas de texte détaillé
- Lisible instantanément

**Durée d'affichage** : <1 seconde, donc design très simple !

---

## 🛠️ Outils pour Créer les Images

### **Option 1 : Canva (Recommandé pour non-designers)**

1. Allez sur [canva.com](https://www.canva.com)
2. Créez un design personnalisé 1024x1024
3. Cherchez "agriculture icons" ou "farm icons"
4. Ajoutez le texte "SALAM" (optionnel)
5. Téléchargez en PNG avec fond transparent

### **Option 2 : Figma (Pour designers)**

1. Créez un frame 1024x1024
2. Dessinez votre icône
3. Exportez en PNG @2x

### **Option 3 : Adobe Illustrator / Inkscape**

1. Créez un document 1024x1024
2. Design vectoriel
3. Exportez en PNG

### **Option 4 : Générateur IA**

Utilisez DALL-E, Midjourney, ou Stable Diffusion avec ce prompt :

```
Simple flat design app icon for agricultural equipment rental app called SALAM,
green color #4CAF50, minimalist, wheat or tractor symbol, 1024x1024, 
transparent background, modern style
```

---

## 📐 Template Couleurs SALAM

### **Palette Principale**

```css
/* Vert Principal */
#4CAF50  rgb(76, 175, 80)

/* Vert Foncé (ombres) */
#388E3C  rgb(56, 142, 60)

/* Vert Clair (highlights) */
#81C784  rgb(129, 199, 132)

/* Blanc (texte sur vert) */
#FFFFFF  rgb(255, 255, 255)

/* Gris Foncé (texte) */
#212121  rgb(33, 33, 33)
```

---

## 📁 Structure des Fichiers

Créez cette structure avant de générer les assets :

```
assets/
├── icons/
│   ├── app_icon.png          ← 1024x1024 (À CRÉER)
│   ├── foreground.png         ← 432x432 (À CRÉER)
│   └── splash_logo.png        ← 1152x1152 (À CRÉER)
└── images/
    └── logo.jpg               ← Existant
```

---

## ✅ Checklist Avant Génération

Avant d'exécuter les commandes de génération, vérifiez :

- [ ] Dossier `assets/icons/` créé
- [ ] Fichier `app_icon.png` (1024x1024) créé
- [ ] Fichier `foreground.png` (432x432) créé
- [ ] Fichier `splash_logo.png` (1152x1152) créé
- [ ] Tous les PNG ont un fond transparent
- [ ] Les dimensions sont exactes
- [ ] Les images sont nettes (pas floues)
- [ ] Le design est lisible en petite taille

---

## 🚀 Commandes de Génération

Une fois les images prêtes, exécutez :

```powershell
# 1. Installer les dépendances
flutter pub get

# 2. Générer les icônes d'application
flutter pub run flutter_launcher_icons

# 3. Générer les splash screens
flutter pub run flutter_native_splash:create

# 4. Vérifier le résultat
flutter run
```

---

## 📊 Résultat Attendu

Après génération, vous aurez :

### **Android**
```
android/app/src/main/res/
├── mipmap-hdpi/ic_launcher.png (72x72)
├── mipmap-mdpi/ic_launcher.png (48x48)
├── mipmap-xhdpi/ic_launcher.png (96x96)
├── mipmap-xxhdpi/ic_launcher.png (144x144)
├── mipmap-xxxhdpi/ic_launcher.png (192x192)
└── drawable/
    ├── launch_background.xml
    └── splash.png
```

### **iOS**
```
ios/Runner/Assets.xcassets/
├── AppIcon.appiconset/
│   ├── Icon-App-20x20@1x.png
│   ├── Icon-App-20x20@2x.png
│   └── ... (toutes les tailles)
└── LaunchImage.imageset/
    ├── LaunchImage.png
    ├── LaunchImage@2x.png
    └── LaunchImage@3x.png
```

---

## 🎨 Exemples de Design

### **Style Minimaliste** (Recommandé)
- Fond vert (#4CAF50)
- Icône blanche simple au centre
- Pas de texte ou texte très court

### **Style Moderne**
- Fond transparent
- Dégradé de vert
- Icône en flat design

### **Style Agricole**
- Symboles : 🌾 épi de blé, 🚜 tracteur, 🌱 plant
- Couleurs : Verts naturels
- Formes arrondies

---

## 💡 Conseils Pratiques

### ✅ À Faire
- Testez l'icône en 48x48 pour vérifier la lisibilité
- Utilisez des formes simples et reconnaissables
- Gardez un bon contraste
- Exportez en haute qualité

### ❌ À Éviter
- Photos réalistes (trop détaillées)
- Texte trop petit
- Trop de couleurs
- Dégradés complexes
- Ombres portées fortes

---

## 🔄 Si Vous N'avez Pas de Designer

### **Solution Rapide**

Utilisez temporairement le logo existant :

```powershell
# Copier le logo existant
Copy-Item "assets/images/logo.jpg" "assets/icons/app_icon.png"
Copy-Item "assets/images/logo.jpg" "assets/icons/foreground.png"
Copy-Item "assets/images/logo.jpg" "assets/icons/splash_logo.png"
```

⚠️ **Note** : Les JPG n'ont pas de transparence. Convertissez en PNG si possible.

### **Services de Design Abordables**

1. **Fiverr** : À partir de 5€
2. **Upwork** : Freelancers à partir de 10€
3. **99designs** : Concours de design
4. **Canva Pro** : Templates premium

---

## 📞 Besoin d'Aide ?

Si vous avez besoin d'aide pour créer les images :

**Contact** : dapy@gmail.com  
**Tel** : +221 707 45 87

---

## 🎯 Prochaine Étape

Une fois les images créées :

1. ✅ Placez-les dans `assets/icons/`
2. ✅ Vérifiez les dimensions
3. ✅ Exécutez `flutter pub get`
4. ✅ Lancez `flutter pub run flutter_launcher_icons`
5. ✅ Lancez `flutter pub run flutter_native_splash:create`

**📌 Référez-vous à `GUIDE_ASSETS.md` pour plus de détails !**
