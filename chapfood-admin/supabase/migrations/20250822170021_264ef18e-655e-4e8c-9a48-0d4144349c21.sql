-- Créer un administrateur général pour ChapFood
SELECT create_admin_user(
  'admin@chapfood.com',
  'admin123',
  'admin_general',
  'Administrateur ChapFood'
);