# 🌾 SALAM - Société Agricole Locale pour l'Amélioration et la Modernisation

<div align="center">

![SALAM Logo](assets/images/logo.jpg)

**Location d'Équipements Agricoles au Sénégal**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

</div>

---

## 📱 À Propos

**SALAM** est une application mobile Flutter qui facilite la **location d'équipements agricoles** entre agriculteurs au Sénégal.

### ✨ Fonctionnalités Principales

- 🚜 **Catalogue d'équipements** : Parcourez et recherchez des équipements agricoles
- 📍 **Géolocalisation** : Trouvez les équipements près de chez vous
- 💬 **Chat en temps réel** : Communiquez avec les propriétaires
- ⭐ **Favoris** : Sauvegardez vos équipements préférés
- 🔔 **Notifications** : Restez informé des nouveautés et messages
- 👤 **Profils utilisateurs** : Gestion complète de compte
- 📦 **Gestion des commandes** : Créez et suivez vos locations
- 📸 **Upload d'images** : Ajoutez des photos à vos équipements
- 🌍 **Multiplateforme** : Android, iOS, Web, Windows, macOS, Linux

---

## 🏗️ Architecture Technique

### **Stack Technologique**

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| **Frontend** | Flutter 3.10+ | Application mobile/desktop |
| **Backend** | Supabase | Base de données, auth, storage (95%) |
| **API Backend** | Node.js/Express | Codes promo uniquement (5%) |
| **Base de données** | PostgreSQL | Via Supabase |
| **État** | Provider | Gestion d'état |
| **Authentification** | Supabase Auth | Connexion/inscription |

### **Architecture**

```
┌─────────────────────────────────────────┐
│         Flutter App (SALAM)             │
│  ┌───────────┐  ┌──────────────────┐   │
│  │  Screens  │  │    Providers     │   │
│  └─────┬─────┘  └────────┬─────────┘   │
│        │                 │              │
│  ┌─────▼──────────────────▼─────────┐  │
│  │         Services Layer           │  │
│  │  • SupabaseService (95%)         │  │
│  │  • ApiService (5% - promos)      │  │
│  └─────┬──────────────────┬─────────┘  │
└────────┼──────────────────┼─────────────┘
         │                  │
         ▼                  ▼
  ┌──────────────┐   ┌──────────────┐
  │   Supabase   │   │  Node.js API │
  │              │   │  (Optional)  │
  │ • Auth       │   │ • Promos     │
  │ • Database   │   └──────────────┘
  │ • Storage    │
  │ • Realtime   │
  └──────────────┘
```

---

## 🚀 Démarrage Rapide

### **Prérequis**

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.10 ou supérieur
- [Git](https://git-scm.com/)
- Un compte [Supabase](https://supabase.com)
- (Optionnel) [Node.js](https://nodejs.org/) 18+ pour les codes promo

### **Installation**

```bash
# 1. Cloner le dépôt
git clone https://github.com/VOTRE_USERNAME/salam-app.git
cd salam-app

# 2. Installer les dépendances Flutter
flutter pub get

# 3. Configurer les variables d'environnement
cp .env.example .env
# Éditez .env avec vos clés Supabase

# 4. Lancer l'application
flutter run
```

### **Configuration Supabase**

1. Créez un projet sur [Supabase](https://app.supabase.com)
2. Copiez vos clés API dans `.env` :

```env
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=votre_cle_anonyme
```

3. Exécutez les migrations SQL (fichiers dans `/baol_api/migrations/`)

---

## 📦 Structure du Projet

```
baol/
├── lib/                        # Code source Flutter
│   ├── main.dart              # Point d'entrée
│   ├── config/                # Configuration
│   ├── models/                # Modèles de données
│   ├── providers/             # Gestion d'état (Provider)
│   ├── screens/               # Écrans de l'app
│   ├── services/              # Services (API, Supabase)
│   └── widgets/               # Composants réutilisables
│
├── baol_api/                  # Backend Node.js (optionnel)
│   ├── server.js              # Serveur Express
│   ├── controllers/           # Contrôleurs
│   ├── routes/                # Routes API
│   └── migrations/            # Migrations SQL
│
├── assets/                    # Assets (images, icons)
│   ├── icons/                 # Icônes d'app
│   └── images/                # Images
│
├── android/                   # Configuration Android
├── ios/                       # Configuration iOS
├── web/                       # Configuration Web
├── windows/                   # Configuration Windows
├── macos/                     # Configuration macOS
├── linux/                     # Configuration Linux
│
└── docs/                      # Documentation
    ├── GUIDE_DEPLOIEMENT.md
    ├── GUIDE_ASSETS.md
    └── ...
```

---

## 🛠️ Configuration du Projet

### **Bundle ID**
- Android : `com.salamagri.salam`
- iOS : `com.salamagri.salam`
- Package : `com.salamagri.salam`

### **Versions**
- Version actuelle : **1.0.0+1**
- Min SDK Android : **21** (Android 5.0)
- Target SDK Android : **34** (Android 14)
- iOS Deployment Target : **12.0**

---

## 📱 Build & Déploiement

### **Android**

```bash
# APK de développement
flutter build apk

# APK de release (signé)
flutter build apk --release

# App Bundle pour Play Store
flutter build appbundle --release
```

📖 Voir [GUIDE_SIGNATURE_ANDROID.md](GUIDE_SIGNATURE_ANDROID.md) pour la signature

### **iOS**

```bash
# Build iOS
flutter build ios --release

# Créer un IPA
flutter build ipa --release
```

📖 Voir [GUIDE_DEPLOIEMENT.md](GUIDE_DEPLOIEMENT.md) pour les détails

---

## 🎨 Assets & Branding

### **Palette de Couleurs**

```css
/* Vert Principal */
#4CAF50  rgb(76, 175, 80)

/* Vert Foncé */
#388E3C  rgb(56, 142, 60)

/* Vert Clair */
#81C784  rgb(129, 199, 132)
```

### **Génération des Assets**

```powershell
# Script PowerShell automatique
.\generer_assets.ps1

# OU manuellement
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```

📖 Voir [GUIDE_ASSETS.md](GUIDE_ASSETS.md) pour les détails

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [GUIDE_DEPLOIEMENT.md](GUIDE_DEPLOIEMENT.md) | Guide complet de déploiement |
| [GUIDE_SIGNATURE_ANDROID.md](GUIDE_SIGNATURE_ANDROID.md) | Signature Android |
| [GUIDE_ASSETS.md](GUIDE_ASSETS.md) | Création des assets |
| [GUIDE_BUILD_PRODUCTION.md](GUIDE_BUILD_PRODUCTION.md) | Build de production |
| [PREPARATION_IMAGES.md](PREPARATION_IMAGES.md) | Spécifications images |
| [DIAGNOSTIC_COMMUNICATION.md](DIAGNOSTIC_COMMUNICATION.md) | Architecture technique |

---

## 🔐 Sécurité

### **Fichiers Sensibles (Ne JAMAIS Commiter)**

- ✅ `.env` - Variables d'environnement
- ✅ `android/key.properties` - Clés de signature Android
- ✅ `android/app/*.jks` - Keystores Android
- ✅ `ios/Runner.xcodeproj/project.pbxproj` (avec secrets)
- ✅ Toute clé API ou token

### **Best Practices**

- Utilisez des variables d'environnement pour les secrets
- Ne commitez jamais les keystores
- Utilisez GitHub Secrets pour CI/CD
- Activez 2FA sur tous les comptes

---

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter drive --target=test_driver/app.dart

# Analyse du code
flutter analyze

# Format du code
flutter format lib/
```

---

## 🤝 Contribution

Ce projet est actuellement **propriétaire**. Pour toute question ou collaboration, contactez :

**Adama Kâ**  
📧 Email : dapy@gmail.com  
📱 Tel : +221 707 45 87

---

## 📄 License

© 2025 SALAM - Tous droits réservés.

Ce projet est propriétaire et ne peut être utilisé, copié ou distribué sans autorisation explicite.

---

## 🗺️ Roadmap

### Version 1.0.0 (Actuelle)
- ✅ Authentification utilisateurs
- ✅ Catalogue d'équipements
- ✅ Géolocalisation
- ✅ Chat temps réel
- ✅ Notifications push
- ✅ Gestion des favoris

### Version 1.1.0 (À venir)
- [ ] Système de paiement intégré
- [ ] Notation et avis
- [ ] Calendrier de disponibilité
- [ ] Mode hors ligne
- [ ] Support multilingue (Wolof, Français, Anglais)

### Version 2.0.0 (Futur)
- [ ] Assurance équipements
- [ ] Contrats intelligents
- [ ] Marketplace étendu
- [ ] Analytics pour propriétaires

---

## 🙏 Remerciements

- **Flutter Team** - Framework exceptionnel
- **Supabase** - Backend puissant et simple
- **Communauté Flutter Sénégal** - Support et inspiration

---

## 📞 Contact & Support

### **Support Technique**
- 📧 Email : dapy@gmail.com
- 📱 Téléphone : +221 707 45 87

### **Liens Utiles**
- 🌐 Site web : (À venir)
- 📱 Play Store : (À venir)
- 🍎 App Store : (À venir)

---

<div align="center">

**Fait avec ❤️ au Sénégal 🇸🇳**

*SALAM - Modernisons l'agriculture ensemble*

</div>
