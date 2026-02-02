# Système de Codes de Confirmation de Livraison

## Vue d'ensemble

Le système de codes de confirmation de livraison permet de sécuriser les livraisons en générant un code à 6 chiffres que le client doit donner au livreur pour confirmer la réception de sa commande.

## Fonctionnalités Implémentées

### 1. **Génération de Codes**
- Génération automatique d'un code à 6 chiffres aléatoire
- Code valide pendant 15 minutes
- Génération possible depuis l'interface admin

### 2. **Suivi des Statuts**
- **Pas de code** : Aucun code généré
- **Code actif** : Code généré et valide
- **Code expiré** : Code dépassé (plus de 15 minutes)
- **Confirmé** : Livraison validée par le client

### 3. **Interface Admin**
- Affichage du statut des codes dans la liste des commandes
- Section dédiée dans le modal de détail des commandes
- Gestion complète du cycle de vie des codes

## Structure de la Base de Données

### Nouveaux Champs (table `orders`)
```sql
delivery_code VARCHAR(6)                    -- Code à 6 chiffres
delivery_code_generated_at TIMESTAMP        -- Date de génération
delivery_code_expires_at TIMESTAMP          -- Date d'expiration (15 min)
delivery_confirmed_at TIMESTAMP             -- Date de confirmation
delivery_confirmed_by VARCHAR(255)          -- Qui a confirmé
```

### Fonctions SQL Créées
- `generate_delivery_code()` : Génère un code aléatoire
- `validate_delivery_code()` : Valide un code
- `confirm_delivery()` : Confirme une livraison
- `cleanup_expired_delivery_codes()` : Nettoie les codes expirés

## Interface Utilisateur

### Dans la Liste des Commandes
Une nouvelle colonne "Code livraison" affiche :
- 🗝️ **Pas de code** (gris)
- 🛡️ **Actif** (bleu)
- ⚠️ **Expiré** (rouge)
- ✅ **Confirmé** (vert)
- **N/A** (pour les commandes à emporter)

### Dans le Modal de Détail
Section complète avec :
- **Statut du code** avec badge coloré
- **Code généré** affiché en gros caractères
- **Bouton de copie** pour faciliter le partage
- **Informations temporelles** (généré le, expire le)
- **Compte à rebours** en temps réel
- **Confirmation de livraison** si validée
- **Instructions** pour le processus

## Workflow de Livraison

### 1. **Génération du Code**
```
Admin → Génère un code → Code affiché dans l'interface
```

### 2. **Processus Client-Livreur**
```
Client génère code → Donne code au livreur → Livreur valide → Livraison confirmée
```

### 3. **Suivi Admin**
```
Admin voit le statut → Peut regénérer si nécessaire → Suit les confirmations
```

## Code Implémenté

### Génération de Code
```typescript
const generateDeliveryCode = async () => {
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  
  await supabase.from('orders').update({
    delivery_code: code,
    delivery_code_generated_at: new Date().toISOString(),
    delivery_code_expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString()
  }).eq('id', order.id);
};
```

### Statut des Codes
```typescript
const getDeliveryCodeStatus = (order: Order) => {
  if (!order.delivery_code) return 'no_code';
  if (order.delivery_confirmed_at) return 'confirmed';
  if (new Date(order.delivery_code_expires_at) < new Date()) return 'expired';
  return 'active';
};
```

## Avantages

1. **Sécurité** : Confirmation obligatoire par le client
2. **Traçabilité** : Suivi complet des livraisons
3. **Flexibilité** : Codes avec expiration automatique
4. **Transparence** : Visibilité totale pour l'admin
5. **Simplicité** : Processus simple pour le client

## Cas d'Usage

### Livraison Normale
1. Admin génère un code
2. Client reçoit le code dans son app
3. Livreur arrive et demande le code
4. Client donne le code
5. Livreur valide → Statut "Confirmé"

### Code Expiré
1. Code généré il y a plus de 15 minutes
2. Admin voit le statut "Expiré"
3. Admin peut générer un nouveau code
4. Processus reprend

### Livraison Confirmée
1. Code validé avec succès
2. Statut passe à "Confirmé"
3. Timestamp de confirmation enregistré
4. Identifiant du livreur sauvegardé

## Fichiers Modifiés

1. **`src/components/admin/OrderDetailModal.tsx`**
   - Section complète de gestion des codes
   - Fonctions de génération et affichage
   - Interface utilisateur détaillée

2. **`src/pages/admin/AdminReservations.tsx`**
   - Nouvelle colonne "Code livraison"
   - Fonction de statut des codes
   - Interface mise à jour

3. **Base de données**
   - Nouveaux champs dans la table `orders`
   - Fonctions SQL pour la gestion des codes
   - Index pour l'optimisation

## Tests Recommandés

1. **Génération de code** : Vérifier la création et l'affichage
2. **Expiration** : Tester le passage en statut "Expiré"
3. **Confirmation** : Valider le processus de confirmation
4. **Interface** : Vérifier l'affichage des différents statuts
5. **Performance** : Tester avec de nombreuses commandes





