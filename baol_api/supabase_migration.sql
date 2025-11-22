-- ==========================================
-- SCRIPT DE MIGRATION SUPABASE - BAOL APP
-- ==========================================
-- Date: 2025-11-17
-- Description: Création complète du schéma de base de données pour l'application BAOL
-- avec Row Level Security (RLS) et politiques de sécurité

-- ==========================================
-- 1. ACTIVATION DES EXTENSIONS
-- ==========================================

-- Extension pour les UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Extension pour le chiffrement
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- 2. SUPPRESSION DES TABLES EXISTANTES
-- ==========================================

DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS chats CASCADE;
DROP TABLE IF EXISTS favorites CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS equipment CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Note: La table auth.users est gérée par Supabase Auth

-- ==========================================
-- 3. TABLE: profiles (Extension de auth.users)
-- ==========================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    photo_url TEXT,
    location VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    description TEXT,
    user_type VARCHAR(50) DEFAULT 'farmer' CHECK (user_type IN ('farmer', 'provider', 'both')),
    role VARCHAR(50) DEFAULT 'client' CHECK (role IN ('client', 'provider', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_user_type ON profiles(user_type);
CREATE INDEX idx_profiles_location ON profiles(location);

-- ==========================================
-- 4. TABLE: equipment
-- ==========================================

CREATE TABLE equipment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    price_per_hour DECIMAL(10, 2) DEFAULT 0,
    price_per_day DECIMAL(10, 2) NOT NULL,
    year VARCHAR(10),
    model VARCHAR(100),
    brand VARCHAR(100),
    location VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    intervention_zone VARCHAR(255),
    photos TEXT[] DEFAULT '{}',
    videos TEXT[] DEFAULT '{}',
    provider_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX idx_equipment_provider ON equipment(provider_id);
CREATE INDEX idx_equipment_category ON equipment(category);
CREATE INDEX idx_equipment_available ON equipment(available);
CREATE INDEX idx_equipment_price ON equipment(price_per_day);
CREATE INDEX idx_equipment_location ON equipment USING gin(to_tsvector('french', location));

-- ==========================================
-- 5. TABLE: chats
-- ==========================================

CREATE TABLE chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    provider_name VARCHAR(255),
    provider_avatar TEXT,
    equipment_id UUID REFERENCES equipment(id) ON DELETE SET NULL,
    equipment_name VARCHAR(255),
    last_message TEXT,
    last_message_time TIMESTAMP WITH TIME ZONE,
    unread_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX idx_chats_user ON chats(user_id);
CREATE INDEX idx_chats_provider ON chats(provider_id);
CREATE INDEX idx_chats_equipment ON chats(equipment_id);
CREATE INDEX idx_chats_last_message_time ON chats(last_message_time DESC);

-- ==========================================
-- 6. TABLE: messages
-- ==========================================

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    sender_name VARCHAR(255) NOT NULL,
    sender_avatar TEXT,
    receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('text', 'image', 'audio', 'document')),
    content TEXT NOT NULL,
    file_url TEXT,
    file_name VARCHAR(255),
    file_size INTEGER,
    audio_duration INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX idx_messages_chat ON messages(chat_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_messages_unread ON messages(is_read) WHERE is_read = FALSE;

-- ==========================================
-- 7. TABLE: favorites
-- ==========================================

CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, equipment_id)
);

-- Index pour performances
CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_equipment ON favorites(equipment_id);

-- ==========================================
-- 8. TABLE: orders
-- ==========================================

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    duration_days INTEGER NOT NULL,
    price_per_day DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'rejected')),
    notes TEXT,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX idx_orders_client ON orders(client_id);
CREATE INDEX idx_orders_provider ON orders(provider_id);
CREATE INDEX idx_orders_equipment ON orders(equipment_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_dates ON orders(start_date, end_date);

-- ==========================================
-- 9. TABLE: notifications
-- ==========================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('order_created', 'order_confirmed', 'order_cancelled', 'message', 'system')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- ==========================================
-- 10. FONCTIONS ET TRIGGERS
-- ==========================================

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger sur profiles
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger sur equipment
CREATE TRIGGER update_equipment_updated_at
    BEFORE UPDATE ON equipment
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger sur chats
CREATE TRIGGER update_chats_updated_at
    BEFORE UPDATE ON chats
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger sur orders
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour créer un profil automatiquement lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour créer le profil automatiquement
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- 11. ROW LEVEL SECURITY (RLS)
-- ==========================================

-- Activer RLS sur toutes les tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 12. POLITIQUES RLS - PROFILES
-- ==========================================

-- Tout le monde peut voir les profils publics
CREATE POLICY "Profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (true);

-- Les utilisateurs peuvent mettre à jour leur propre profil
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Les utilisateurs peuvent insérer leur propre profil
CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ==========================================
-- 13. POLITIQUES RLS - EQUIPMENT
-- ==========================================

-- Tout le monde peut voir les équipements
CREATE POLICY "Equipment is viewable by everyone"
    ON equipment FOR SELECT
    USING (true);

-- Les prestataires peuvent créer des équipements
CREATE POLICY "Providers can insert equipment"
    ON equipment FOR INSERT
    WITH CHECK (auth.uid() = provider_id);

-- Les prestataires peuvent mettre à jour leurs équipements
CREATE POLICY "Providers can update own equipment"
    ON equipment FOR UPDATE
    USING (auth.uid() = provider_id);

-- Les prestataires peuvent supprimer leurs équipements
CREATE POLICY "Providers can delete own equipment"
    ON equipment FOR DELETE
    USING (auth.uid() = provider_id);

-- ==========================================
-- 14. POLITIQUES RLS - CHATS
-- ==========================================

-- Les utilisateurs peuvent voir leurs propres chats
CREATE POLICY "Users can view own chats"
    ON chats FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = provider_id);

-- Les utilisateurs peuvent créer des chats
CREATE POLICY "Users can create chats"
    ON chats FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Les utilisateurs peuvent mettre à jour leurs propres chats
CREATE POLICY "Users can update own chats"
    ON chats FOR UPDATE
    USING (auth.uid() = user_id OR auth.uid() = provider_id);

-- ==========================================
-- 15. POLITIQUES RLS - MESSAGES
-- ==========================================

-- Les participants peuvent voir les messages de leur chat
CREATE POLICY "Chat participants can view messages"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.user_id = auth.uid() OR chats.provider_id = auth.uid())
        )
    );

-- Les participants peuvent envoyer des messages
CREATE POLICY "Chat participants can send messages"
    ON messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = chat_id
            AND (chats.user_id = auth.uid() OR chats.provider_id = auth.uid())
        )
    );

-- Les participants peuvent mettre à jour leurs messages (pour marquer comme lu)
CREATE POLICY "Chat participants can update messages"
    ON messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.user_id = auth.uid() OR chats.provider_id = auth.uid())
        )
    );

-- ==========================================
-- 16. POLITIQUES RLS - FAVORITES
-- ==========================================

-- Les utilisateurs peuvent voir leurs favoris
CREATE POLICY "Users can view own favorites"
    ON favorites FOR SELECT
    USING (auth.uid() = user_id);

-- Les utilisateurs peuvent ajouter des favoris
CREATE POLICY "Users can add favorites"
    ON favorites FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Les utilisateurs peuvent supprimer leurs favoris
CREATE POLICY "Users can delete own favorites"
    ON favorites FOR DELETE
    USING (auth.uid() = user_id);

-- ==========================================
-- 17. POLITIQUES RLS - ORDERS
-- ==========================================

-- Les clients et prestataires peuvent voir leurs commandes
CREATE POLICY "Users can view own orders"
    ON orders FOR SELECT
    USING (auth.uid() = client_id OR auth.uid() = provider_id);

-- Les clients peuvent créer des commandes
CREATE POLICY "Clients can create orders"
    ON orders FOR INSERT
    WITH CHECK (auth.uid() = client_id);

-- Les clients et prestataires peuvent mettre à jour leurs commandes
CREATE POLICY "Users can update own orders"
    ON orders FOR UPDATE
    USING (auth.uid() = client_id OR auth.uid() = provider_id);

-- ==========================================
-- 18. POLITIQUES RLS - NOTIFICATIONS
-- ==========================================

-- Les utilisateurs peuvent voir leurs notifications
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

-- Les utilisateurs peuvent mettre à jour leurs notifications (marquer comme lu)
CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- Le système peut créer des notifications
CREATE POLICY "System can create notifications"
    ON notifications FOR INSERT
    WITH CHECK (true);

-- ==========================================
-- 19. DONNÉES DE TEST
-- ==========================================

-- Note: Les utilisateurs seront créés via Supabase Auth
-- Vous pouvez créer des utilisateurs de test via la console Supabase
-- ou via l'application Flutter

-- ==========================================
-- 20. VÉRIFICATION FINALE
-- ==========================================

DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN ('profiles', 'equipment', 'chats', 'messages', 'favorites', 'orders', 'notifications');
    
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'MIGRATION SUPABASE TERMINÉE !';
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Tables créées: %', table_count;
    RAISE NOTICE '';
    RAISE NOTICE '✅ Extensions activées';
    RAISE NOTICE '✅ Tables créées avec UUID';
    RAISE NOTICE '✅ Index créés pour performances';
    RAISE NOTICE '✅ Triggers pour updated_at';
    RAISE NOTICE '✅ Row Level Security activé';
    RAISE NOTICE '✅ Politiques de sécurité configurées';
    RAISE NOTICE '';
    RAISE NOTICE 'Prochaines étapes:';
    RAISE NOTICE '1. Configurer les buckets Storage';
    RAISE NOTICE '2. Créer des utilisateurs de test';
    RAISE NOTICE '3. Tester les politiques RLS';
    RAISE NOTICE '==========================================';
END $$;
