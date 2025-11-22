# ðŸ—„ï¸ Configuration de la Base de Données PostgreSQL - BAOL

## ðŸ“‹ Prérequis

- PostgreSQL installé (version 12+)
- pgAdmin ou psql
- Accès administrateur à  PostgreSQL

---

## ðŸš€ à‰tape 1 : Créer la base de données

### Option A : Avec pgAdmin

1. Ouvrez **pgAdmin**
2. Clic droit sur **Databases** †’ **Create** †’ **Database**
3. Nom : `baol_db`
4. Owner : `postgres` (ou votre utilisateur)
5. Cliquez sur **Save**

### Option B : Avec psql

```bash
psql -U postgres
CREATE DATABASE baol_db;
\c baol_db
```

---

## ðŸ”§ à‰tape 2 : Exécuter les scripts SQL

### 2.1 Créer les tables principales

Exécutez le fichier `create_tables.sql` :

**Avec pgAdmin :**
1. Connectez-vous à  la base `baol_db`
2. Tools †’ Query Tool
3. Ouvrez le fichier `baol_api/create_tables.sql`
4. Cliquez sur **Execute** (F5)

**Avec psql :**
```bash
psql -U postgres -d baol_db -f create_tables.sql
```

### 2.2 Ajouter la table notifications

Exécutez le fichier `setup_notifications.sql` :

**Avec pgAdmin :**
1. Tools †’ Query Tool
2. Ouvrez le fichier `baol_api/setup_notifications.sql`
3. Cliquez sur **Execute** (F5)

**Avec psql :**
```bash
psql -U postgres -d baol_db -f setup_notifications.sql
```

---

## ðŸ“ à‰tape 3 : Configuration du fichier .env

à‰ditez le fichier `baol_api/.env` :

```env
# Configuration PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=baol_db
DB_USER=postgres
DB_PASSWORD=VOTRE_MOT_DE_PASSE_ICI  # š ï¸ IMPORTANT: Remplacez par votre mot de passe

# JWT
JWT_SECRET=votre_secret_jwt_ultra_securise_changez_en_production
JWT_EXPIRES_IN=7d

# Serveur
PORT=3000
NODE_ENV=development

# CORS
ALLOWED_ORIGINS=*
```

**š ï¸ CRITIQUE :** Remplacez `VOTRE_MOT_DE_PASSE_ICI` par votre vrai mot de passe PostgreSQL !

---

## œ… à‰tape 4 : Vérification

### 4.1 Vérifier les tables

Dans pgAdmin ou psql, exécutez :

```sql
-- Lister toutes les tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Devrait afficher:
-- chats
-- equipment
-- favorites
-- messages
-- notifications  † Nouvelle table
-- orders
-- users
```

### 4.2 Vérifier le schéma de notifications

```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;

-- Devrait afficher:
-- id            | character varying | NO
-- user_id       | character varying | NO
-- type          | character varying | NO
-- title         | character varying | NO
-- message       | text              | NO
-- order_id      | character varying | YES
-- is_read       | boolean           | YES
-- created_at    | timestamp         | YES
```

### 4.3 Compter les enregistrements

```sql
SELECT 
    'users' as table, COUNT(*) as count FROM users
UNION ALL
SELECT 'equipment', COUNT(*) FROM equipment
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications;
```

---

## ðŸš€ à‰tape 5 : Démarrer le serveur

```bash
cd baol_api
node server.js
```

**Sortie attendue :**

```
ðŸ“Š Vérification de la base de données...
œ“ Table users existe
œ“ Table equipment existe
œ“ Table chats existe
œ“ Table messages existe
œ“ Table favorites existe
œ“ Table orders existe
œ“ Table notifications existe

========================================
ðŸš€ Serveur démarré avec succès !
ðŸ“ URL: http://localhost:3000
ðŸŒ Environnement: development
========================================

ðŸ“‹ Endpoints disponibles:
   GET    /health
   POST   /api/auth/register
   POST   /api/auth/login
   ...
   GET    /api/notifications           † Nouvelles routes
   PUT    /api/notifications/:id/read
   ...

œ… Prêt à  recevoir des requêtes !
```

---

## ðŸ§ª à‰tape 6 : Test de l'API

### Test avec curl (Windows PowerShell)

```powershell
# Test health check
Invoke-RestMethod -Uri "http://localhost:3000/health" -Method GET

# Test auth (après inscription/connexion)
$headers = @{ Authorization = "Bearer VOTRE_TOKEN_JWT" }
Invoke-RestMethod -Uri "http://localhost:3000/api/notifications" -Headers $headers
```

---

## ðŸ› Dépannage

### Problème : "SASL: SCRAM-SERVER-FIRST-MESSAGE: client password must be a string"

**Solution :**
- Vérifiez que `DB_PASSWORD` dans `.env` est entre guillemets si nécessaire
- Vérifiez qu'il n'y a pas d'espaces avant/après le mot de passe
- Testez la connexion avec psql : `psql -U postgres -d baol_db`

### Problème : "database baol_db does not exist"

**Solution :**
```sql
CREATE DATABASE baol_db;
```

### Problème : "Table users does not exist"

**Solution :**
Exécutez d'abord `create_tables.sql` avant `setup_notifications.sql`

---

## ðŸ“Š Structure finale de la base

```
baol_db/
”œ”€”€ users (authentification, profils)
”œ”€”€ equipment (matériels à  louer)
”œ”€”€ chats (conversations)
”œ”€”€ messages (messages chat)
”œ”€”€ favorites (favoris utilisateurs)
”œ”€”€ orders (réservations/commandes)
”””€”€ notifications (notifications système) † NOUVEAU
```

---

## œ… Checklist de vérification

- [ ] Base de données `baol_db` créée
- [ ] Fichier `create_tables.sql` exécuté avec succès
- [ ] Fichier `setup_notifications.sql` exécuté avec succès
- [ ] 7 tables présentes dans la base
- [ ] Table `notifications` a 8 colonnes
- [ ] Fichier `.env` configuré avec le bon mot de passe
- [ ] Serveur Node.js démarre sans erreur
- [ ] Endpoint `/health` répond avec succès

**Une fois tout coché, l'application est prête ! ðŸŽ‰**

