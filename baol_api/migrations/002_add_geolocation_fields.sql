-- Migration: Ajouter les coordonnées GPS aux tables users et equipment
-- Date: 2025-11-16
-- Description: Permet de stocker la position géographique des utilisateurs et équipements
--              pour calculer les distances et afficher les résultats à proximité

-- Ajout des colonnes de géolocalisation à la table users
ALTER TABLE users ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE users ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);

-- Ajout des colonnes de géolocalisation à la table equipment
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE equipment ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);

-- Commentaires pour la documentation
COMMENT ON COLUMN users.latitude IS 'Latitude de la position de l''utilisateur (-90 à 90)';
COMMENT ON COLUMN users.longitude IS 'Longitude de la position de l''utilisateur (-180 à 180)';
COMMENT ON COLUMN equipment.latitude IS 'Latitude de la position de l''équipement (-90 à 90)';
COMMENT ON COLUMN equipment.longitude IS 'Longitude de la position de l''équipement (-180 à 180)';

-- Créer des index pour améliorer les performances des recherches géographiques
CREATE INDEX IF NOT EXISTS idx_users_coordinates ON users(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_equipment_coordinates ON equipment(latitude, longitude);

-- Afficher un message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Migration géolocalisation effectuée avec succès';
    RAISE NOTICE '   - Colonnes latitude/longitude ajoutées à users';
    RAISE NOTICE '   - Colonnes latitude/longitude ajoutées à equipment';
    RAISE NOTICE '   - Index créés pour optimiser les recherches';
END $$;
