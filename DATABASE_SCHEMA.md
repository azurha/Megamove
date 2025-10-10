# Architecture de la Base de Données - MegaMove

## Vue d'ensemble

Ce document décrit l'architecture complète de la base de données pour la plateforme MegaMove, un marketplace logistique multi-tenant avec intégration d'itinéraires Valhalla.

### Principes architecturaux

- **Multi-tenant par organisation** : Toutes les entités métier sont rattachées à `org_id` avec contraintes composites
- **Isolation des données** : Utilisation de `with: [org_id: :org_id]` pour garantir la cohérence inter-tables
- **Scoping applicatif** : Toutes les requêtes filtrées par `@current_scope.user.org_id`
- **Normalisation** : Entités de base (utilisateurs, organisations), demandes de transport, arrêts, offres, réservation, suivi
- **Enum via check constraint** : Utilisation de contraintes CHECK pour les énumérations (portable)
- **Indexation optimisée** : Index sur clés étrangères, filtres usuels, et champs de recherche

---

## Tables existantes (phx.gen.auth)

### users
**Table d'authentification des utilisateurs**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `email` | CITEXT | NOT NULL, UNIQUE | Email utilisateur (insensible à la casse) |
| `hashed_password` | VARCHAR(255) | NULL | Mot de passe chiffré |
| `confirmed_at` | TIMESTAMP(0) | NULL | Date de confirmation email |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Index :**
- `users_email_index` UNIQUE sur `email`

### users_tokens
**Table des tokens d'authentification**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `user_id` | BIGINT | NOT NULL, FK → users(id) | Référence utilisateur |
| `token` | BYTEA | NOT NULL | Token chiffré |
| `context` | VARCHAR(255) | NOT NULL | Contexte du token (session, reset, etc.) |
| `sent_to` | VARCHAR(255) | NULL | Adresse de destination |
| `authenticated_at` | TIMESTAMP(0) | NULL | Date d'authentification |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |

**Index :**
- `users_tokens_user_id_index` sur `user_id`
- `users_tokens_context_token_index` UNIQUE sur `(context, token)`

---

## Tables à créer - Gestion des organisations

### organizations
**Table des organisations (multi-tenant)**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `name` | VARCHAR(255) | NOT NULL | Nom de l'organisation |
| `slug` | VARCHAR(255) | NOT NULL, UNIQUE | Identifiant URL-safe |
| `locale` | VARCHAR(10) | NOT NULL, DEFAULT 'fr-FR' | Locale par défaut |
| `currency` | VARCHAR(3) | NOT NULL, DEFAULT 'EUR' | Devise ISO 4217 |
| `settings` | JSONB | NULL | Paramètres organisation |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Index :**
- `organizations_slug_index` UNIQUE sur `slug`

### memberships
**Table de liaison utilisateurs-organisations**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `user_id` | BIGINT | NOT NULL, FK → users(id) | Référence utilisateur |
| `org_role` | VARCHAR(50) | NOT NULL, CHECK | Rôle dans l'organisation |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `memberships_org_id_user_id_index` UNIQUE sur `(org_id, user_id)`
- `org_role` CHECK IN ('owner', 'admin', 'dispatcher', 'driver', 'requester', 'viewer')

**Index :**
- `memberships_org_id_index` sur `org_id`
- `memberships_user_id_index` sur `user_id`

**Rôles et permissions :**

| Rôle | Description | Permissions |
|------|-------------|-------------|
| `owner` | Propriétaire de l'organisation | Contrôle total : gestion membres, paramètres, facturation, toutes opérations |
| `admin` | Administrateur | Gestion membres et paramètres, toutes opérations opérationnelles |
| `dispatcher` | Dispatcheur/Société de transport | Voir demandes org, créer/éditer devis, accepter/refuser, assigner missions |
| `driver` | Conducteur/Transporteur | Lire missions assignées, mettre à jour statuts, preuve de livraison |
| `requester` | Demandeur/Visiteur | Créer demandes, lire ses demandes/devis, accepter/refuser devis |
| `viewer` | Lecture seule | Lecture globale de l'organisation, pas d'écriture |

### carriers
**Table des transporteurs (optionnel - peut être intégré dans users)**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `legal_name` | VARCHAR(255) | NOT NULL | Raison sociale |
| `vat_number` | VARCHAR(50) | NULL | Numéro TVA |
| `dot_number` | VARCHAR(50) | NULL | Numéro DOT (US) |
| `contact_email` | VARCHAR(255) | NULL | Email de contact |
| `contact_phone` | VARCHAR(50) | NULL | Téléphone de contact |
| `status` | VARCHAR(50) | NOT NULL, CHECK | Statut du transporteur |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `carriers_org_id_vat_number_index` UNIQUE sur `(org_id, vat_number)` WHERE vat_number IS NOT NULL
- `status` CHECK IN ('active', 'suspended', 'pending')

**Index :**
- `carriers_org_id_index` sur `org_id`
- `carriers_status_index` sur `status`

---

## Tables à créer - Référentiel géographique

### places
**Table des lieux/adresses**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `label` | VARCHAR(255) | NOT NULL | Libellé convivial |
| `street` | VARCHAR(255) | NULL | Rue |
| `street2` | VARCHAR(255) | NULL | Complément d'adresse |
| `city` | VARCHAR(100) | NOT NULL | Ville |
| `postal_code` | VARCHAR(20) | NULL | Code postal |
| `state` | VARCHAR(100) | NULL | État/Région |
| `country_code` | VARCHAR(2) | NOT NULL | Code pays ISO 3166-1 |
| `lat` | DECIMAL(10, 8) | NULL | Latitude |
| `lng` | DECIMAL(11, 8) | NULL | Longitude |
| `geohash` | VARCHAR(12) | NULL | Encodage spatial |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Index :**
- `places_org_id_city_index` sur `(org_id, city)`
- `places_org_id_geohash_index` sur `(org_id, geohash)`
- `places_org_id_lat_lng_index` sur `(org_id, lat, lng)`

---

## Tables à créer - Demandes de transport

### transport_requests
**Table des demandes de transport**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `created_by_user_id` | BIGINT | NOT NULL, FK → users(id) | Créateur de la demande |
| `reference` | VARCHAR(100) | NULL | Référence externe |
| `status` | VARCHAR(50) | NOT NULL, CHECK | Statut de la demande |
| `shipment_type` | VARCHAR(50) | NOT NULL, CHECK | Type d'expédition |
| `cargo_description` | TEXT | NULL | Description de la marchandise |
| `cargo_weight_kg` | DECIMAL(10, 2) | NULL | Poids en kg |
| `cargo_volume_m3` | DECIMAL(10, 3) | NULL | Volume en m³ |
| `hazmat` | BOOLEAN | NOT NULL, DEFAULT false | Matières dangereuses |
| `temperature_control` | BOOLEAN | NOT NULL, DEFAULT false | Contrôle température |
| `pickup_earliest_at` | TIMESTAMP(0) | NULL | Début fenêtre retrait |
| `pickup_latest_at` | TIMESTAMP(0) | NULL | Fin fenêtre retrait |
| `delivery_earliest_at` | TIMESTAMP(0) | NULL | Début fenêtre livraison |
| `delivery_latest_at` | TIMESTAMP(0) | NULL | Fin fenêtre livraison |
| `requested_vehicle_type` | VARCHAR(50) | NULL | Type véhicule souhaité |
| `notes` | TEXT | NULL | Notes internes |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `transport_requests_org_id_reference_index` UNIQUE sur `(org_id, reference)` WHERE reference IS NOT NULL
- `status` CHECK IN ('draft', 'published', 'quoted', 'booked', 'cancelled', 'completed')
- `shipment_type` CHECK IN ('parcel', 'pallet', 'full_truck', 'container', 'other')

**Index :**
- `transport_requests_org_id_status_index` sur `(org_id, status)`
- `transport_requests_org_id_inserted_at_index` sur `(org_id, inserted_at DESC)`
- `transport_requests_created_by_user_id_index` sur `created_by_user_id`

### transport_request_stops
**Table des arrêts d'une demande de transport**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `transport_request_id` | BIGINT | NOT NULL, FK → transport_requests(id) | Référence demande |
| `position` | INTEGER | NOT NULL | Ordre dans l'itinéraire (1..N) |
| `place_id` | BIGINT | NULL, FK → places(id) | Référence lieu |
| `stop_type` | VARCHAR(50) | NOT NULL, CHECK | Type d'arrêt |
| `time_window_start` | TIMESTAMP(0) | NULL | Début fenêtre horaire |
| `time_window_end` | TIMESTAMP(0) | NULL | Fin fenêtre horaire |
| `instructions` | TEXT | NULL | Instructions spécifiques |
| `contact_name` | VARCHAR(255) | NULL | Nom du contact |
| `contact_phone` | VARCHAR(50) | NULL | Téléphone du contact |
| `contact_email` | VARCHAR(255) | NULL | Email du contact |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `transport_request_stops_org_id_transport_request_id_position_index` UNIQUE sur `(org_id, transport_request_id, position)`
- `stop_type` CHECK IN ('pickup', 'dropoff', 'waypoint')

**Index :**
- `transport_request_stops_org_id_transport_request_id_index` sur `(org_id, transport_request_id)`
- `transport_request_stops_org_id_stop_type_index` sur `(org_id, stop_type)`

---

## Tables à créer - Offres et réservations

### quotes
**Table des devis/offres des transporteurs**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `transport_request_id` | BIGINT | NOT NULL, FK → transport_requests(id) | Référence demande |
| `carrier_id` | BIGINT | NOT NULL, FK → carriers(id) | Référence transporteur |
| `price_cents` | INTEGER | NOT NULL | Prix en centimes |
| `currency` | VARCHAR(3) | NOT NULL, DEFAULT 'EUR' | Devise |
| `eta_pickup` | TIMESTAMP(0) | NULL | ETA retrait |
| `eta_delivery` | TIMESTAMP(0) | NULL | ETA livraison |
| `validity_expires_at` | TIMESTAMP(0) | NULL | Expiration de l'offre |
| `status` | VARCHAR(50) | NOT NULL, CHECK | Statut de l'offre |
| `notes` | TEXT | NULL | Notes du transporteur |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `quotes_org_id_transport_request_id_carrier_id_index` UNIQUE sur `(org_id, transport_request_id, carrier_id)`
- `status` CHECK IN ('proposed', 'withdrawn', 'accepted', 'expired', 'rejected')

**Index :**
- `quotes_org_id_transport_request_id_index` sur `(org_id, transport_request_id)`
- `quotes_org_id_status_index` sur `(org_id, status)`
- `quotes_carrier_id_index` sur `carrier_id`

### bookings
**Table des réservations confirmées**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `transport_request_id` | BIGINT | NOT NULL, FK → transport_requests(id) | Référence demande |
| `quote_id` | BIGINT | NOT NULL, FK → quotes(id) | Référence devis accepté |
| `booked_by_user_id` | BIGINT | NOT NULL, FK → users(id) | Utilisateur ayant réservé |
| `status` | VARCHAR(50) | NOT NULL, CHECK | Statut de la réservation |
| `booked_at` | TIMESTAMP(0) | NOT NULL | Date de réservation |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `bookings_org_id_transport_request_id_index` UNIQUE sur `(org_id, transport_request_id)`
- `status` CHECK IN ('booked', 'in_transit', 'delivered', 'cancelled', 'failed')

**Index :**
- `bookings_org_id_status_index` sur `(org_id, status)`
- `bookings_quote_id_index` sur `quote_id`
- `bookings_booked_by_user_id_index` sur `booked_by_user_id`

---

## Tables à créer - Flotte et exécution

### vehicles
**Table des véhicules**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `carrier_id` | BIGINT | NOT NULL, FK → carriers(id) | Référence transporteur |
| `vehicle_type` | VARCHAR(50) | NOT NULL, CHECK | Type de véhicule |
| `plate_number` | VARCHAR(20) | NOT NULL | Numéro d'immatriculation |
| `capacity_weight_kg` | DECIMAL(10, 2) | NULL | Capacité poids en kg |
| `capacity_volume_m3` | DECIMAL(10, 3) | NULL | Capacité volume en m³ |
| `pallets` | INTEGER | NULL | Nombre de palettes |
| `length_m` | DECIMAL(6, 2) | NULL | Longueur en mètres |
| `width_m` | DECIMAL(6, 2) | NULL | Largeur en mètres |
| `height_m` | DECIMAL(6, 2) | NULL | Hauteur en mètres |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `vehicles_org_id_plate_number_index` UNIQUE sur `(org_id, plate_number)`
- `vehicle_type` CHECK IN ('van', 'rigid', 'tractor', 'trailer', 'bike', 'other')

**Index :**
- `vehicles_org_id_carrier_id_index` sur `(org_id, carrier_id)`
- `vehicles_org_id_vehicle_type_index` sur `(org_id, vehicle_type)`

### assignments
**Table des affectations véhicule/conducteur**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `booking_id` | BIGINT | NOT NULL, FK → bookings(id) | Référence réservation |
| `vehicle_id` | BIGINT | NOT NULL, FK → vehicles(id) | Référence véhicule |
| `driver_user_id` | BIGINT | NULL, FK → users(id) | Référence conducteur |
| `status` | VARCHAR(50) | NOT NULL, CHECK | Statut de l'affectation |
| `planned_start_at` | TIMESTAMP(0) | NULL | Début planifié |
| `planned_end_at` | TIMESTAMP(0) | NULL | Fin planifiée |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `status` CHECK IN ('planned', 'en_route', 'arrived', 'completed', 'cancelled')

**Index :**
- `assignments_org_id_booking_id_index` sur `(org_id, booking_id)`
- `assignments_org_id_status_index` sur `(org_id, status)`
- `assignments_vehicle_id_index` sur `vehicle_id`
- `assignments_driver_user_id_index` sur `driver_user_id`

### tracking_events
**Table des événements de suivi**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `booking_id` | BIGINT | NOT NULL, FK → bookings(id) | Référence réservation |
| `assignment_id` | BIGINT | NULL, FK → assignments(id) | Référence affectation |
| `stop_id` | BIGINT | NULL, FK → transport_request_stops(id) | Référence arrêt |
| `event_type` | VARCHAR(50) | NOT NULL, CHECK | Type d'événement |
| `at` | TIMESTAMP(0) | NOT NULL | Horodatage événement |
| `lat` | DECIMAL(10, 8) | NULL | Latitude |
| `lng` | DECIMAL(11, 8) | NULL | Longitude |
| `accuracy_m` | DECIMAL(8, 2) | NULL | Précision en mètres |
| `details` | JSONB | NULL | Détails additionnels |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `event_type` CHECK IN ('departed', 'arrived', 'loaded', 'unloaded', 'delivered', 'exception', 'delay')

**Index :**
- `tracking_events_org_id_booking_id_at_index` sur `(org_id, booking_id, at)`
- `tracking_events_org_id_event_type_index` sur `(org_id, event_type)`
- `tracking_events_org_id_lat_lng_index` sur `(org_id, lat, lng)`

---

## Tables à créer - Intégration Valhalla

### routes
**Table des itinéraires calculés par Valhalla**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `context_type` | VARCHAR(50) | NOT NULL, CHECK | Type de contexte |
| `context_id` | BIGINT | NOT NULL | ID du contexte |
| `profile` | VARCHAR(50) | NOT NULL, CHECK | Profil Valhalla |
| `distance_m` | DECIMAL(12, 2) | NOT NULL | Distance en mètres |
| `duration_s` | DECIMAL(12, 2) | NOT NULL | Durée en secondes |
| `polyline` | TEXT | NULL | Géométrie encodée (polyline6) |
| `valhalla_params` | JSONB | NULL | Paramètres de la requête |
| `valhalla_raw_response` | JSONB | NULL | Réponse brute Valhalla |
| `computed_at` | TIMESTAMP(0) | NOT NULL | Date de calcul |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `context_type` CHECK IN ('transport_request', 'booking', 'assignment')
- `profile` CHECK IN ('auto', 'truck', 'bicycle', 'pedestrian')

**Index :**
- `routes_org_id_context_type_context_id_index` sur `(org_id, context_type, context_id)`
- `routes_org_id_computed_at_index` sur `(org_id, computed_at DESC)`

### route_waypoints
**Table des points de passage des itinéraires**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `route_id` | BIGINT | NOT NULL, FK → routes(id) | Référence itinéraire |
| `position` | INTEGER | NOT NULL | Ordre du point (1..N) |
| `place_id` | BIGINT | NULL, FK → places(id) | Référence lieu |
| `lat` | DECIMAL(10, 8) | NOT NULL | Latitude |
| `lng` | DECIMAL(11, 8) | NOT NULL | Longitude |
| `name` | VARCHAR(255) | NULL | Nom du point |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `route_waypoints_org_id_route_id_position_index` UNIQUE sur `(org_id, route_id, position)`

**Index :**
- `route_waypoints_org_id_route_id_index` sur `(org_id, route_id)`

### route_legs
**Table des tronçons des itinéraires**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `route_id` | BIGINT | NOT NULL, FK → routes(id) | Référence itinéraire |
| `position` | INTEGER | NOT NULL | Ordre du tronçon (1..N) |
| `distance_m` | DECIMAL(12, 2) | NOT NULL | Distance du tronçon en mètres |
| `duration_s` | DECIMAL(12, 2) | NOT NULL | Durée du tronçon en secondes |
| `summary` | TEXT | NULL | Résumé du tronçon |
| `polyline` | TEXT | NULL | Géométrie du tronçon |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `route_legs_org_id_route_id_position_index` UNIQUE sur `(org_id, route_id, position)`

**Index :**
- `route_legs_org_id_route_id_index` sur `(org_id, route_id)`

---

## Tables à créer - Tarification et facturation (optionnel)

### pricing_rules
**Table des règles de tarification**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `name` | VARCHAR(255) | NOT NULL | Nom de la règle |
| `vehicle_type` | VARCHAR(50) | NULL | Type de véhicule ciblé |
| `base_fee_cents` | INTEGER | NOT NULL, DEFAULT 0 | Frais de base en centimes |
| `per_km_cents` | INTEGER | NOT NULL, DEFAULT 0 | Prix par km en centimes |
| `per_minute_cents` | INTEGER | NOT NULL, DEFAULT 0 | Prix par minute en centimes |
| `min_fee_cents` | INTEGER | NOT NULL, DEFAULT 0 | Prix minimum en centimes |
| `active` | BOOLEAN | NOT NULL, DEFAULT true | Règle active |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Index :**
- `pricing_rules_org_id_active_index` sur `(org_id, active)`
- `pricing_rules_org_id_vehicle_type_index` sur `(org_id, vehicle_type)`

### invoices
**Table des factures**

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Identifiant unique |
| `org_id` | BIGINT | NOT NULL, FK → organizations(id) | Référence organisation |
| `booking_id` | BIGINT | NOT NULL, FK → bookings(id) | Référence réservation |
| `total_cents` | INTEGER | NOT NULL | Montant total en centimes |
| `currency` | VARCHAR(3) | NOT NULL, DEFAULT 'EUR' | Devise |
| `status` | VARCHAR(50) | NOT NULL, CHECK | Statut de la facture |
| `issued_at` | TIMESTAMP(0) | NULL | Date d'émission |
| `paid_at` | TIMESTAMP(0) | NULL | Date de paiement |
| `inserted_at` | TIMESTAMP(0) | NOT NULL | Date de création |
| `updated_at` | TIMESTAMP(0) | NOT NULL | Date de modification |

**Contraintes :**
- `invoices_org_id_booking_id_index` UNIQUE sur `(org_id, booking_id)`
- `status` CHECK IN ('draft', 'issued', 'paid', 'void')

**Index :**
- `invoices_org_id_status_index` sur `(org_id, status)`
- `invoices_booking_id_index` sur `booking_id`

---

## Contraintes multi-tenant

### Clés étrangères composites
Toutes les tables "enfant" utilisent des contraintes de clé étrangère composite pour garantir l'isolation des données :

```sql
-- Exemple pour transport_requests
FOREIGN KEY (org_id, transport_request_id) 
REFERENCES transport_requests(org_id, id)

-- En Ecto, cela se traduit par :
belongs_to :transport_request, TransportRequest,
  with: [org_id: :org_id]
```

### Scoping applicatif
Toutes les requêtes doivent être filtrées par `@current_scope.user.org_id` :

```elixir
# Exemple de requête scoped
def list_transport_requests(org_id) do
  from(tr in TransportRequest, where: tr.org_id == ^org_id)
  |> Repo.all()
end
```

---

## Index et performances

### Index systématiques
- **Clés étrangères** : `(org_id, foreign_key)`
- **Statuts** : `(org_id, status)`
- **Dates** : `(org_id, inserted_at DESC)`
- **Recherche** : `reference`, `plate_number`, `email`, `slug`

### Index géographiques
- **Proximité** : `(org_id, geohash)`
- **Coordonnées** : `(org_id, lat, lng)`
- **Événements de suivi** : `(org_id, lat, lng)` pour tracking_events

---

## Flux typiques

### Création d'une demande
1. `transport_requests` + `transport_request_stops`
2. Calcul `routes` à partir des stops via Valhalla
3. Transporteurs soumettent `quotes`
4. Client sélectionne et crée `bookings`
5. Affectation `assignments` + `vehicles`
6. Suivi via `tracking_events`

### Requêtes courantes
- **Demandes par statut** : `(org_id, status)`
- **Devis par demande** : `(org_id, transport_request_id)`
- **Réservations actives** : `(org_id, status IN ('booked', 'in_transit'))`
- **Événements récents** : `(org_id, booking_id, at DESC)`

---

## Évolutions futures

### PostGIS (optionnel)
Si besoins géographiques avancés :
- Remplacer `lat/lng` par `geometry(POINT, 4326)`
- Index spatial `GIST` sur les géométries
- Requêtes de proximité avec `ST_DWithin`

### Documents
- Table `documents` rattachée à `bookings`/`stops`
- Stockage de POD, CMR, photos
- Intégration avec stockage objet (S3, etc.)

### Intégrations
- Table `outbox_events` pour webhooks
- Intégrations TMS/ERP
- Notifications temps réel via PubSub

---

## Notes d'implémentation

### Migrations Ecto
- Utiliser `references/2` avec `with: [org_id: :org_id]`
- Ajouter `org_id` en premier dans les contraintes composites
- Prévoir les rollbacks pour les contraintes complexes

### Validation des données
- Valider les énumérations au niveau Ecto
- Utiliser `Ecto.Changeset.validate_inclusion/3`
- Contraintes de cohérence temporelle (fenêtres horaires)

### Sécurité
- Row Level Security (RLS) sur PostgreSQL
- Policies basées sur `org_id`
- Audit trail sur les modifications sensibles

---

*Ce document est maintenu à jour avec l'évolution de l'architecture. Dernière mise à jour : [Date actuelle]*
