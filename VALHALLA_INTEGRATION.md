# 🚀 Intégration Valhalla - Megamove

Ce document décrit l'intégration de Valhalla dans l'application Megamove pour l'optimisation d'itinéraires dans le marketplace de transport.

## 📋 Vue d'ensemble

Valhalla est un moteur de routage open-source développé par Mapzen qui fournit des fonctionnalités avancées pour :
- Le calcul d'itinéraires simples et optimisés
- L'optimisation de tournées (TSP - Traveling Salesman Problem)
- Le calcul d'isochrones (zones accessibles en temps/distance)
- Les matrices de distances entre sources et destinations
- Le géocodage et géocodage inverse

## 🏗️ Architecture

### Modules créés

1. **`Megamove.ValhallaService`** - Service principal d'intégration
2. **`Megamove.Valhalla.Types`** - Types et structures de données
3. **`MegamoveWeb.ValhallaDemoLive`** - Interface de démonstration

### Configuration

La configuration Valhalla est définie dans `config/config.exs` :

```elixir
config :megamove, :valhalla,
  base_url: "http://localhost:8002",
  timeout: 30_000,
  retry_attempts: 3,
  retry_delay: 1000
```

## 🚀 Fonctionnalités disponibles

### 1. Calcul d'itinéraires simples

```elixir
# Itinéraire entre deux points
locations = [{48.8566, 2.3522}, {48.8606, 2.3376}]
{:ok, result} = Megamove.ValhallaService.route(locations)

# Avec mode de transport spécifique
{:ok, result} = Megamove.ValhallaService.route(locations, costing: "bicycle")
```

### 2. Optimisation d'itinéraires (TSP)

```elixir
# Optimisation pour plusieurs points
locations = [
  {48.8566, 2.3522}, 
  {48.8606, 2.3376}, 
  {48.8584, 2.2945}
]
{:ok, result} = Megamove.ValhallaService.optimized_route(locations)
```

### 3. Calcul d'isochrones

```elixir
# Isochrone basée sur le temps
location = {48.8566, 2.3522}
contours = [%{time: 15}]
{:ok, result} = Megamove.ValhallaService.isochrone(location, contours)

# Isochrone basée sur la distance
contours = [%{distance: 5}]
{:ok, result} = Megamove.ValhallaService.isochrone(location, contours)
```

### 4. Matrices de distances

```elixir
sources = [{48.8566, 2.3522}, {48.8606, 2.3376}]
targets = [{48.8584, 2.2945}, {48.8522, 2.3376}]
{:ok, result} = Megamove.ValhallaService.sources_to_targets(sources, targets)
```

### 5. Géocodage inverse

```elixir
location = {48.8566, 2.3522}
{:ok, result} = Megamove.ValhallaService.reverse_geocode(location)
```

## 🎯 Cas d'usage pour le marketplace

### 1. Optimisation des tournées des transporteurs

Les transporteurs peuvent optimiser leurs trajets pour minimiser :
- La distance totale parcourue
- Le temps de trajet
- La consommation de carburant
- Les coûts opérationnels

### 2. Calcul des zones de service

Les isochrones permettent de :
- Définir les zones couvertes par chaque transporteur
- Calculer les frais de livraison basés sur la distance
- Optimiser la répartition géographique des transporteurs

### 3. Estimation des coûts

Les matrices de distances permettent de :
- Calculer automatiquement les coûts de transport
- Comparer les offres de différents transporteurs
- Optimiser la sélection des transporteurs

### 4. Planification intelligente

L'optimisation TSP permet de :
- Planifier les tournées de collecte/livraison
- Minimiser les temps de trajet
- Améliorer l'efficacité opérationnelle

## 🧪 Tests

### Tests unitaires

```bash
mix test test/megamove/valhalla_service_test.exs
```

### Test d'intégration complet

```bash
elixir test_valhalla_integration.exs
```

## 🌐 Interface de démonstration

Une interface de démonstration est disponible à l'adresse :
```
http://localhost:4000/valhalla-demo
```

Cette interface permet de :
- Ajouter des points de coordonnées
- Tester les différents types de calculs
- Visualiser les résultats en temps réel
- Comprendre les capacités de Valhalla

## 🔧 Configuration du serveur Valhalla

### Installation locale

1. Télécharger Valhalla depuis [GitHub](https://github.com/valhalla/valhalla)
2. Compiler et installer
3. Télécharger les données OpenStreetMap
4. Démarrer le serveur :

```bash
valhalla_service valhalla.json
```

### Configuration Docker

```yaml
version: '3'
services:
  valhalla:
    image: gisops/valhalla:latest
    ports:
      - "8002:8002"
    volumes:
      - ./valhalla_data:/data
    command: valhalla_service /data/valhalla.json
```

## 📊 Performance

### Métriques typiques

- **Calcul d'itinéraire simple** : ~100-500ms
- **Optimisation TSP (5 points)** : ~1-3s
- **Calcul d'isochrone** : ~200-800ms
- **Matrice 10x10** : ~2-5s

### Optimisations

- Mise en cache des résultats fréquents
- Calculs asynchrones pour les opérations longues
- Retry automatique en cas d'échec
- Timeout configurable

## 🚨 Gestion d'erreurs

Le service gère automatiquement :
- Les erreurs de réseau
- Les timeouts
- Les erreurs de format de données
- Les erreurs de serveur Valhalla

```elixir
case Megamove.ValhallaService.route(locations) do
  {:ok, result} -> 
    # Traitement du résultat
  {:error, reason} -> 
    # Gestion de l'erreur
end
```

## 🔮 Évolutions futures

### Fonctionnalités prévues

1. **Support multimodal** - Intégration des transports en commun
2. **Calculs en temps réel** - Prise en compte du trafic
3. **Optimisation avancée** - Contraintes personnalisées
4. **Intégration cartographique** - Visualisation des itinéraires
5. **API REST** - Endpoints pour l'application mobile

### Intégrations possibles

- **OpenStreetMap** - Données cartographiques
- **Google Maps** - Géocodage et visualisation
- **Mapbox** - Cartes interactives
- **PostGIS** - Base de données géospatiale

## 📚 Ressources

- [Documentation Valhalla](https://github.com/valhalla/valhalla)
- [API Reference](https://github.com/valhalla/valhalla/blob/master/docs/api/turn-by-turn/api-reference.md)
- [OpenStreetMap](https://www.openstreetmap.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)

## 🤝 Contribution

Pour contribuer à l'intégration Valhalla :

1. Fork le projet
2. Créer une branche feature
3. Implémenter les modifications
4. Ajouter les tests
5. Créer une Pull Request

## 📄 Licence

Ce projet utilise la licence MIT. Valhalla est sous licence MIT également.
