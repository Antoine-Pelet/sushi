# Sushef

Application web Java Servlet autonome pour Tomcat.

## Fonctionnalites

- Connexion utilisateur
- Consultation des recettes
- Ajout / retrait des favoris
- Ajout / retrait au panier
- Passage de commande
- Administration des recettes
- Gestion des stocks
- API JSON couvrant les memes operations que l'interface web

## Comptes de demonstration

- Utilisateur: `demo / demo`
- Administrateur: `admin / admin`

## Donnees

- Stockage XML principal: `src/main/webapp/WEB-INF/data/store.xml`
- Aucune base externe requise

## Entree principale

- Interface web: `/app`
- Redirection automatique depuis `/`

## Exemples d'API

- `GET /api/recipes`
- `GET /api/me`
- `POST /api/session/login`
- `POST /api/favorites/toggle`
- `POST /api/cart/add`
- `POST /api/cart/remove`
- `POST /api/orders/checkout`
- `POST /api/admin/recipes/save`
- `POST /api/admin/recipes/delete`
- `POST /api/admin/products/save`

Les requetes `POST` utilisent des parametres de formulaire classiques (`application/x-www-form-urlencoded`), ce qui evite toute dependance JSON supplementaire cote serveur.

