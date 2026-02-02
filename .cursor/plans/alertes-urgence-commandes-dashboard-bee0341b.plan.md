---
name: "Plan : Restriction progressive des statuts dans l'app admin"
overview: ""
todos:
  - id: 203fa852-8f1b-482b-9cca-d943fd32f74e
    content: Transformer active_delivery_screen pour afficher une carte pleine écran avec Mapbox
    status: pending
  - id: 9f4c476c-f001-4468-b13e-f5fcac772baf
    content: Ajouter le marqueur du livreur (position en temps réel via DriverLocationService)
    status: pending
  - id: ddeb4c39-6d19-4a26-a83e-56d3c9a6a5cf
    content: Ajouter le marqueur du client (deliveryLat/deliveryLng de la commande)
    status: pending
  - id: 98e35cb1-4840-4d3a-a30f-f1956dbdac7f
    content: Calculer et afficher l'itinéraire entre livreur et client avec MapboxRoutingService
    status: pending
  - id: d4a544fa-8a10-4eff-9696-59f96d27e9de
    content: Ajouter un bottom sheet draggable avec les informations de commande et les boutons d'action
    status: pending
  - id: 5c60d12d-f548-41f3-be9d-0f9b01835e18
    content: Créer StatePersistenceService pour gérer la sauvegarde et restauration de l'état de livraison active
    status: pending
  - id: fb67b749-1181-4e26-9310-7bda41271856
    content: Créer ActiveDeliveryService pour gérer le cycle de vie complet d'une livraison
    status: pending
  - id: a876cda5-a693-4865-8e24-62d9db0fbca9
    content: Créer OrderStatusService pour la synchronisation temps réel des statuts
    status: pending
  - id: 84a147ca-f869-44b0-bb60-9c3f3b68f84a
    content: Créer DriverLocationService unifié pour la gestion GPS et itinéraires
    status: pending
  - id: f3a69374-af16-46e4-8135-b2a896622434
    content: Créer le modèle ActiveDeliveryState pour représenter l'état d'une livraison active
    status: pending
  - id: 4e531faf-7941-44db-967c-8c9be02511bc
    content: Créer DashboardScreen qui remplace home_screen avec restauration automatique de l'état
    status: pending
  - id: e120fef9-4aed-4d28-9215-4a3d718df810
    content: Créer ActiveDeliveryScreen pour l'écran dédié à la livraison active avec tous les boutons d'action
    status: pending
  - id: 79716def-ef49-4f1d-929c-24cf98dd18fb
    content: Créer les widgets pour delivery_status_card, delivery_actions_panel, arrived_confirmation_button, delivery_completion_modal
    status: pending
  - id: cff09294-f1a8-40f2-8c51-14157ac25820
    content: Ajouter la colonne arrived_at dans order_driver_assignments via migration SQL
    status: pending
  - id: 7a49688c-b147-46da-9523-64ab43efec58
    content: Mettre à jour OrderService avec markAsPickedUp, markAsArrived, completeDelivery
    status: pending
  - id: be8eed12-e8d2-44bd-827e-fcce750a6404
    content: Mettre à jour main.dart avec les nouvelles routes (dashboard_screen, active_delivery_screen)
    status: pending
  - id: b2c2734e-c4d6-4269-81ef-9d8031940201
    content: Supprimer les anciens écrans obsolètes (home_screen, enhanced_home_screen, simplified_home_screen)
    status: pending
  - id: 9fcb8dbe-6f56-4629-9502-b239f0709ec1
    content: Implémenter la synchronisation temps réel avec app client et admin via OrderStatusService
    status: pending
  - id: 7a34e2bd-da7d-4ae5-bcbb-b0e96926aa0d
    content: "Tester la persistance : démarrer livraison, éteindre téléphone, redémarrer, vérifier restauration"
    status: pending
  - id: efd4fbc4-878a-42a1-b087-9b3f081c72c0
    content: "Tester tous les boutons : récupérée, arrivé, finaliser avec QR/code"
    status: pending
  - id: 271ccc0c-2e25-4fed-b8bc-a7010ff101f2
    content: Créer StatePersistenceService pour gérer la sauvegarde et restauration de l'état de livraison active
    status: pending
  - id: 812789f3-c206-4ce6-8ebc-bf539315b218
    content: Créer ActiveDeliveryService pour gérer le cycle de vie complet d'une livraison
    status: pending
  - id: 012fd800-4704-49b1-8f07-028e382405e8
    content: Créer OrderStatusService pour la synchronisation temps réel des statuts
    status: pending
  - id: de6e66cf-58f6-40b9-b01d-a3f63ea6c222
    content: Créer DriverLocationService unifié pour la gestion GPS et itinéraires
    status: pending
  - id: 0445bcd4-8f5c-438b-9c4f-635939ca27e4
    content: Créer le modèle ActiveDeliveryState pour représenter l'état d'une livraison active
    status: pending
  - id: 4dda95b9-9c89-4457-aec2-f5f24b92a561
    content: Créer DashboardScreen qui remplace home_screen avec restauration automatique de l'état
    status: pending
  - id: 7d2d9ba8-82f2-4f71-9a79-0098e55c71f5
    content: Créer ActiveDeliveryScreen pour l'écran dédié à la livraison active avec tous les boutons d'action
    status: pending
  - id: 7efc3edd-a091-4e14-bfe4-9bba836cf5e3
    content: Créer les widgets pour delivery_status_card, delivery_actions_panel, arrived_confirmation_button, delivery_completion_modal
    status: pending
  - id: 43211fdd-e851-4924-9805-1dc7c71f4ef2
    content: Ajouter la colonne arrived_at dans order_driver_assignments via migration SQL
    status: pending
  - id: 814191fe-c00d-476f-9cf1-66f1ce2b7bf2
    content: Mettre à jour OrderService avec markAsPickedUp, markAsArrived, completeDelivery
    status: pending
  - id: 2cdd741a-0faf-4d3c-a8ab-7c19820bf737
    content: Mettre à jour main.dart avec les nouvelles routes (dashboard_screen, active_delivery_screen)
    status: pending
  - id: 49915cb7-66a9-48eb-84fd-5856208c49b5
    content: Supprimer les anciens écrans obsolètes (home_screen, enhanced_home_screen, simplified_home_screen)
    status: pending
  - id: 3b830129-ea64-46df-9762-c24a68c6c035
    content: Implémenter la synchronisation temps réel avec app client et admin via OrderStatusService
    status: pending
  - id: 6f3ff91f-1e27-4155-9171-b8496052a55e
    content: "Tester la persistance : démarrer livraison, éteindre téléphone, redémarrer, vérifier restauration"
    status: pending
  - id: 232bd4dd-e0b0-4b46-9aaf-f61a33965ecd
    content: "Tester tous les boutons : récupérée, arrivé, finaliser avec QR/code"
    status: pending
  - id: 72819c4b-641a-49dc-bf03-f83b88748c34
    content: Créer StatePersistenceService pour gérer la sauvegarde et restauration de l'état de livraison active
    status: pending
  - id: 4f95fa94-37a9-46eb-b613-546786ce2ab3
    content: Créer ActiveDeliveryService pour gérer le cycle de vie complet d'une livraison
    status: pending
  - id: 3afccd7b-db24-4b29-8489-d3ad56893aa4
    content: Créer OrderStatusService pour la synchronisation temps réel des statuts
    status: pending
  - id: 0411e053-3b89-477c-bde3-b5ce6a71d675
    content: Créer DriverLocationService unifié pour la gestion GPS et itinéraires
    status: pending
  - id: 8ddf81df-44f7-4dd7-abf8-50391c270ba7
    content: Créer le modèle ActiveDeliveryState pour représenter l'état d'une livraison active
    status: pending
  - id: 6c718ce4-3d7e-48e7-8525-43eed988c885
    content: Créer DashboardScreen qui remplace home_screen avec restauration automatique de l'état
    status: pending
  - id: f1edccd0-ef83-4bdd-8d2d-f1761003bb63
    content: Créer ActiveDeliveryScreen pour l'écran dédié à la livraison active avec tous les boutons d'action
    status: pending
  - id: e667afad-9940-484e-b8a3-7fbc77b5730c
    content: Créer les widgets pour delivery_status_card, delivery_actions_panel, arrived_confirmation_button, delivery_completion_modal
    status: pending
  - id: 4dbbc8d1-9801-47f2-99c9-ed650764b29d
    content: Ajouter la colonne arrived_at dans order_driver_assignments via migration SQL
    status: pending
  - id: 372d649e-1eab-426a-8bd0-4a56ffe44b79
    content: Mettre à jour OrderService avec markAsPickedUp, markAsArrived, completeDelivery
    status: pending
  - id: 5b7a5cda-f6b3-4cca-98e9-6c1728645c7f
    content: Mettre à jour main.dart avec les nouvelles routes (dashboard_screen, active_delivery_screen)
    status: pending
  - id: fe1dda1d-1646-468b-ac48-981c05897ddf
    content: Supprimer les anciens écrans obsolètes (home_screen, enhanced_home_screen, simplified_home_screen)
    status: pending
  - id: 9e6c6a8c-dfd5-43d9-a9b0-38b6dea5204b
    content: Implémenter la synchronisation temps réel avec app client et admin via OrderStatusService
    status: pending
  - id: 0ee889b8-7a1d-4bdf-8b93-cf27bd0c7555
    content: "Tester la persistance : démarrer livraison, éteindre téléphone, redémarrer, vérifier restauration"
    status: pending
  - id: a2306715-bc02-4a2b-b18b-664de84af54a
    content: "Tester tous les boutons : récupérée, arrivé, finaliser avec QR/code"
    status: pending
  - id: f2185cb1-306e-4853-a2f4-eba352f8824c
    content: Créer StatePersistenceService pour gérer la sauvegarde et restauration de l'état de livraison active
    status: pending
  - id: 34424347-2c29-4a2a-8056-eff6574fec4d
    content: Créer ActiveDeliveryService pour gérer le cycle de vie complet d'une livraison
    status: pending
  - id: 48b74199-0457-476d-9ddc-5fe16874b8f5
    content: Créer OrderStatusService pour la synchronisation temps réel des statuts
    status: pending
  - id: 809f2b45-68d3-4477-b119-dd0bc4d16c6a
    content: Créer DriverLocationService unifié pour la gestion GPS et itinéraires
    status: pending
  - id: 21a9ebf2-69ff-402c-a8c0-59476eab85c2
    content: Créer le modèle ActiveDeliveryState pour représenter l'état d'une livraison active
    status: pending
  - id: a80fe4d1-b6fe-49da-b8cd-5488b00201ea
    content: Créer DashboardScreen qui remplace home_screen avec restauration automatique de l'état
    status: pending
  - id: 4bac811d-fbf3-436b-b549-88a09321daf6
    content: Créer ActiveDeliveryScreen pour l'écran dédié à la livraison active avec tous les boutons d'action
    status: pending
  - id: 39a64f9e-0255-4a10-be9d-76e9c317a93c
    content: Créer les widgets pour delivery_status_card, delivery_actions_panel, arrived_confirmation_button, delivery_completion_modal
    status: pending
  - id: 3b2617b4-833a-4ac9-9d0e-52826056eb4a
    content: Ajouter la colonne arrived_at dans order_driver_assignments via migration SQL
    status: pending
  - id: 475b8358-3a98-46b2-92ab-50fcc285b2f7
    content: Mettre à jour OrderService avec markAsPickedUp, markAsArrived, completeDelivery
    status: pending
  - id: 109fe42d-d086-4194-b7d6-93ab0e78b317
    content: Mettre à jour main.dart avec les nouvelles routes (dashboard_screen, active_delivery_screen)
    status: pending
  - id: 81e866a9-959e-434f-969f-fea505a09487
    content: Supprimer les anciens écrans obsolètes (home_screen, enhanced_home_screen, simplified_home_screen)
    status: pending
  - id: 5848fd56-c0d1-4250-9696-6e9fd25ad8f7
    content: Implémenter la synchronisation temps réel avec app client et admin via OrderStatusService
    status: pending
  - id: ab8b9086-2e7d-4984-ad94-776560ce7aab
    content: "Tester la persistance : démarrer livraison, éteindre téléphone, redémarrer, vérifier restauration"
    status: pending
  - id: 3b7b6267-e34a-46c6-beb4-ba94a391e4a2
    content: "Tester tous les boutons : récupérée, arrivé, finaliser avec QR/code"
    status: pending
  - id: d4b829f7-99ea-4869-8e16-0e8139bfab01
    content: Créer StatePersistenceService pour gérer la sauvegarde et restauration de l'état de livraison active
    status: pending
  - id: a80c291e-c1bc-4c0e-8940-6f337c11fdb0
    content: Créer ActiveDeliveryService pour gérer le cycle de vie complet d'une livraison
    status: pending
  - id: 1c81d20a-c504-4573-b374-e424bf377f8a
    content: Créer OrderStatusService pour la synchronisation temps réel des statuts
    status: pending
  - id: 8a1ab129-039c-49aa-93e1-12d60192d658
    content: Créer DriverLocationService unifié pour la gestion GPS et itinéraires
    status: pending
  - id: f142b9f6-fba8-49e2-9379-79b8c22af4ab
    content: Créer le modèle ActiveDeliveryState pour représenter l'état d'une livraison active
    status: pending
  - id: 77aa043d-3a5f-4026-b52f-32bb0155c559
    content: Créer DashboardScreen qui remplace home_screen avec restauration automatique de l'état
    status: pending
  - id: aee4d7aa-0871-4acf-98e3-f9a62eaf4c3b
    content: Créer ActiveDeliveryScreen pour l'écran dédié à la livraison active avec tous les boutons d'action
    status: pending
  - id: 00449d49-7d62-4bed-84f3-2817a88bf5fc
    content: Créer les widgets pour delivery_status_card, delivery_actions_panel, arrived_confirmation_button, delivery_completion_modal
    status: pending
  - id: e68d7c9f-ed5f-4e04-a1a7-48084443db78
    content: Ajouter la colonne arrived_at dans order_driver_assignments via migration SQL
    status: pending
  - id: 6a645738-eb3c-4007-a2d8-fc27f8a35e25
    content: Mettre à jour OrderService avec markAsPickedUp, markAsArrived, completeDelivery
    status: pending
  - id: 89577c91-5f9c-4e4c-8e3d-ec9b21353896
    content: Mettre à jour main.dart avec les nouvelles routes (dashboard_screen, active_delivery_screen)
    status: pending
  - id: 7afb34b0-3352-40e6-80e5-3f55b82112bd
    content: Supprimer les anciens écrans obsolètes (home_screen, enhanced_home_screen, simplified_home_screen)
    status: pending
  - id: 953286fa-c6ff-4885-bd11-1fc41221a843
    content: Implémenter la synchronisation temps réel avec app client et admin via OrderStatusService
    status: pending
  - id: 93613863-5847-4b16-8c8d-1c90b8ba6d7b
    content: "Tester la persistance : démarrer livraison, éteindre téléphone, redémarrer, vérifier restauration"
    status: pending
  - id: bca849d4-586f-43df-b6d9-cf01539877c8
    content: "Tester tous les boutons : récupérée, arrivé, finaliser avec QR/code"
    status: pending
---

# Plan : Restriction progressive des statuts dans l'app admin

## Objectif

Restreindre les statuts disponibles selon le statut actuel de la commande, en affichant uniquement les transitions valides avec des boutons d'action clairs.

## Workflow des statuts

### 1. **pending** (En attente)

- **Actions disponibles** : 
  - ✅ Accepter → `accepted`
  - ❌ Refuser → `cancelled`

### 2. **accepted** (Acceptée - vers restaurant)

- **Actions disponibles** :
  - ✅ Prête pour livraison → `ready_for_delivery`
  - ❌ Annuler → `cancelled`

### 3. **ready_for_delivery** (Prête pour livraison)

- **Actions disponibles** :
  - ✅ Repas récupéré → `picked_up` (si livreur assigné)
  - ⚠️ Assigner un livreur (si pas encore assigné)

### 4. **picked_up** (Repas récupéré - vers client)

- **Actions disponibles** :
  - ✅ En cours de livraison → `in_transit`
  - ❌ Annuler → `cancelled` (rare, mais possible)

### 5. **in_transit** (En cours de livraison)

- **Actions disponibles** :
  - ✅ Livrée → `delivered`
  - ❌ Annuler → `cancelled` (rare, mais possible)

### 6. **delivered** (Livrée)

- **Aucune action** : Statut final

### 7. **cancelled** (Annulée)

- **Aucune action** : Statut final

## Implémentation

### Fichiers à modifier

- `chapfood-admin/src/components/admin/OrderDetailModal.tsx`

### Changements à apporter

1. **Créer une fonction `getAvailableStatusTransitions()`**

   - Prend le statut actuel en paramètre
   - Retourne la liste des statuts valides suivants
   - Gère les cas spéciaux (livreur assigné, etc.)

2. **Remplacer le Select par des boutons d'action**

   - Afficher uniquement les boutons pour les transitions valides
   - Style différent pour chaque type d'action (accepter = vert, refuser = rouge, etc.)
   - Désactiver les boutons si les conditions ne sont pas remplies (ex: pas de livreur)

3. **Améliorer l'UX**

   - Afficher clairement le statut actuel
   - Montrer les prochaines étapes possibles
   - Messages d'aide contextuels (ex: "Assignez un livreur d'abord")

4. **Gérer les cas spéciaux**

   - Vérifier si un livreur est assigné avant d'autoriser `picked_up` ou `in_transit`
   - Empêcher les retours en arrière (ex: de `delivered` vers `pending`)

## Structure proposée

```typescript
const getAvailableTransitions = (currentStatus: string, hasDriver: boolean) => {
  switch (currentStatus) {
    case 'pending':
      return [
        { value: 'accepted', label: 'Accepter', variant: 'success' },
        { value: 'cancelled', label: 'Refuser', variant: 'destructive' }
      ];
    case 'accepted':
      return [
        { value: 'ready_for_delivery', label: 'Prête pour livraison', variant: 'default' },
        { value: 'cancelled', label: 'Annuler', variant: 'destructive' }
      ];
    // ... etc
  }
}
```

## Avantages

- Workflow clair et guidé
- Réduction des erreurs (impossible de sauter des étapes)
- Meilleure UX avec des boutons au lieu d'un Select
- Conformité avec le workflow métier réel