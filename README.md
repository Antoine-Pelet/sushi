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

## Test local avec Tomcat 10.1

### Option la plus simple

Depuis la racine du projet:

```powershell
.\scripts\deploy-local.cmd -TomcatPath "C:\apache-tomcat-10.1.39" -LaunchTomcat
```

Attention: le chemin doit etre remplace par le vrai dossier Tomcat installe sur votre machine.

Exemples de dossiers valides:

- `C:\apache-tomcat-10.1.39`
- `C:\Program Files\Apache Software Foundation\Tomcat 10.1`
- `C:\Users\votre-nom\Downloads\apache-tomcat-10.1.39`

Si `CATALINA_HOME` ou `CATALINA_BASE` pointe deja vers Tomcat 10.1, vous pouvez aussi lancer simplement:

```powershell
.\scripts\deploy-local.cmd -LaunchTomcat
```

Si ces variables pointent encore vers Tomcat 9, le script les rejettera et vous demandera un `-TomcatPath` explicite vers Tomcat 10.1.

Puis ouvrir:

```text
http://localhost:8080/sushi/app
```

Si `8080` est deja occupe, le script demarre automatiquement une instance Tomcat 10.1 isolee sur `8081`, puis affiche l'URL exacte a ouvrir.

### Ce que fait le script

- compile les sources Java avec `javac`
- assemble une webapp exploitee dans `build\local\sushi`
- genere aussi `build\local\sushi.war`
- deploie l'application dans `webapps\sushi` du Tomcat cible
- utilise le stockage XML du projet: `src/main/webapp/WEB-INF/data/store.xml`

### Options utiles

- `-BuildOnly` : construit l'application sans la copier dans Tomcat
- `-ContextName ROOT` : deploie l'application en racine Tomcat
- `-PortOffset 1` : force Tomcat 10.1 a utiliser `8081`, `8006`, `8444`

Exemple build seul:

```powershell
.\scripts\deploy-local.cmd -TomcatPath "C:\apache-tomcat-10.1.39" -BuildOnly
```

Si vous deployez en `ROOT`, l'URL devient:

```text
http://localhost:8080/app
```

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
