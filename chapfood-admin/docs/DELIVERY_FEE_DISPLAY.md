# Affichage des Frais de Livraison dans le Modal de Commande

## Vue d'ensemble

Le modal de détail des commandes affiche maintenant un détail complet des prix, incluant les frais de livraison pour les commandes de livraison.

## Fonctionnalités Ajoutées

### 1. **Détail des Prix**
Le modal affiche maintenant :
- **Sous-total** : Montant des articles sans les frais
- **Frais de livraison** : Affiché uniquement pour les livraisons (avec icône camion)
- **Total** : Montant final incluant tous les frais

### 2. **Affichage Conditionnel**
- Les frais de livraison ne s'affichent que si :
  - `delivery_type === 'delivery'`
  - `delivery_fee` est défini et non null
- Pour les commandes à emporter, seuls le sous-total et le total sont affichés

## Interface Utilisateur

### Pour une Livraison
```
Articles commandés
├── Article 1: 15,000 FCFA
├── Article 2: 12,500 FCFA
└── Article 3: 8,000 FCFA
─────────────────────────
Sous-total: 35,500 FCFA
🚚 Frais de livraison: 3,500 FCFA
─────────────────────────
Total: 39,000 FCFA
```

### Pour une Commande à Emporter
```
Articles commandés
├── Article 1: 15,000 FCFA
├── Article 2: 12,500 FCFA
└── Article 3: 8,000 FCFA
─────────────────────────
Sous-total: 35,500 FCFA
─────────────────────────
Total: 35,500 FCFA
```

## Structure de la Base de Données

### Champs Utilisés (table `orders`)
- `subtotal` : Montant des articles sans frais
- `delivery_fee` : Frais de livraison (null pour les commandes à emporter)
- `total_amount` : Montant total incluant tous les frais
- `delivery_type` : Type de commande ('delivery' ou 'pickup')

## Code Implémenté

### Dans `OrderDetailModal.tsx`
```typescript
{/* Détail des prix */}
<div className="space-y-2">
  <div className="flex justify-between items-center">
    <span>Sous-total</span>
    <span>{formatPrice(order.subtotal || 0)}</span>
  </div>
  
  {order.delivery_type === 'delivery' && order.delivery_fee && (
    <div className="flex justify-between items-center">
      <span className="flex items-center gap-1">
        <Truck className="h-3 w-3" />
        Frais de livraison
      </span>
      <span>{formatPrice(order.delivery_fee)}</span>
    </div>
  )}
  
  <Separator />
  
  <div className="flex justify-between items-center text-lg font-semibold">
    <span>Total</span>
    <span>{formatPrice(order.total_amount)}</span>
  </div>
</div>
```

### Interface Mise à Jour
```typescript
interface Order {
  // ... autres champs
  subtotal: number;
  delivery_fee: number | null;
  total_amount: number;
  delivery_type: string;
  // ... autres champs
}
```

## Avantages

1. **Transparence** : Le client voit clairement le détail des frais
2. **Clarté** : Distinction entre prix des articles et frais de service
3. **Flexibilité** : Affichage adapté selon le type de commande
4. **Professionnalisme** : Interface détaillée et claire

## Cas d'Usage

### Livraison avec Frais
- Sous-total : 25,000 FCFA
- Frais de livraison : 2,500 FCFA
- **Total : 27,500 FCFA**

### Livraison Gratuite
- Sous-total : 25,000 FCFA
- Frais de livraison : 0 FCFA (affiché)
- **Total : 25,000 FCFA**

### Commande à Emporter
- Sous-total : 25,000 FCFA
- (Pas de frais de livraison)
- **Total : 25,000 FCFA**

## Fichiers Modifiés

1. **`src/components/admin/OrderDetailModal.tsx`**
   - Ajout du détail des prix avec frais de livraison
   - Affichage conditionnel selon le type de commande

2. **`src/pages/admin/AdminReservations.tsx`**
   - Mise à jour de l'interface Order pour inclure subtotal et delivery_fee

## Tests Recommandés

1. **Commande de livraison avec frais** : Vérifier l'affichage des frais
2. **Commande de livraison sans frais** : Vérifier que les frais ne s'affichent pas
3. **Commande à emporter** : Vérifier l'absence des frais de livraison
4. **Calculs** : Vérifier que sous-total + frais = total


