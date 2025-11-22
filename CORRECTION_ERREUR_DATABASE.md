# 🔧 Correction de l'erreur "Database error saving new user"

## 🐛 Erreur rencontrée

```
AuthRetryable Fetch Exception (message: {"code":"unexpected_failure","message":"Database error saving new user"}, statusCode: 500)
```

## 📋 Cause du problème

Cette erreur se produit parce que **la table `profiles` n'existe pas encore** ou que **le trigger de création automatique de profil n'est pas configuré**.

Quand un utilisateur s'inscrit :
1. ✅ Supabase crée l'utilisateur dans `auth.users`
2. ❌ Le trigger devrait créer automatiquement un profil dans `public.profiles`
3. ❌ ERREUR : La table ou le trigger n'existe pas

---

## ✅ Solution : Exécuter le script SQL

### Étape 1 : Ouvrir le SQL Editor de Supabase

1. Aller sur : https://supabase.com/dashboard/project/bfmnqkmdjerzbgafdclo/sql
2. Cliquer sur **"New Query"**

### Étape 2 : Copier et exécuter le script complet

Ouvrir le fichier `supabase_setup_complet.sql` et copier **TOUT le contenu** (520+ lignes)

**OU** copier le script ci-dessous :

```sql
-- ============================================
-- SCRIPT DE CONFIGURATION COMPLÈTE SUPABASE
-- Application BAOL - Location Matériel Agricole
-- ============================================

-- Activer les extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- SUPPRESSION DES TABLES EXISTANTES (si nécessaire)
-- Décommenter ces lignes si vous voulez réinstaller
-- ============================================

-- DROP TABLE IF EXISTS notifications CASCADE;
-- DROP TABLE IF EXISTS messages CASCADE;
-- DROP TABLE IF EXISTS chats CASCADE;
-- DROP TABLE IF EXISTS orders CASCADE;
-- DROP TABLE IF EXISTS favorites CASCADE;
-- DROP TABLE IF EXISTS equipment CASCADE;
-- DROP TABLE IF EXISTS profiles CASCADE;

-- ============================================
-- CRÉATION DES TABLES
-- ============================================

-- Table des profils utilisateurs
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    address TEXT,
    photo_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des équipements
CREATE TABLE IF NOT EXISTS equipment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    category TEXT NOT NULL,
    price_per_hour DECIMAL(10, 2) DEFAULT 0,
    price_per_day DECIMAL(10, 2) NOT NULL,
    year TEXT,
    model TEXT,
    brand TEXT,
    photos TEXT[] DEFAULT '{}',
    videos TEXT[] DEFAULT '{}',
    provider_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    location TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_available BOOLEAN DEFAULT TRUE,
    intervention_zone TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des favoris
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, equipment_id)
);

-- Table des commandes/réservations
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    renter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des conversations
CREATE TABLE IF NOT EXISTS chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user1_id, user2_id),
    CHECK (user1_id < user2_id)
);

-- Table des messages
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT,
    type TEXT NOT NULL DEFAULT 'text',
    media_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table des notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CRÉATION DES INDEX POUR LES PERFORMANCES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_equipment_provider ON equipment(provider_id);
CREATE INDEX IF NOT EXISTS idx_equipment_category ON equipment(category);
CREATE INDEX IF NOT EXISTS idx_equipment_location ON equipment USING GIST(geography(ST_MakePoint(longitude, latitude)));
CREATE INDEX IF NOT EXISTS idx_equipment_created_at ON equipment(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_equipment ON favorites(equipment_id);

CREATE INDEX IF NOT EXISTS idx_orders_equipment ON orders(equipment_id);
CREATE INDEX IF NOT EXISTS idx_orders_renter ON orders(renter_id);
CREATE INDEX IF NOT EXISTS idx_orders_provider ON orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

CREATE INDEX IF NOT EXISTS idx_chats_user1 ON chats(user1_id);
CREATE INDEX IF NOT EXISTS idx_chats_user2 ON chats(user2_id);
CREATE INDEX IF NOT EXISTS idx_chats_last_message_at ON chats(last_message_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================
-- ACTIVER ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLITIQUES RLS - PROFILES
-- ============================================

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
CREATE POLICY "Public profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- ============================================
-- POLITIQUES RLS - EQUIPMENT
-- ============================================

DROP POLICY IF EXISTS "Equipment is viewable by everyone" ON equipment;
CREATE POLICY "Equipment is viewable by everyone"
    ON equipment FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can insert their own equipment" ON equipment;
CREATE POLICY "Users can insert their own equipment"
    ON equipment FOR INSERT
    WITH CHECK (auth.uid() = provider_id);

DROP POLICY IF EXISTS "Users can update their own equipment" ON equipment;
CREATE POLICY "Users can update their own equipment"
    ON equipment FOR UPDATE
    USING (auth.uid() = provider_id);

DROP POLICY IF EXISTS "Users can delete their own equipment" ON equipment;
CREATE POLICY "Users can delete their own equipment"
    ON equipment FOR DELETE
    USING (auth.uid() = provider_id);

-- ============================================
-- POLITIQUES RLS - FAVORITES
-- ============================================

DROP POLICY IF EXISTS "Users can view their own favorites" ON favorites;
CREATE POLICY "Users can view their own favorites"
    ON favorites FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own favorites" ON favorites;
CREATE POLICY "Users can insert their own favorites"
    ON favorites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own favorites" ON favorites;
CREATE POLICY "Users can delete their own favorites"
    ON favorites FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- POLITIQUES RLS - ORDERS
-- ============================================

DROP POLICY IF EXISTS "Users can view their orders" ON orders;
CREATE POLICY "Users can view their orders"
    ON orders FOR SELECT
    USING (auth.uid() = renter_id OR auth.uid() = provider_id);

DROP POLICY IF EXISTS "Users can insert orders" ON orders;
CREATE POLICY "Users can insert orders"
    ON orders FOR INSERT
    WITH CHECK (auth.uid() = renter_id);

DROP POLICY IF EXISTS "Users can update their orders" ON orders;
CREATE POLICY "Users can update their orders"
    ON orders FOR UPDATE
    USING (auth.uid() = renter_id OR auth.uid() = provider_id);

-- ============================================
-- POLITIQUES RLS - CHATS
-- ============================================

DROP POLICY IF EXISTS "Users can view their chats" ON chats;
CREATE POLICY "Users can view their chats"
    ON chats FOR SELECT
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can create chats" ON chats;
CREATE POLICY "Users can create chats"
    ON chats FOR INSERT
    WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can update their chats" ON chats;
CREATE POLICY "Users can update their chats"
    ON chats FOR UPDATE
    USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- ============================================
-- POLITIQUES RLS - MESSAGES
-- ============================================

DROP POLICY IF EXISTS "Users can view messages in their chats" ON messages;
CREATE POLICY "Users can view messages in their chats"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.user1_id = auth.uid() OR chats.user2_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can insert messages in their chats" ON messages;
CREATE POLICY "Users can insert messages in their chats"
    ON messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Users can update their messages" ON messages;
CREATE POLICY "Users can update their messages"
    ON messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.user1_id = auth.uid() OR chats.user2_id = auth.uid())
        )
    );

-- ============================================
-- POLITIQUES RLS - NOTIFICATIONS
-- ============================================

DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;
CREATE POLICY "Users can view their notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their notifications" ON notifications;
CREATE POLICY "Users can update their notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their notifications" ON notifications;
CREATE POLICY "Users can delete their notifications"
    ON notifications FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- FONCTIONS ET TRIGGERS
-- ============================================

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers pour updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_equipment_updated_at ON equipment;
CREATE TRIGGER update_equipment_updated_at
    BEFORE UPDATE ON equipment
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_chats_updated_at ON chats;
CREATE TRIGGER update_chats_updated_at
    BEFORE UPDATE ON chats
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ⭐ FONCTION CRITIQUE : Créer automatiquement un profil lors de l'inscription
CREATE OR REPLACE FUNCTION create_profile_for_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, email, created_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', 'Utilisateur'),
        NEW.email,
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ⭐ TRIGGER CRITIQUE : Déclencher la création de profil automatiquement
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_for_user();

-- Fonction pour mettre à jour le dernier message d'un chat
CREATE OR REPLACE FUNCTION update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chats
    SET last_message = NEW.content,
        last_message_at = NEW.created_at
    WHERE id = NEW.chat_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_chat_on_message ON messages;
CREATE TRIGGER update_chat_on_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_last_message();

-- ============================================
-- VÉRIFICATIONS
-- ============================================

-- Vérifier que toutes les tables existent
SELECT 
    'profiles' as table_name,
    COUNT(*) as row_count
FROM profiles
UNION ALL
SELECT 'equipment', COUNT(*) FROM equipment
UNION ALL
SELECT 'favorites', COUNT(*) FROM favorites
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'chats', COUNT(*) FROM chats
UNION ALL
SELECT 'messages', COUNT(*) FROM messages
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications;

-- ============================================
-- FIN DU SCRIPT
-- ============================================
```

### Étape 3 : Exécuter le script

1. Cliquer sur **"Run"** (ou F5)
2. Vérifier qu'il n'y a pas d'erreurs
3. Vous devriez voir le résultat des vérifications à la fin

### Étape 4 : Créer les buckets Storage

1. Aller sur : https://supabase.com/dashboard/project/bfmnqkmdjerzbgafdclo/storage/buckets
2. Créer 3 nouveaux buckets (tous **PUBLIC**) :
   - `equipment`
   - `chat`
   - `profiles`

### Étape 5 : Appliquer les politiques Storage

Retourner dans le SQL Editor et exécuter :

```sql
-- Politiques pour le bucket equipment
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'equipment' );

CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'equipment' AND auth.role() = 'authenticated' );

-- Politiques pour le bucket chat
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'chat' );

CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'chat' AND auth.role() = 'authenticated' );

-- Politiques pour le bucket profiles
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'profiles' );

CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'profiles' AND auth.role() = 'authenticated' );
```

---

## ✅ Vérification

Après avoir exécuté ces scripts, testez l'inscription :

1. Lancer l'application
2. Créer un nouveau compte
3. L'inscription devrait maintenant fonctionner ! ✨

---

## 🐛 Si l'erreur persiste

1. Vérifier dans le Dashboard Supabase > **Database** > **Tables** que la table `profiles` existe
2. Vérifier dans **Database** > **Triggers** que le trigger `on_auth_user_created` existe
3. Consulter les logs : https://supabase.com/dashboard/project/bfmnqkmdjerzbgafdclo/logs/postgres-logs

---

**🎯 L'erreur sera corrigée une fois le script SQL exécuté !**
