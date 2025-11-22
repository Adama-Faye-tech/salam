-- ============================================
-- SCRIPT COMPLET DE CRÉATION DU PROJET BAOL
-- Plateforme de partage d'équipements agricoles
-- Date: 18 novembre 2025
-- ============================================

-- ============================================
-- PARTIE 1 : SUPPRESSION DES TABLES EXISTANTES
-- (Décommenter si vous voulez tout réinitialiser)
-- ============================================

-- DROP TABLE IF EXISTS notifications CASCADE;
-- DROP TABLE IF EXISTS messages CASCADE;
-- DROP TABLE IF EXISTS chats CASCADE;
-- DROP TABLE IF EXISTS orders CASCADE;
-- DROP TABLE IF EXISTS favorites CASCADE;
-- DROP TABLE IF EXISTS equipment CASCADE;
-- DROP TABLE IF EXISTS profiles CASCADE;

-- ============================================
-- PARTIE 2 : CRÉATION DES TABLES
-- ============================================

-- Table des profils utilisateurs (complète les données auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    location TEXT,
    photo_url TEXT,
    description TEXT,
    user_type TEXT CHECK (user_type IN ('farmer', 'provider')) DEFAULT 'farmer',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des équipements
CREATE TABLE IF NOT EXISTS equipment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    price DECIMAL(10, 2) DEFAULT 0,
    images TEXT[] DEFAULT '{}',
    video_url TEXT,
    availability TEXT CHECK (availability IN ('available', 'unavailable', 'maintenance')) DEFAULT 'available',
    location TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des favoris
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, equipment_id)
);

-- Table des commandes/réservations
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES auth.users(id),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status TEXT CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')) DEFAULT 'pending',
    payment_status TEXT CHECK (payment_status IN ('pending', 'paid', 'refunded')) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des conversations (chats)
CREATE TABLE IF NOT EXISTS chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    equipment_id UUID REFERENCES equipment(id) ON DELETE SET NULL,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, provider_id, equipment_id)
);

-- Table des messages
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    type TEXT CHECK (type IN ('text', 'image', 'audio', 'document', 'location')) DEFAULT 'text',
    file_name TEXT,
    file_size INTEGER,
    audio_duration INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT CHECK (type IN ('order', 'chat', 'system', 'favorite')) DEFAULT 'system',
    reference_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- PARTIE 3 : CRÉATION DES INDEX
-- ============================================

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_equipment_owner ON equipment(owner_id);
CREATE INDEX IF NOT EXISTS idx_equipment_category ON equipment(category);
CREATE INDEX IF NOT EXISTS idx_equipment_availability ON equipment(availability);
CREATE INDEX IF NOT EXISTS idx_equipment_location ON equipment(location);
CREATE INDEX IF NOT EXISTS idx_equipment_created_at ON equipment(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_equipment ON favorites(equipment_id);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_provider ON orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_equipment ON orders(equipment_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_dates ON orders(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_chats_user ON chats(user_id);
CREATE INDEX IF NOT EXISTS idx_chats_provider ON chats(provider_id);
CREATE INDEX IF NOT EXISTS idx_chats_equipment ON chats(equipment_id);

CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- ============================================
-- PARTIE 4 : POLITIQUES RLS (ROW LEVEL SECURITY)
-- ============================================

-- Activer RLS sur toutes les tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ====== POLITIQUES PROFILES ======

-- Lecture publique des profils
CREATE POLICY "Public profiles are viewable by everyone"
ON profiles FOR SELECT
USING (true);

-- Création de son propre profil
CREATE POLICY "Users can create their own profile"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- Mise à jour de son propre profil
CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);

-- ====== POLITIQUES EQUIPMENT ======

-- Lecture publique des équipements
CREATE POLICY "Equipment are viewable by everyone"
ON equipment FOR SELECT
USING (true);

-- Création d'équipements pour utilisateurs authentifiés
CREATE POLICY "Authenticated users can create equipment"
ON equipment FOR INSERT
WITH CHECK (auth.uid() = owner_id);

-- Mise à jour de ses propres équipements
CREATE POLICY "Users can update their own equipment"
ON equipment FOR UPDATE
USING (auth.uid() = owner_id);

-- Suppression de ses propres équipements
CREATE POLICY "Users can delete their own equipment"
ON equipment FOR DELETE
USING (auth.uid() = owner_id);

-- ====== POLITIQUES FAVORITES ======

-- Lecture de ses propres favoris
CREATE POLICY "Users can view their own favorites"
ON favorites FOR SELECT
USING (auth.uid() = user_id);

-- Ajout de favoris
CREATE POLICY "Users can add favorites"
ON favorites FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Suppression de ses favoris
CREATE POLICY "Users can delete their own favorites"
ON favorites FOR DELETE
USING (auth.uid() = user_id);

-- ====== POLITIQUES ORDERS ======

-- Lecture des commandes (client ou prestataire)
CREATE POLICY "Users can view their orders"
ON orders FOR SELECT
USING (auth.uid() = customer_id OR auth.uid() = provider_id);

-- Création de commandes
CREATE POLICY "Users can create orders"
ON orders FOR INSERT
WITH CHECK (auth.uid() = customer_id);

-- Mise à jour des commandes (client ou prestataire)
CREATE POLICY "Users can update their orders"
ON orders FOR UPDATE
USING (auth.uid() = customer_id OR auth.uid() = provider_id);

-- ====== POLITIQUES CHATS ======

-- Lecture de ses propres conversations
CREATE POLICY "Users can view their chats"
ON chats FOR SELECT
USING (auth.uid() = user_id OR auth.uid() = provider_id);

-- Création de conversations
CREATE POLICY "Users can create chats"
ON chats FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Mise à jour de ses conversations
CREATE POLICY "Users can update their chats"
ON chats FOR UPDATE
USING (auth.uid() = user_id OR auth.uid() = provider_id);

-- ====== POLITIQUES MESSAGES ======

-- Lecture des messages de ses conversations
CREATE POLICY "Users can view messages in their chats"
ON messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM chats
        WHERE chats.id = messages.chat_id
        AND (chats.user_id = auth.uid() OR chats.provider_id = auth.uid())
    )
);

-- Envoi de messages
CREATE POLICY "Users can send messages in their chats"
ON messages FOR INSERT
WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
        SELECT 1 FROM chats
        WHERE chats.id = chat_id
        AND (chats.user_id = auth.uid() OR chats.provider_id = auth.uid())
    )
);

-- Mise à jour des messages (marquer comme lu)
CREATE POLICY "Users can update messages in their chats"
ON messages FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM chats
        WHERE chats.id = messages.chat_id
        AND (chats.user_id = auth.uid() OR chats.provider_id = auth.uid())
    )
);

-- ====== POLITIQUES NOTIFICATIONS ======

-- Lecture de ses propres notifications
CREATE POLICY "Users can view their own notifications"
ON notifications FOR SELECT
USING (auth.uid() = user_id);

-- Création de notifications (système ou utilisateur)
CREATE POLICY "System can create notifications"
ON notifications FOR INSERT
WITH CHECK (true);

-- Mise à jour de ses notifications
CREATE POLICY "Users can update their own notifications"
ON notifications FOR UPDATE
USING (auth.uid() = user_id);

-- Suppression de ses notifications
CREATE POLICY "Users can delete their own notifications"
ON notifications FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- PARTIE 5 : FONCTIONS ET TRIGGERS
-- ============================================

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers pour updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_equipment_updated_at
    BEFORE UPDATE ON equipment
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chats_updated_at
    BEFORE UPDATE ON chats
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour créer automatiquement un profil après inscription
CREATE OR REPLACE FUNCTION create_profile_for_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, name, phone, user_type)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'phone', NULL),
        COALESCE(NEW.raw_user_meta_data->>'user_type', 'farmer')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour créer le profil automatiquement
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_for_user();

-- Fonction pour mettre à jour le dernier message du chat
CREATE OR REPLACE FUNCTION update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chats
    SET 
        last_message = NEW.content,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.chat_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour automatiquement last_message
CREATE TRIGGER on_new_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_last_message();

-- ============================================
-- PARTIE 6 : DONNÉES DE TEST (OPTIONNEL)
-- ============================================

-- Insérer des catégories d'équipements (pour référence)
-- Ces valeurs sont aussi définies dans l'app Flutter (AppConstants)

/*
Catégories disponibles:
- Tracteurs
- Moissonneuses
- Semoirs
- Pulvérisateurs
- Outils de labour
- Matériel d'irrigation
- Équipement de transport
- Autres
*/

-- ============================================
-- VÉRIFICATION FINALE
-- ============================================

-- Vérifier que toutes les tables sont créées
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE columns.table_name = tables.table_name) as column_count
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Vérifier que RLS est activé
SELECT 
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Vérifier les politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================
-- FIN DU SCRIPT
-- ============================================

-- NOTES IMPORTANTES:
-- 1. Ce script crée toute la structure de base de données
-- 2. Les buckets Storage doivent être créés manuellement via l'interface
-- 3. Exécutez le script supabase_storage_policies.sql séparément pour Storage
-- 4. Vérifiez que l'authentification Supabase est configurée (Email/Password)
-- 5. Configurez l'URL de confirmation email si nécessaire

-- Pour créer les buckets Storage, voir: CONFIGURATION_SUPABASE_BUCKETS.md
