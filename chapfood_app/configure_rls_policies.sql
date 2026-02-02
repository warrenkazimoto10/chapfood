-- ============================================================================
-- Configuration Row Level Security (RLS) - ChapFood
-- ============================================================================
-- Ce script configure les politiques de sécurité au niveau des lignes
-- pour protéger les données selon les rôles utilisateurs
-- ============================================================================

-- ============================================================================
-- 1. ACTIVER RLS SUR TOUTES LES TABLES
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_driver_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

RAISE NOTICE 'RLS activé sur toutes les tables';

-- ============================================================================
-- 2. POLITIQUES POUR LA TABLE USERS
-- ============================================================================

-- Les utilisateurs peuvent lire leur propre profil
CREATE POLICY "Users can read own profile"
ON users FOR SELECT
USING (id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Les utilisateurs peuvent mettre à jour leur propre profil
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (id = current_setting('request.jwt.claims', true)::json->>'sub')
WITH CHECK (id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Permettre l'insertion pour l'inscription (anon)
CREATE POLICY "Allow public signup"
ON users FOR INSERT
WITH CHECK (true);

-- Les admins peuvent tout faire (à ajouter si rôle admin existe)
-- CREATE POLICY "Admins can do anything on users"
-- ON users FOR ALL
-- USING (current_setting('request.jwt.claims', true)::json->>'role' = 'admin');

-- ============================================================================
-- 3. POLITIQUES POUR LA TABLE DRIVERS
-- ============================================================================

-- Les drivers peuvent lire leur propre profil
CREATE POLICY "Drivers can read own profile"
ON drivers FOR SELECT
USING (
  id::text = current_setting('request.jwt.claims', true)::json->>'sub'
  OR
  -- Permettre aux clients de voir les drivers disponibles (pour liste)
  is_available = true
);

-- Les drivers peuvent mettre à jour leur propre profil
CREATE POLICY "Drivers can update own profile"
ON drivers FOR UPDATE
USING (id::text = current_setting('request.jwt.claims', true)::json->>'sub')
WITH CHECK (id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Permettre l'insertion pour l'inscription driver
CREATE POLICY "Allow driver signup"
ON drivers FOR INSERT
WITH CHECK (true);

-- ============================================================================
-- 4. POLITIQUES POUR LA TABLE ORDERS
-- ============================================================================

-- Les clients peuvent voir leurs propres commandes
CREATE POLICY "Users can read own orders"
ON orders FOR SELECT
USING (
  user_id = current_setting('request.jwt.claims', true)::json->>'sub'
  OR
  -- Ou si le driver est assigné
  driver_id IN (
    SELECT id FROM drivers
    WHERE id::text = current_setting('request.jwt.claims', true)::json->>'sub'
  )
);

-- Les clients peuvent créer des commandes
CREATE POLICY "Users can create orders"
ON orders FOR INSERT
WITH CHECK (
  user_id = current_setting('request.jwt.claims', true)::json->>'sub'
  OR
  -- Permettre création sans user_id (guest checkout)
  user_id IS NULL
);

-- Les clients peuvent mettre à jour leurs commandes (seulement certains champs)
CREATE POLICY "Users can update own orders"
ON orders FOR UPDATE
USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub')
WITH CHECK (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Les drivers peuvent mettre à jour les commandes assignées
CREATE POLICY "Drivers can update assigned orders"
ON orders FOR UPDATE
USING (
  driver_id IN (
    SELECT id FROM drivers
    WHERE id::text = current_setting('request.jwt.claims', true)::json->>'sub'
  )
)
WITH CHECK (
  driver_id IN (
    SELECT id FROM drivers
    WHERE id::text = current_setting('request.jwt.claims', true)::json->>'sub'
  )
);

-- Les drivers peuvent voir les commandes disponibles (ready_for_delivery)
CREATE POLICY "Drivers can see available orders"
ON orders FOR SELECT
USING (
  status = 'ready_for_delivery'
  OR
  driver_id IN (
    SELECT id FROM drivers
    WHERE id::text = current_setting('request.jwt.claims', true)::json->>'sub'
  )
);

-- ============================================================================
-- 5. POLITIQUES POUR LA TABLE ORDER_ITEMS
-- ============================================================================

-- Les clients peuvent voir les items de leurs commandes
CREATE POLICY "Users can read own order items"
ON order_items FOR SELECT
USING (
  order_id IN (
    SELECT id FROM orders
    WHERE user_id = current_setting('request.jwt.claims', true)::json->>'sub'
  )
  OR
  -- Ou si le driver est assigné à la commande
  order_id IN (
    SELECT id FROM orders
    WHERE driver_id IN (
      SELECT id FROM drivers
      WHERE id::text = current_setting('request.jwt.claims', true)::json->>'sub'
    )
  )
);

-- Les clients peuvent créer des items pour leurs commandes
CREATE POLICY "Users can create order items"
ON order_items FOR INSERT
WITH CHECK (
  order_id IN (
    SELECT id FROM orders
    WHERE user_id = current_setting('request.jwt.claims', true)::json->>'sub'
    OR user_id IS NULL
  )
);

-- ============================================================================
-- 6. POLITIQUES POUR LA TABLE ORDER_DRIVER_ASSIGNMENTS
-- ============================================================================

-- Les drivers peuvent voir leurs assignations
CREATE POLICY "Drivers can read own assignments"
ON order_driver_assignments FOR SELECT
USING (
  driver_id IN (
    SELECT id FROM drivers
    WHERE id::text = current_setting('request.jwt.claims', true)::json->>'sub'
  )
);

-- Les clients peuvent voir les assignations de leurs commandes
CREATE POLICY "Users can read assignments for own orders"
ON order_driver_assignments FOR SELECT
USING (
  order_id IN (
    SELECT id FROM orders
    WHERE user_id = current_setting('request.jwt.claims', true)::json->>'sub'
  )
);

-- Les drivers peuvent créer des assignations pour eux-mêmes
CREATE POLICY "Drivers can create own assignments"
ON order_driver_assignments FOR INSERT
WITH CHECK (
  driver_id IN (
    SELECT id FROM drivers
    WHERE id::text = current_setting('request.jwt.claims', true)::json->>'sub'
  )
);

-- ============================================================================
-- 7. POLITIQUES POUR LES TABLES PUBLIQUES (Menu, Catégories)
-- ============================================================================

-- Tout le monde peut lire le menu et les catégories
CREATE POLICY "Public can read menu items"
ON menu_items FOR SELECT
USING (is_available = true);

CREATE POLICY "Public can read categories"
ON categories FOR SELECT
USING (is_active = true);

-- ============================================================================
-- 8. POLITIQUE POUR ACCES ANONYME (Guests)
-- ============================================================================

-- Permettre aux utilisateurs anonymes de lire certaines données
CREATE POLICY "Anonymous can read available menu"
ON menu_items FOR SELECT
TO anon
USING (is_available = true);

CREATE POLICY "Anonymous can read categories"
ON categories FOR SELECT
TO anon
USING (is_active = true);

-- ============================================================================
-- 9. DÉSACTIVER TEMPORAIREMENT CERTAINES POLITIQUES POUR DEBUG
-- ============================================================================
-- Si vous avez des problèmes d'accès, vous pouvez temporairement
-- créer des politiques plus permissives pour le développement

/*
-- ATTENTION: SEULEMENT POUR DEV, PAS EN PRODUCTION!
CREATE POLICY "Dev: Allow all for authenticated users"
ON orders FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);
*/

-- ============================================================================
-- 10. VÉRIFICATION DES POLITIQUES
-- ============================================================================

-- Afficher toutes les politiques créées
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- 11. FUNCTION HELPER POUR OBTENIR L'ID UTILISATEUR COURANT
-- ============================================================================

CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS TEXT AS $$
BEGIN
  RETURN current_setting('request.jwt.claims', true)::json->>'sub';
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- NOTES IMPORTANTES
-- ============================================================================
/*
1. Les politiques RLS sont évaluées APRÈS les règles de la table
2. Si aucune politique ne correspond, l'accès est REFUSÉ par défaut
3. Les policies s'appliquent à tous sauf les SUPERUSERS et propriétaires de table
4. Pour tester les policies, utilisez SET ROLE et pas votre compte admin

TEST:
-----
-- Se connecter en tant qu'utilisateur normal
SET ROLE authenticated;
SET request.jwt.claims = '{"sub": "user-uuid-here", "role": "authenticated"}';

-- Tester lecture commandes
SELECT * FROM orders;  -- Devrait voir seulement ses commandes

-- Revenir en admin
RESET ROLE;
*/


