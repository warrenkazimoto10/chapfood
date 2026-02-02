# Système de Permissions - Gestion du Stock

## Vue d'ensemble

Ce document décrit le nouveau système de permissions pour la gestion du stock, des catégories et des articles du menu dans l'application ChapFood Admin Hub.

## Architecture de Sécurité

### 1. Désactivation des RLS (Row Level Security)

Les règles RLS ont été désactivées sur les tables suivantes pour permettre une gestion libre par les administrateurs :

- `categories` - Catégories d'articles
- `menu_items` - Articles du menu
- `supplements` - Garnitures et suppléments
- `menu_item_supplements` - Relation articles-garnitures

### 2. Vérification Côté Client

La sécurité est maintenant gérée côté client avec vérification des rôles utilisateur :

- **admin_general** : Accès complet à toutes les fonctionnalités
- **cuisine** : Accès complet à la gestion du stock et du menu

## Composants de Permissions

### Hook useStockPermissions

```typescript
const permissions = useStockPermissions();

// Vérifications disponibles
permissions.canCreate    // Peut créer de nouveaux éléments
permissions.canEdit      // Peut modifier les éléments existants
permissions.canDelete    // Peut supprimer des éléments
permissions.canView      // Peut voir les éléments
permissions.isAdmin      // Est un administrateur général
permissions.isKitchen    // Est du personnel de cuisine
```

### Composant PermissionGuard

```typescript
<PermissionGuard requiredPermission="create">
  <Button>Ajouter un article</Button>
</PermissionGuard>
```

### Composant PermissionError

Affiche des messages d'erreur informatifs en cas de permissions insuffisantes.

## Service StockService

Le service `StockService` centralise toutes les opérations CRUD avec vérification automatique des permissions :

```typescript
// Création d'un article
await StockService.createMenuItem(itemData, permissions);

// Modification d'une catégorie
await StockService.updateCategory(id, updates, permissions);

// Suppression d'un supplément
await StockService.deleteSupplement(id, permissions);
```

## Migration de Base de Données

### Fichier : `20250822180000_disable_rls_categories_menu_items.sql`

Cette migration :
1. Désactive RLS sur les tables de stock
2. Crée des fonctions de vérification des rôles
3. Maintient la sécurité via les fonctions côté serveur

## Utilisation dans l'Interface

### Page AdminStock

La page de gestion du stock utilise maintenant :

1. **StockDashboard** : Affichage des statistiques avec actions contextuelles
2. **PermissionGuard** : Contrôle d'accès aux fonctionnalités
3. **StockService** : Opérations sécurisées sur la base de données

### Gestion des Erreurs

Les erreurs de permissions sont gérées de manière élégante avec :
- Messages d'erreur informatifs
- Affichage du rôle requis vs. rôle actuel
- Boutons de retry quand approprié

## Bonnes Pratiques

### 1. Vérification des Permissions

Toujours vérifier les permissions avant d'afficher ou d'exécuter des actions :

```typescript
if (!permissions.canEdit) {
  return <PermissionError requiredRole="cuisine" />;
}
```

### 2. Gestion des Erreurs

Utiliser le composant `PermissionError` pour une expérience utilisateur cohérente :

```typescript
try {
  await StockService.updateMenuItem(id, updates, permissions);
} catch (error) {
  if (error.message.includes('Accès refusé')) {
    setError('permission');
  }
}
```

### 3. Fallbacks UI

Toujours prévoir des alternatives pour les utilisateurs sans permissions :

```typescript
{permissions.canEdit ? (
  <EditButton />
) : (
  <span className="text-muted-foreground">Lecture seule</span>
)}
```

## Sécurité

### Avantages

- **Flexibilité** : Gestion fine des permissions côté client
- **Performance** : Pas de surcharge RLS sur les opérations de stock
- **UX** : Messages d'erreur clairs et actions contextuelles

### Considérations

- **Côté Client** : Les permissions sont vérifiées côté client
- **Authentification** : Dépend de la session admin valide
- **Audit** : Toutes les opérations sont tracées dans les logs Supabase

## Tests

### Vérification des Permissions

```typescript
// Test des permissions admin
const adminPermissions = useStockPermissions(); // admin_general
expect(adminPermissions.canCreate).toBe(true);
expect(adminPermissions.canDelete).toBe(true);

// Test des permissions cuisine
const kitchenPermissions = useStockPermissions(); // cuisine
expect(kitchenPermissions.canEdit).toBe(true);
expect(kitchenPermissions.isKitchen).toBe(true);
```

### Test des Opérations

```typescript
// Test de création avec permissions
await StockService.createMenuItem(itemData, permissions);

// Test de création sans permissions (doit échouer)
expect(() => 
  StockService.createMenuItem(itemData, { canCreate: false })
).toThrow('Accès refusé: permission de création requise');
```

## Maintenance

### Ajout de Nouvelles Tables

Pour ajouter de nouvelles tables au système de permissions :

1. Désactiver RLS dans une migration
2. Ajouter les méthodes dans `StockService`
3. Mettre à jour les interfaces TypeScript
4. Tester les permissions

### Modification des Rôles

Pour modifier les rôles autorisés :

1. Mettre à jour `useStockPermissions`
2. Modifier les composants de vérification
3. Tester avec différents rôles utilisateur
