# Gestion des Commandes - Modal de Détail

## Vue d'ensemble

Le modal de détail des commandes permet aux administrateurs de visualiser toutes les informations d'une commande et de gérer son statut selon le flux suivant :

**Flux des statuts :** `pending → accepted → ready_for_delivery → in_transit → delivered`

## Fonctionnalités

### 1. Visualisation des détails
- **Informations client** : nom, téléphone, adresse de livraison
- **Informations commande** : type de livraison, méthode de paiement, heure prévue
- **Articles commandés** : liste détaillée avec quantités, prix et suppléments
- **Instructions spéciales** : notes du client
- **Livreur assigné** : affichage du livreur assigné à la commande

### 2. Gestion des statuts
Les administrateurs peuvent changer le statut d'une commande avec les options suivantes :

| Statut | Description | Couleur | Prérequis |
|--------|-------------|---------|-----------|
| `pending` | En attente | Jaune | - |
| `accepted` | Acceptée | Bleu | - |
| `ready_for_delivery` | Prête pour livraison | Vert | - |
| `in_transit` | En cours de livraison | Violet | **Livreur assigné obligatoire** |
| `delivered` | Livrée | Vert émeraude | - |
| `cancelled` | Annulée | Rouge | - |

### 3. Gestion des livreurs
- **Affichage des livreurs disponibles** : Liste des livreurs actifs et disponibles (sans livraison en cours)
- **Assignation automatique** : Quand un livreur est assigné, le statut passe automatiquement à "in_transit"
- **Vérification des assignations** : Le système vérifie si la commande a déjà un livreur assigné
- **Notifications livreur** : Le livreur reçoit une notification quand une commande lui est assignée

### 4. Notifications automatiques
- Mise à jour automatique des timestamps selon le statut
- Création de notifications pour le client (si des notes sont ajoutées)
- Notifications pour les livreurs lors de l'assignation
- Rechargement automatique de la liste des commandes

## Utilisation

### Accéder au modal
1. Allez dans la page "Gestion des Commandes" (`/admin/reservations`)
2. Cliquez sur l'icône "œil" (👁️) dans la colonne "Actions"
3. Le modal s'ouvre avec tous les détails de la commande

### Changer le statut
1. Dans le modal, section "Gestion du statut"
2. Sélectionnez le nouveau statut dans le menu déroulant
3. **Si le statut est "ready_for_delivery"** : Un card s'affiche avec les livreurs disponibles
4. **Pour passer à "in_transit"** : Vous devez d'abord assigner un livreur
5. Ajoutez des notes optionnelles
6. Cliquez sur "Mettre à jour le statut"

### Assigner un livreur
1. Quand le statut est "ready_for_delivery", le card "Livreurs disponibles" s'affiche
2. La liste montre tous les livreurs actifs et disponibles (sans livraison en cours)
3. Cliquez sur "Assigner" à côté du livreur souhaité
4. Le statut passe automatiquement à "in_transit"
5. Le livreur reçoit une notification de la nouvelle assignation

### Fermer le modal
- Cliquez sur "Fermer" ou sur la croix (X) en haut à droite

## Intégration technique

### Composants
- `OrderDetailModal.tsx` : Modal principal de détail
- `AdminReservations.tsx` : Page d'administration mise à jour

### Base de données
- Migration `20250124000000_update_order_status_enum.sql` : Ajoute les nouveaux statuts
- Mise à jour automatique des timestamps (`accepted_at`, `ready_at`, `actual_delivery_time`)
- Gestion des assignations livreur-commande via `order_driver_assignments`
- Notifications automatiques pour livreurs et clients

### Types TypeScript
- Mise à jour de `src/integrations/supabase/types.ts` avec les nouveaux statuts

## Notes importantes

1. **Compatibilité** : Les anciens statuts sont toujours supportés pour la compatibilité
2. **Permissions** : Seuls les administrateurs peuvent modifier les statuts
3. **Notifications** : Les notifications clients sont créées seulement si des notes sont ajoutées
4. **Timestamps** : Chaque changement de statut met à jour automatiquement les timestamps appropriés
5. **Livreurs** : Le statut "in_transit" ne peut être sélectionné que si un livreur est assigné
6. **Disponibilité** : Seuls les livreurs actifs et disponibles (sans livraison en cours) sont affichés
7. **Assignation automatique** : L'assignation d'un livreur met automatiquement le statut à "in_transit"

## Développement futur

- Ajout de notifications push en temps réel
- Intégration avec le système de livraison
- Historique des changements de statut
- Rapports de performance des commandes
