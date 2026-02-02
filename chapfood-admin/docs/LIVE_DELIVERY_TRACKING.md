# Suivi des Livraisons en Temps Réel

## Vue d'ensemble

L'écran de suivi des livraisons en temps réel permet aux administrateurs de surveiller toutes les livraisons en cours sur un écran plein écran optimisé pour la surveillance continue.

## Fonctionnalités principales

### 📊 Tableau de bord en temps réel
- **Statistiques globales** : Nombre total de livraisons, en cours, assignées, livrées
- **Actualisation automatique** : Données mises à jour toutes les 10 secondes
- **Indicateur de dernière mise à jour** : Timestamp visible de la dernière actualisation

### 🚚 Suivi des livraisons
- **Vue d'ensemble** : Toutes les commandes avec statut `in_transit` ou `ready_for_delivery`
- **Informations détaillées** : Client, adresse, livreur assigné, statut
- **Position des livreurs** : Coordonnées GPS actuelles des livreurs
- **Timestamps** : Heures d'assignation, récupération, livraison

### 🎯 Mode plein écran
- **Bouton plein écran** : Passage en mode plein écran optimisé pour surveillance
- **Interface adaptée** : Layout optimisé pour écrans larges
- **Masquage de la sidebar** : Interface épurée en mode plein écran

### ⚡ Contrôles
- **Actualisation automatique** : Toggle pour activer/désactiver l'auto-refresh
- **Actualisation manuelle** : Bouton pour forcer la mise à jour
- **Indicateur de statut** : Animation de chargement pendant les mises à jour

## Utilisation

### Accéder à l'écran
1. Connectez-vous en tant qu'administrateur
2. Dans le menu de navigation, cliquez sur "Suivi des Livraisons" (icône MapPin)
3. L'écran s'affiche avec toutes les livraisons en cours

### Mode plein écran
1. Cliquez sur le bouton "Maximize" (⛶) en haut à droite
2. L'écran passe en mode plein écran
3. Pour revenir au mode normal, cliquez sur "Minimize" (⛶) ou appuyez sur Échap

### Gestion de l'actualisation
- **Auto-refresh activé** : Les données se mettent à jour automatiquement toutes les 10 secondes
- **Désactiver l'auto-refresh** : Cliquez sur "Actualisation auto" pour désactiver
- **Actualisation manuelle** : Cliquez sur "Actualiser maintenant" pour forcer une mise à jour

## Interface

### Statistiques globales
- **Total des livraisons** : Nombre total de commandes actives
- **En cours de livraison** : Commandes en transit avec livreur
- **Assignées aux livreurs** : Commandes assignées mais pas encore récupérées
- **Prêtes pour assignation** : Commandes prêtes mais sans livreur assigné

### Cartes de livraison
Chaque livraison est affichée dans une carte contenant :

#### Informations client
- Nom du client (ou "Client anonyme")
- Numéro de téléphone
- Adresse de livraison
- Heure de livraison prévue

#### Informations livreur (si assigné)
- Nom et photo du livreur
- Numéro de téléphone
- Position GPS actuelle
- Heures d'assignation et récupération

#### Informations commande
- Numéro de commande
- Montant total
- Statut avec badge coloré

### Badges de statut
- **Prête pour assignation** : Badge gris pour les commandes sans livreur
- **Assignée au livreur** : Badge bleu pour les commandes assignées
- **En cours de livraison** : Badge vert pour les livraisons en cours

## Optimisations pour plein écran

### Layout adaptatif
- **Grille responsive** : 1 colonne sur mobile, 2 sur tablette, 3 sur desktop
- **Cartes optimisées** : Taille et espacement adaptés pour la lisibilité
- **Typographie** : Tailles de police optimisées pour la distance de lecture

### Couleurs et contrastes
- **Badges colorés** : Codes couleur intuitifs pour les statuts
- **Arrière-plans** : Contrastes élevés pour la lisibilité
- **Animations** : Indicateurs visuels pour les états de chargement

## Intégration technique

### Données en temps réel
- **Requêtes Supabase** : Récupération des commandes avec leurs assignations
- **Jointures** : Relations avec les tables `drivers` et `order_driver_assignments`
- **Filtrage** : Seules les commandes `in_transit` et `ready_for_delivery`

### Performance
- **Actualisation optimisée** : Requêtes légères avec sélection de champs spécifiques
- **Gestion mémoire** : Nettoyage des intervalles lors du démontage
- **Cache** : Mise en cache des données pour réduire les requêtes

### Sécurité
- **Authentification admin** : Accès restreint aux administrateurs
- **Permissions** : Utilisation des politiques RLS de Supabase
- **Validation** : Vérification des données avant affichage

## Cas d'usage

### Surveillance opérationnelle
- **Salle de contrôle** : Affichage permanent sur écran dédié
- **Suivi en temps réel** : Surveillance continue des livraisons
- **Alertes visuelles** : Identification rapide des problèmes

### Gestion d'équipe
- **Répartition des tâches** : Vue d'ensemble pour optimiser les assignations
- **Suivi des performances** : Statistiques de livraison en temps réel
- **Communication** : Informations centralisées pour l'équipe

## Développement futur

### Fonctionnalités avancées
- **Notifications push** : Alertes en temps réel pour les événements critiques
- **Géolocalisation** : Intégration avec des cartes interactives
- **Historique** : Archive des livraisons passées
- **Rapports** : Export de données et statistiques

### Intégrations
- **API externes** : Connexion avec des services de géolocalisation
- **Webhooks** : Intégration avec d'autres systèmes
- **Mobile** : Application dédiée pour les livreurs

