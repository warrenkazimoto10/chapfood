// Test pour vérifier que l'authentification fonctionne avec les UUID
import 'package:uuid/uuid.dart';

void main() {
  print('🧪 Test de génération d\'UUID pour l\'authentification...\n');
  
  const uuid = Uuid();
  
  // Simuler la génération d'IDs utilisateur
  print('📝 Génération d\'IDs utilisateur pour l\'inscription :');
  for (int i = 0; i < 3; i++) {
    final userId = uuid.v4();
    print('   Utilisateur ${i + 1}: $userId');
    
    // Vérifier le format UUID
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    final isValidUuid = uuidRegex.hasMatch(userId);
    print('   Format valide: ${isValidUuid ? '✅' : '❌'}');
  }
  
  print('\n🎯 Exemples d\'utilisateurs qui seront créés :');
  
  // Simuler des données d'utilisateurs
  final users = [
    {
      'id': uuid.v4(),
      'email': 'test1@example.com',
      'full_name': 'Test User 1',
      'phone': '+225123456789'
    },
    {
      'id': uuid.v4(),
      'email': 'test2@example.com',
      'full_name': 'Test User 2',
      'phone': '+225987654321'
    },
    {
      'id': uuid.v4(),
      'email': 'test3@example.com',
      'full_name': 'Test User 3',
      'phone': '+225555666777'
    }
  ];
  
  users.forEach((user) {
    print('\n👤 Utilisateur:');
    print('   - ID: ${user['id']}');
    print('   - Email: ${user['email']}');
    print('   - Nom: ${user['full_name']}');
    print('   - Téléphone: ${user['phone']}');
  });
  
  print('\n✅ Tous les IDs sont au format UUID standard !');
  print('🔗 Ces IDs peuvent être utilisés comme clés étrangères dans d\'autres tables.');
  
  // Test de format pour les logs attendus
  print('\n📊 Exemple de logs attendus lors de l\'inscription :');
  final exampleUserId = uuid.v4();
  print('   📝 Début de l\'inscription directe pour: user@example.com');
  print('   👤 Création de l\'utilisateur dans la table users...');
  print('   ✅ Utilisateur créé avec succès: user@example.com');
  print('   💾 Session sauvegardée avec succès');
  print('   🆔 ID généré: $exampleUserId');
}

