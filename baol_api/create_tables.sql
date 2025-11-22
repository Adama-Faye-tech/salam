-- Script de création des tables pour l'application SAME
-- Base de données : baol_db
-- Version : 1.0

-- ==================== TABLE: users ====================
-- Stocke les informations des utilisateurs (clients et prestataires)
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    photo_url TEXT,
    location VARCHAR(255),
    description TEXT,
    user_type VARCHAR(50) DEFAULT 'farmer' CHECK (user_type IN ('farmer', 'provider', 'both')),
    role VARCHAR(50) DEFAULT 'client' CHECK (role IN ('client', 'provider', 'admin')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_users_location ON users(location);

-- ==================== TABLE: equipment ====================
-- Stocke les équipements proposés par les prestataires
DROP TABLE IF EXISTS equipment CASCADE;

CREATE TABLE equipment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    price_per_day DECIMAL(10, 2) NOT NULL,
    location VARCHAR(255),
    image_url TEXT,
    provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX idx_equipment_provider ON equipment(provider_id);
CREATE INDEX idx_equipment_category ON equipment(category);
CREATE INDEX idx_equipment_available ON equipment(available);
CREATE INDEX idx_equipment_price ON equipment(price_per_day);

-- ==================== TABLE: chats ====================
-- Stocke les conversations entre clients et prestataires
DROP TABLE IF EXISTS chats CASCADE;

CREATE TABLE chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(client_id, provider_id, equipment_id)
);

-- Index pour améliorer les performances
CREATE INDEX idx_chats_client ON chats(client_id);
CREATE INDEX idx_chats_provider ON chats(provider_id);
CREATE INDEX idx_chats_equipment ON chats(equipment_id);

-- ==================== TABLE: messages ====================
-- Stocke les messages échangés dans les chats
DROP TABLE IF EXISTS messages CASCADE;

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('text', 'image', 'audio', 'document')),
    content TEXT,
    file_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX idx_messages_chat ON messages(chat_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created ON messages(created_at);
CREATE INDEX idx_messages_unread ON messages(read_at) WHERE read_at IS NULL;

-- ==================== TABLE: favorites ====================
-- Stocke les équipements favoris des utilisateurs
DROP TABLE IF EXISTS favorites CASCADE;

CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, equipment_id)
);

-- Index pour améliorer les performances
CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_equipment ON favorites(equipment_id);

-- ==================== TABLE: orders ====================
-- Stocke les commandes de location d'équipements
DROP TABLE IF EXISTS orders CASCADE;

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX idx_orders_client ON orders(client_id);
CREATE INDEX idx_orders_equipment ON orders(equipment_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_dates ON orders(start_date, end_date);

-- ==================== TRIGGERS ====================
-- Trigger pour mettre à jour automatiquement updated_at

-- Fonction pour mettre à jour le timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger sur users
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Appliquer le trigger sur equipment
CREATE TRIGGER update_equipment_updated_at
    BEFORE UPDATE ON equipment
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Appliquer le trigger sur orders
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==================== DONNÉES DE TEST ====================
-- Insérer quelques utilisateurs de test

INSERT INTO users (name, email, password_hash, phone, role) VALUES
    ('John Prestataire', 'provider@test.com', '$2b$10$xqZ8P3K5n8H9LGVhBXxZSeXJfGZhQcW4xqZ8P3K5n8H9LGVhBXxZSe', '0601020304', 'provider'),
    ('Marie Cliente', 'client@test.com', '$2b$10$xqZ8P3K5n8H9LGVhBXxZSeXJfGZhQcW4xqZ8P3K5n8H9LGVhBXxZSe', '0605060708', 'client');
-- Mot de passe pour les deux : "password123"

-- Insérer quelques équipements de test
INSERT INTO equipment (name, description, category, price_per_day, location, provider_id, available) VALUES
    ('Tracteur John Deere', 'Tracteur agricole puissant pour travaux de labour', 'Tracteur', 150.00, 'Dakar, Sénégal', (SELECT id FROM users WHERE email = 'provider@test.com'), TRUE),
    ('Moissonneuse-batteuse', 'Équipement complet pour la récolte du blé', 'Moissonneuse', 300.00, 'Thiès, Sénégal', (SELECT id FROM users WHERE email = 'provider@test.com'), TRUE),
    ('Charrue à disques', 'Charrue moderne pour labour profond', 'Charrue', 50.00, 'Kaolack, Sénégal', (SELECT id FROM users WHERE email = 'provider@test.com'), TRUE);

-- ==================== VÉRIFICATION ====================
-- Afficher le nombre de lignes dans chaque table

DO $$
BEGIN
    RAISE NOTICE 'Tables créées avec succès !';
    RAISE NOTICE 'Nombre d''utilisateurs : %', (SELECT COUNT(*) FROM users);
    RAISE NOTICE 'Nombre d''équipements : %', (SELECT COUNT(*) FROM equipment);
    RAISE NOTICE 'Nombre de chats : %', (SELECT COUNT(*) FROM chats);
    RAISE NOTICE 'Nombre de messages : %', (SELECT COUNT(*) FROM messages);
    RAISE NOTICE 'Nombre de favoris : %', (SELECT COUNT(*) FROM favorites);
    RAISE NOTICE 'Nombre de commandes : %', (SELECT COUNT(*) FROM orders);
END $$;

-- ==================== FIN ====================
