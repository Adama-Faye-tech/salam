-- Migration: Ajouter les champs de profil manquants à la table users
-- Date: 2025-11-16
-- Description: Ajoute photo_url, location, description, et user_type pour profils complets

-- Ajouter la colonne photo_url pour la photo de profil
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Ajouter la colonne location pour la localisation de l'utilisateur
ALTER TABLE users ADD COLUMN IF NOT EXISTS location VARCHAR(255);

-- Ajouter la colonne description pour la bio/description de l'utilisateur
ALTER TABLE users ADD COLUMN IF NOT EXISTS description TEXT;

-- Ajouter la colonne user_type pour différencier agriculteur/prestataire
-- Valeurs possibles: 'farmer', 'provider', 'both'
ALTER TABLE users ADD COLUMN IF NOT EXISTS user_type VARCHAR(50) DEFAULT 'farmer' CHECK (user_type IN ('farmer', 'provider', 'both'));

-- Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_users_location ON users(location);

-- Commentaires pour documentation
COMMENT ON COLUMN users.photo_url IS 'URL de la photo de profil de l''utilisateur';
COMMENT ON COLUMN users.location IS 'Localisation/ville de l''utilisateur';
COMMENT ON COLUMN users.description IS 'Description/bio de l''utilisateur';
COMMENT ON COLUMN users.user_type IS 'Type d''utilisateur: farmer (agriculteur), provider (prestataire), both (les deux)';
