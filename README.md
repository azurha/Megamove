---

# MegaMove

**MegaMove** est une plateforme web de mise en relation entre particuliers souhaitant transporter des biens volumineux (voiture, moto, colis > 30kg, etc.) et des professionnels du transport.  
L’application offre une gestion complète du cycle de vie de la demande jusqu’au paiement, avec optimisation des trajets.

---

## 🚀 Fonctionnalités principales

- **Création de demandes de transport** (départ, arrivée, date, poids, description…)
- **Géolocalisation intelligente** avec autocomplétion d'adresses (Nominatim)
- **Calcul d'itinéraires optimisés** avec contraintes poids lourds (Valhalla)
- **Cartographie interactive** avec visualisation des trajets (Leaflet.js)
- **Réception et gestion de devis** côté client et transporteur
- **Comparaison des offres** et sélection du transporteur
- **Optimisation automatique des trajets** pour proposer les meilleurs tarifs et calcul automatique du coût
- **Gestion sécurisée des paiements en ligne & génération de factures**
- **Tableau de bord** pour les clients et les transporteurs
- **Notifications** (email, temps réel à venir)
- **Gestion des utilisateurs, sécurité et RGPD**

---

## 🛠️ Stack technique

- **Backend** : [Elixir](https://elixir-lang.org/) & [Phoenix Framework](https://www.phoenixframework.org/) 1.7+  
- **Frontend** : [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/) avec [Tailwind CSS](https://tailwindcss.com/)
- **Base de données** : PostgreSQL
- **Géolocalisation** : [Valhalla](https://github.com/valhalla/valhalla) (routage) + [Nominatim](https://nominatim.org/) (géocodage)
- **Cartographie** : [Leaflet.js](https://leafletjs.com/) avec [Mapbox Polyline](https://github.com/mapbox/polyline)
- **Paiement** : Stripe (à confirmer)
- **Déploiement** : Hetzner (à préciser)

---

## 🎨 Design System & Charte Graphique

### Palette de couleurs
- **Bleu foncé** : `#1E3A5F` (brand-dark-blue) - Navigation et éléments principaux
- **Bleu clair** : `#61A0FF` (brand-light-blue) - Accents et liens
- **Vert** : `#35C979` (brand-green) - Succès et validation
- **Gris clair** : `#F5F7FA` (brand-light-gray) - Arrière-plans
- **Gris moyen** : `#CCD6DD` (brand-medium-gray) - Bordures et séparateurs
- **Rouge** : `#FF4D4F` (brand-red) - Erreurs et alertes

### Typographie
- **Police principale** : [Inter](https://fonts.google.com/specimen/Inter) (400, 600, 700)
- **Approche** : Utility-first avec Tailwind CSS
- **Responsive** : Mobile-first design

### Composants UI
- **Boutons** : Styles cohérents (primary, secondary, danger)
- **Formulaires** : Champs avec validation en temps réel
- **Cartes** : Interface de transport avec géolocalisation
- **Icônes** : [Heroicons](https://heroicons.com/) v2.1.1

---

## 🔒 Sécurité

- Chiffrement des mots de passe (bcrypt)
- Authentification JWT ou session plug
- Protection CSRF, gestion des rôles
- RGPD-by-design

---

## 🗺️ Services de Géolocalisation

### Valhalla (Routage)
- **Calcul d'itinéraires** multi-profils (voiture, poids lourd, vélo, marche)
- **Optimisation de tournées** pour livraisons multiples
- **Contraintes logistiques** (évitement autoroutes, restrictions poids lourds)
- **Matrices de distance** pour calculs en lot
- **Isochrones** pour zones d'accessibilité

### Nominatim (Géocodage)
- **Forward Geocoding** : Adresse → Coordonnées GPS
- **Reverse Geocoding** : Coordonnées → Adresse
- **Autocomplétion** en temps réel avec debounce
- **Recherche multi-sources** (OSM, OpenAddresses, etc.)
- **Validation d'adresses** pour la logistique

### Leaflet.js (Cartographie)
- **Cartes interactives** avec marqueurs personnalisés
- **Visualisation d'itinéraires** avec polylines
- **Zoom et navigation** fluides
- **Responsive design** mobile/desktop
- **Intégration** avec les services de géolocalisation

---

## 💬 Contact

Pour toute question ou suggestion :  
📧 [contact@megamove.com](mailto:azurha21@icloud.com)  
👥 Issues & Discussions sur GitHub bienvenues !

---

