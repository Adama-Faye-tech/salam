-- ============================================
-- BAOL - Structure complète Supabase Database
-- Date: 17 novembre 2025
-- ============================================

-- ============================================
-- 1. TABLE: profiles
-- Profils utilisateurs (complète auth.users)
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  location TEXT,
  photo_url TEXT,
  user_type TEXT DEFAULT 'farmer',
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherches rapides
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON public.profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_profiles_location ON public.profiles(location);

-- RLS (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Politique: Lecture publique des profils
CREATE POLICY "Les profils sont publics" 
  ON public.profiles FOR SELECT 
  USING (true);

-- Politique: Utilisateurs peuvent insérer leur propre profil
CREATE POLICY "Les utilisateurs peuvent créer leur profil" 
  ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Politique: Utilisateurs peuvent mettre à jour leur propre profil
CREATE POLICY "Les utilisateurs peuvent mettre à jour leur profil" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

-- ============================================
-- 2. TABLE: equipment
-- Équipements agricoles et services
-- ============================================
CREATE TABLE IF NOT EXISTS public.equipment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  description TEXT,
  images TEXT[], -- Array d'URLs
  video_url TEXT,
  availability TEXT DEFAULT 'available' CHECK (availability IN ('available', 'unavailable', 'rented')),
  location TEXT,
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour performances
CREATE INDEX IF NOT EXISTS idx_equipment_owner ON public.equipment(owner_id);
CREATE INDEX IF NOT EXISTS idx_equipment_category ON public.equipment(category);
CREATE INDEX IF NOT EXISTS idx_equipment_availability ON public.equipment(availability);
CREATE INDEX IF NOT EXISTS idx_equipment_location ON public.equipment(location);
CREATE INDEX IF NOT EXISTS idx_equipment_created_at ON public.equipment(created_at DESC);

-- RLS
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;

-- Lecture publique
CREATE POLICY "Les équipements sont publics" 
  ON public.equipment FOR SELECT 
  USING (true);

-- Insertion: utilisateurs authentifiés uniquement
CREATE POLICY "Utilisateurs authentifiés peuvent créer des équipements" 
  ON public.equipment FOR INSERT 
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = owner_id);

-- Mise à jour: propriétaire uniquement
CREATE POLICY "Les propriétaires peuvent mettre à jour leurs équipements" 
  ON public.equipment FOR UPDATE 
  USING (auth.uid() = owner_id);

-- Suppression: propriétaire uniquement
CREATE POLICY "Les propriétaires peuvent supprimer leurs équipements" 
  ON public.equipment FOR DELETE 
  USING (auth.uid() = owner_id);

-- ============================================
-- 3. TABLE: favorites
-- Favoris des utilisateurs
-- ============================================
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  equipment_id UUID NOT NULL REFERENCES public.equipment(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, equipment_id) -- Un équipement ne peut être favori qu'une fois par utilisateur
);

-- Index
CREATE INDEX IF NOT EXISTS idx_favorites_user ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_equipment ON public.favorites(equipment_id);

-- RLS
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Lecture: utilisateur peut voir ses propres favoris
CREATE POLICY "Utilisateurs peuvent voir leurs favoris" 
  ON public.favorites FOR SELECT 
  USING (auth.uid() = user_id);

-- Insertion
CREATE POLICY "Utilisateurs peuvent ajouter des favoris" 
  ON public.favorites FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Suppression
CREATE POLICY "Utilisateurs peuvent supprimer leurs favoris" 
  ON public.favorites FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- 4. TABLE: orders
-- Commandes/Réservations
-- ============================================
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  equipment_id UUID NOT NULL REFERENCES public.equipment(id) ON DELETE CASCADE,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_orders_customer ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_provider ON public.orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_equipment ON public.orders(equipment_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);

-- RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Lecture: clients et prestataires peuvent voir leurs commandes
CREATE POLICY "Utilisateurs peuvent voir leurs commandes" 
  ON public.orders FOR SELECT 
  USING (auth.uid() = customer_id OR auth.uid() = provider_id);

-- Insertion: clients authentifiés
CREATE POLICY "Clients peuvent créer des commandes" 
  ON public.orders FOR INSERT 
  WITH CHECK (auth.uid() = customer_id);

-- Mise à jour: clients et prestataires
CREATE POLICY "Participants peuvent mettre à jour les commandes" 
  ON public.orders FOR UPDATE 
  USING (auth.uid() = customer_id OR auth.uid() = provider_id);

-- ============================================
-- 5. TABLE: notifications
-- Notifications utilisateurs
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error', 'order')),
  is_read BOOLEAN DEFAULT FALSE,
  related_id UUID, -- ID de l'objet lié (commande, équipement, etc.)
  related_type TEXT, -- Type: 'order', 'equipment', 'chat', etc.
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Lecture: utilisateur voit ses propres notifications
CREATE POLICY "Utilisateurs peuvent voir leurs notifications" 
  ON public.notifications FOR SELECT 
  USING (auth.uid() = user_id);

-- Mise à jour: utilisateur peut marquer comme lu
CREATE POLICY "Utilisateurs peuvent mettre à jour leurs notifications" 
  ON public.notifications FOR UPDATE 
  USING (auth.uid() = user_id);

-- Suppression
CREATE POLICY "Utilisateurs peuvent supprimer leurs notifications" 
  ON public.notifications FOR DELETE 
  USING (auth.uid() = user_id);

-- ============================================
-- 6. TABLE: chats
-- Conversations entre utilisateurs
-- ============================================
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  participant2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_message TEXT,
  last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(participant1_id, participant2_id),
  CHECK (participant1_id != participant2_id)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_chats_participant1 ON public.chats(participant1_id);
CREATE INDEX IF NOT EXISTS idx_chats_participant2 ON public.chats(participant2_id);
CREATE INDEX IF NOT EXISTS idx_chats_last_message_at ON public.chats(last_message_at DESC);

-- RLS
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

-- Lecture: participants uniquement
CREATE POLICY "Participants peuvent voir leurs conversations" 
  ON public.chats FOR SELECT 
  USING (auth.uid() = participant1_id OR auth.uid() = participant2_id);

-- Insertion
CREATE POLICY "Utilisateurs peuvent créer des conversations" 
  ON public.chats FOR INSERT 
  WITH CHECK (auth.uid() = participant1_id OR auth.uid() = participant2_id);

-- Mise à jour
CREATE POLICY "Participants peuvent mettre à jour leurs conversations" 
  ON public.chats FOR UPDATE 
  USING (auth.uid() = participant1_id OR auth.uid() = participant2_id);

-- ============================================
-- 7. TABLE: messages
-- Messages des conversations
-- ============================================
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'audio', 'document')),
  media_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_messages_chat ON public.messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);

-- RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Lecture: participants du chat
CREATE POLICY "Participants du chat peuvent voir les messages" 
  ON public.messages FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.chats 
      WHERE id = messages.chat_id 
      AND (participant1_id = auth.uid() OR participant2_id = auth.uid())
    )
  );

-- Insertion: participants du chat
CREATE POLICY "Participants du chat peuvent envoyer des messages" 
  ON public.messages FOR INSERT 
  WITH CHECK (
    auth.uid() = sender_id 
    AND EXISTS (
      SELECT 1 FROM public.chats 
      WHERE id = messages.chat_id 
      AND (participant1_id = auth.uid() OR participant2_id = auth.uid())
    )
  );

-- Mise à jour: marquer comme lu
CREATE POLICY "Participants peuvent marquer les messages comme lus" 
  ON public.messages FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.chats 
      WHERE id = messages.chat_id 
      AND (participant1_id = auth.uid() OR participant2_id = auth.uid())
    )
  );

-- ============================================
-- 8. TRIGGERS
-- Mise à jour automatique de updated_at
-- ============================================

-- Fonction pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers sur les tables concernées
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_equipment_updated_at BEFORE UPDATE ON public.equipment
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour mettre à jour last_message_at dans chats
CREATE OR REPLACE FUNCTION update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.chats 
  SET last_message = NEW.content, 
      last_message_at = NEW.created_at
  WHERE id = NEW.chat_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_chat_on_new_message AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION update_chat_last_message();

-- ============================================
-- 9. FONCTIONS UTILES
-- ============================================

-- Fonction: Créer un profil automatiquement après signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, user_type, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'farmer'),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger sur auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Fonction: Compter les favoris d'un équipement
CREATE OR REPLACE FUNCTION count_favorites(equipment_id_param UUID)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER 
  FROM public.favorites 
  WHERE equipment_id = equipment_id_param;
$$ LANGUAGE SQL STABLE;

-- Fonction: Compter les commandes d'un équipement
CREATE OR REPLACE FUNCTION count_orders(equipment_id_param UUID)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER 
  FROM public.orders 
  WHERE equipment_id = equipment_id_param;
$$ LANGUAGE SQL STABLE;

-- Fonction: Obtenir les messages non lus
CREATE OR REPLACE FUNCTION get_unread_messages_count(user_id_param UUID)
RETURNS INTEGER AS $$
  SELECT COUNT(*)::INTEGER 
  FROM public.messages m
  JOIN public.chats c ON m.chat_id = c.id
  WHERE (c.participant1_id = user_id_param OR c.participant2_id = user_id_param)
    AND m.sender_id != user_id_param
    AND m.is_read = FALSE;
$$ LANGUAGE SQL STABLE;

-- ============================================
-- 10. STORAGE BUCKETS (à créer via Dashboard)
-- ============================================

-- IMPORTANT: Ces buckets doivent être créés via le Dashboard Supabase
-- Après création, configurez les politiques suivantes:

-- Bucket: profiles
-- Public: true
-- Allowed MIME types: image/jpeg, image/png, image/webp
-- Max file size: 5 MB

-- Politique: Lecture publique
-- CREATE POLICY "Public Access"
-- ON storage.objects FOR SELECT
-- TO public
-- USING ( bucket_id = 'profiles' );

-- Politique: Utilisateurs peuvent uploader leurs photos
-- CREATE POLICY "Users can upload their profile photo"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK ( bucket_id = 'profiles' AND (storage.foldername(name))[1] = auth.uid()::text );

-- Bucket: equipment
-- Public: true
-- Allowed MIME types: image/*, video/mp4
-- Max file size: 20 MB

-- Politique: Lecture publique
-- CREATE POLICY "Public Access"
-- ON storage.objects FOR SELECT
-- TO public
-- USING ( bucket_id = 'equipment' );

-- Politique: Utilisateurs authentifiés peuvent uploader
-- CREATE POLICY "Authenticated users can upload equipment media"
-- ON storage.objects FOR INSERT
-- TO authenticated
-- WITH CHECK ( bucket_id = 'equipment' );

-- ============================================
-- FIN DU SCRIPT
-- ============================================
-- Pour exécuter ce script:
-- 1. Allez sur https://hddkscngvcdngxpogqmt.supabase.co
-- 2. SQL Editor → New Query
-- 3. Copiez-collez ce script
-- 4. Cliquez sur "Run"
-- 5. Créez les buckets Storage manuellement (profiles, equipment)
-- ============================================
