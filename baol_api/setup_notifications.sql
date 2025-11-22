-- ========================================
-- Script d'initialisation de la base de données BAOL
-- Base: PostgreSQL
-- Date: 2025-11-16
-- ========================================

-- INSTRUCTIONS:
-- 1. Ouvrir pgAdmin ou psql
-- 2. Se connecter à PostgreSQL
-- 3. Exécuter ce script dans l'ordre

-- ========================================
-- 1. CRÉATION DE LA BASE DE DONNÉES
-- ========================================

-- Créer la base si elle n'existe pas
-- (À exécuter depuis la base postgres par défaut)
-- CREATE DATABASE baol_db;

-- Puis se connecter à baol_db et exécuter le reste

-- ========================================
-- 2. VÉRIFICATION DES TABLES EXISTANTES
-- ========================================

-- Vérifier si les tables users et orders existent
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE NOTICE '⚠️  Table users n''existe pas. Exécutez d''abord create_tables.sql';
    ELSE
        RAISE NOTICE '✅ Table users trouvée';
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'orders') THEN
        RAISE NOTICE '⚠️  Table orders n''existe pas. Exécutez d''abord create_tables.sql';
    ELSE
        RAISE NOTICE '✅ Table orders trouvée';
    END IF;
END $$;

-- ========================================
-- 3. CRÉATION DE LA TABLE NOTIFICATIONS
-- ========================================

-- Supprimer la table si elle existe (pour recréation propre)
DROP TABLE IF EXISTS notifications CASCADE;

-- Créer la table notifications
CREATE TABLE notifications (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    order_id VARCHAR(255),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ajouter les contraintes de clés étrangères si les tables existent
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        ALTER TABLE notifications 
        ADD CONSTRAINT fk_notifications_user 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Contrainte FK vers users ajoutée';
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'orders') THEN
        ALTER TABLE notifications 
        ADD CONSTRAINT fk_notifications_order 
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Contrainte FK vers orders ajoutée';
    END IF;
END $$;

-- ========================================
-- 4. CRÉATION DES INDEX
-- ========================================

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_order_id ON notifications(order_id) WHERE order_id IS NOT NULL;

-- ========================================
-- 5. INSERTION DE DONNÉES DE TEST (OPTIONNEL)
-- ========================================

-- Décommenter les lignes ci-dessous pour insérer des notifications de test
/*
INSERT INTO notifications (id, user_id, type, title, message, is_read, created_at) VALUES
('notif_test_1', 'user_id_test', 'system', 'Bienvenue sur BAOL', 'Merci de rejoindre notre plateforme !', false, NOW()),
('notif_test_2', 'user_id_test', 'order_update', 'Commande confirmée', 'Votre réservation a été confirmée', false, NOW() - INTERVAL '1 hour');
*/

-- ========================================
-- 6. VÉRIFICATION FINALE
-- ========================================

DO $$
DECLARE
    notif_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO notif_count FROM notifications;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Configuration de la base terminée !';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Table: notifications';
    RAISE NOTICE 'Colonnes: id, user_id, type, title, message, order_id, is_read, created_at';
    RAISE NOTICE 'Index: 4 index créés';
    RAISE NOTICE 'Notifications existantes: %', notif_count;
    RAISE NOTICE '';
    RAISE NOTICE '📋 Prochaines étapes:';
    RAISE NOTICE '1. Configurez le fichier .env avec vos credentials PostgreSQL';
    RAISE NOTICE '2. Redémarrez le serveur Node.js: node server.js';
    RAISE NOTICE '3. Testez avec Flutter: flutter run';
    RAISE NOTICE '========================================';
END $$;
