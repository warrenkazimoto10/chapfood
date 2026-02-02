// Test pour vérifier la génération d'UUID
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();
  
  print('🧪 Test de génération d\'UUID...\n');
  
  // Générer plusieurs UUID pour vérifier le format
  for (int i = 0; i < 5; i++) {
    final generatedUuid = uuid.v4();
    print('UUID ${i + 1}: $generatedUuid');
    
    // Vérifier le format UUID v4
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    final isValidUuid = uuidRegex.hasMatch(generatedUuid);
    print('   Format valide: ${isValidUuid ? '✅' : '❌'}');
    print('   Longueur: ${generatedUuid.length} caractères');
    print('');
  }
  
  print('🎯 Exemples d\'UUID générés pour les utilisateurs:');
  final userUuids = List.generate(3, (index) => uuid.v4());
  userUuids.forEach((uuid) {
    print('   - $uuid');
  });
}

