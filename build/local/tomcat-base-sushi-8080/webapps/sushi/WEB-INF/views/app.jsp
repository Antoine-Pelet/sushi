<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.text.DecimalFormat,java.util.*,sushi.*,sushi.SushiService.DashboardData" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private int parseIntOrDefault(String value, int defaultValue) {
        if (value == null || value.isBlank()) return defaultValue;
        try { return Integer.parseInt(value.trim()); } catch (NumberFormatException exception) { return defaultValue; }
    }

    private List<String> splitSteps(String text) {
        List<String> steps = new ArrayList<>();
        if (text == null || text.isBlank()) return steps;
        for (String rawLine : text.split("\\r?\\n")) {
            String line = rawLine.trim();
            if (line.isEmpty()) continue;
            steps.add(line.replaceFirst("^\\d+\\)\\s*", ""));
        }
        if (steps.isEmpty()) steps.add(text.trim());
        return steps;
    }

    private int prepMinutes(Recette recette) {
        if (recette == null) return 0;
        return Math.max(20, recette.getIngredients().size() * 4);
    }

    private int difficulty(Recette recette) {
        if (recette == null) return 1;
        return Math.max(1, Math.min(5, (int) Math.ceil(recette.getIngredients().size() / 2.0)));
    }

    private int countCartItems(User user) {
        if (user == null) return 0;
        int total = 0;
        for (PanierItem item : user.getPanier()) total += item.getQuantite();
        return total;
    }

    private int quantityInCart(User user, int recipeId) {
        if (user == null) return 0;
        for (PanierItem item : user.getPanier()) if (item.getRecetteId() == recipeId) return item.getQuantite();
        return 0;
    }

    private String initials(User user) {
        if (user == null || user.getUsername() == null || user.getUsername().isBlank()) return "G";
        return user.getUsername().substring(0, 1).toUpperCase(Locale.ROOT);
    }

    private String recipeVariant(int recipeId) {
        int mod = Math.floorMod(recipeId, 3);
        if (mod == 0) return "recipe-visual--left";
        if (mod == 1) return "recipe-visual--center";
        return "recipe-visual--right";
    }

    private String stepChef(int index) {
        int mod = Math.floorMod(index, 4);
        if (mod == 1) return "sushef-focused.png";
        if (mod == 2) return "sushef-right.png";
        if (mod == 3) return "sushef-calm.png";
        return "sushef-happy.png";
    }
%>
<%
    DashboardData dashboard = (DashboardData) request.getAttribute("dashboard");
    User currentUser = dashboard.currentUser();
    List<Recette> recettes = dashboard.recettes();
    List<Produit> produits = dashboard.produits();
    List<Commande> userCommandes = dashboard.userCommandes();
    List<Commande> allCommandes = dashboard.allCommandes();
    Map<Integer, Integer> disponibilites = dashboard.disponibilites();
    Recette recetteEdition = dashboard.recetteEdition();
    String flashType = (String) request.getAttribute("flashType");
    String flashMessage = (String) request.getAttribute("flashMessage");
    String ctx = request.getContextPath();
    DecimalFormat money = new DecimalFormat("0.00");
    DecimalFormat qty = new DecimalFormat("0.##");
    Map<Integer, Recette> recettesById = new HashMap<>();
    Set<Integer> favoris = new HashSet<>();
    if (currentUser != null) favoris.addAll(currentUser.getFavoris());
    for (Recette recette : recettes) recettesById.put(recette.getId(), recette);

    int selectedRecipeId = recettes.isEmpty() ? 0 : recettes.get(0).getId();
    selectedRecipeId = parseIntOrDefault(request.getParameter("recipeId"), selectedRecipeId);
    Recette selectedRecipe = recettes.isEmpty() ? null : recettes.get(0);
    for (Recette recette : recettes) if (recette.getId() == selectedRecipeId) { selectedRecipe = recette; break; }

    List<String> recipeSteps = selectedRecipe == null ? Collections.emptyList() : splitSteps(selectedRecipe.getDescriptionEtapes());
    int cartCount = countCartItems(currentUser);
    int selectedRecipeStock = selectedRecipe == null ? 0 : disponibilites.getOrDefault(selectedRecipe.getId(), 0);
    String selectedRecipeParam = selectedRecipe == null ? "" : Integer.toString(selectedRecipe.getId());
    String selectedRecipeLink = selectedRecipe == null ? (ctx + "/app") : (ctx + "/app?recipeId=" + selectedRecipe.getId());
    List<Ingredient> ingredientsEdition = recetteEdition == null ? Collections.emptyList() : recetteEdition.getIngredients();
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sushef</title>
    <link rel="stylesheet" href="<%= ctx %>/assets/app.css">
</head>
<body>
<header class="topbar">
    <a class="brand" href="<%= ctx %>/app"><span>Sushef</span><small>Recette Maker</small></a>
    <nav class="nav-links">
        <a href="#catalogue">Recettes</a>
        <a href="#detail">Fiche</a>
        <a href="#steps">Etapes</a>
        <% if (currentUser != null) { %><a href="#cart-panel">Panier</a><% } %>
        <% if (currentUser != null && currentUser.isAdmin()) { %><a href="#admin-board">Admin</a><% } %>
    </nav>
    <div class="top-meta">
        <a class="cart-link" href="<%= currentUser != null ? "#cart-panel" : "#auth-panel" %>">🧺<% if (cartCount > 0) { %><span class="cart-badge"><%= cartCount %></span><% } %></a>
        <div class="avatar"><%= esc(initials(currentUser)) %></div>
    </div>
</header>

<% if (flashMessage != null && !flashMessage.isBlank()) { %>
<div class="flash flash--<%= esc(flashType == null ? "info" : flashType) %>"><%= esc(flashMessage) %></div>
<% } %>

<main class="app-shell">
    <section class="screen" id="landing">
        <div class="panel panel--hero">
            <div class="flowers flowers--left"><span></span><span></span><span></span><span></span><span></span></div>
            <div class="flowers flowers--right"><span></span><span></span><span></span><span></span><span></span></div>
            <div class="hero-copy">
                <div class="accent"></div>
                <p class="eyebrow"><%= currentUser == null ? "Be your own Sushi chef" : "Bienvenue " + esc(currentUser.getUsername()) %></p>
                <h1>Devenez votre propre Sushi chef</h1>
                <p>Retrouvez le fond immersif, les cartes sombres et le style du Figma, tout en gardant les favoris, le panier, les commandes et l administration.</p>
                <div class="hero-actions">
                    <a class="button button--outline button--big" href="#catalogue">Decouvrir</a>
                    <% if (selectedRecipe != null) { %><a class="button button--ghost" href="<%= selectedRecipeLink %>#detail">Voir la recette du moment</a><% } %>
                </div>
            </div>
            <img class="chef chef--hero" src="<%= ctx %>/assets/img/sushef-happy.png" alt="Sushef">
        </div>
    </section>

    <section class="screen" id="catalogue">
        <div class="panel">
            <div class="section-head section-head--center"><div><p class="eyebrow">Catalogue</p><h2>Les Recettes</h2></div><p>Choisissez une recette pour afficher sa fiche puis lancer les etapes.</p></div>
            <div class="recipe-grid">
                <% for (Recette recette : recettes) { int recipeStock = disponibilites.getOrDefault(recette.getId(), 0); boolean favorite = favoris.contains(recette.getId()); boolean selected = selectedRecipe != null && selectedRecipe.getId() == recette.getId(); %>
                <article class="recipe-card <%= selected ? "is-selected" : "" %>">
                    <div class="recipe-card__media">
                        <% if (currentUser != null) { %>
                        <form class="favorite-form" method="post" action="<%= ctx %>/favorites/toggle">
                            <input type="hidden" name="recipeId" value="<%= recette.getId() %>">
                            <input type="hidden" name="returnRecipeId" value="<%= recette.getId() %>">
                            <input type="hidden" name="returnSection" value="detail">
                            <button type="submit" class="favorite-button"><%= favorite ? "♥" : "♡" %></button>
                        </form>
                        <% } else { %><span class="favorite-button favorite-button--ghost">♡</span><% } %>
                        <a class="recipe-visual <%= recipeVariant(recette.getId()) %>" href="<%= ctx %>/app?recipeId=<%= recette.getId() %>#detail"></a>
                    </div>
                    <div class="recipe-card__body">
                        <div class="recipe-card__title"><h3><a href="<%= ctx %>/app?recipeId=<%= recette.getId() %>#detail"><%= esc(recette.getTitre()) %></a></h3><span><%= money.format(recette.getPrix()) %> €</span></div>
                        <p class="recipe-card__excerpt"><%= esc(recette.getDescriptionEtapes()) %></p>
                        <div class="metrics"><span>◷ <%= prepMinutes(recette) %></span><span>✿ <%= difficulty(recette) %></span><span>🧺 <%= recipeStock %></span></div>
                        <div class="recipe-card__actions">
                            <a class="button button--ghost" href="<%= ctx %>/app?recipeId=<%= recette.getId() %>#detail">Voir</a>
                            <% if (currentUser != null) { %>
                            <form method="post" action="<%= ctx %>/cart/add">
                                <input type="hidden" name="recipeId" value="<%= recette.getId() %>">
                                <input type="hidden" name="quantity" value="1">
                                <input type="hidden" name="returnRecipeId" value="<%= recette.getId() %>">
                                <input type="hidden" name="returnSection" value="detail">
                                <button type="submit" class="button button--outline" <%= recipeStock == 0 ? "disabled" : "" %>>Ajouter</button>
                            </form>
                            <% } %>
                        </div>
                    </div>
                </article>
                <% } %>
            </div>
        </div>
    </section>

    <section class="screen" id="detail">
        <div class="panel panel--detail">
            <% if (selectedRecipe != null) { %>
            <div class="section-head section-head--center"><div><p class="eyebrow">Fiche recette</p><h2><%= esc(selectedRecipe.getTitre()).toUpperCase(Locale.ROOT) %></h2></div><p>Version detaillee inspiree de la maquette Info Recette.</p></div>
            <div class="detail-layout">
                <div class="detail-media">
                    <div class="recipe-visual recipe-visual--large <%= recipeVariant(selectedRecipe.getId()) %>"></div>
                    <div class="detail-stats"><span>✿ Difficulte <%= difficulty(selectedRecipe) %></span><span>◷ <%= prepMinutes(selectedRecipe) %> min</span></div>
                </div>
                <div class="detail-body">
                    <div class="stock-box"><div class="accent accent--small"></div><p><strong><%= selectedRecipeStock %></strong> portions disponibles</p></div>
                    <ul class="ingredients-list">
                        <% for (Ingredient ingredient : selectedRecipe.getIngredients()) { %><li><span><%= esc(ingredient.getProduit().getNom()) %></span><strong><%= qty.format(ingredient.getQuantite()) %> <%= esc(ingredient.getUnite()) %></strong></li><% } %>
                    </ul>
                    <div class="detail-actions">
                        <% if (currentUser != null) { %>
                        <form method="post" action="<%= ctx %>/cart/add">
                            <input type="hidden" name="recipeId" value="<%= selectedRecipe.getId() %>">
                            <input type="hidden" name="quantity" value="1">
                            <input type="hidden" name="returnRecipeId" value="<%= selectedRecipe.getId() %>">
                            <input type="hidden" name="returnSection" value="detail">
                            <button type="submit" class="button button--outline button--wide" <%= selectedRecipeStock == 0 ? "disabled" : "" %>>Ajouter la recette au panier</button>
                        </form>
                        <% } else { %><a class="button button--outline button--wide" href="#auth-panel">Se connecter</a><% } %>
                        <a class="button button--ghost button--wide" href="#steps">Commencer la recette</a>
                    </div>
                    <% if (currentUser != null && quantityInCart(currentUser, selectedRecipe.getId()) > 0) { %><p class="helper">Cette recette est deja presente <strong><%= quantityInCart(currentUser, selectedRecipe.getId()) %></strong> fois dans votre panier.</p><% } %>
                </div>
            </div>
            <% } else { %><p class="helper">Aucune recette disponible.</p><% } %>
        </div>
    </section>

    <section class="screen" id="steps">
        <div class="panel">
            <div class="section-head"><div><p class="eyebrow">Mode pas a pas</p><h2><%= selectedRecipe == null ? "Etapes" : "Suivre " + esc(selectedRecipe.getTitre()) %></h2></div><p>Lecteur sombre avec fleches laterales, comme dans les maquettes Etape.</p></div>
            <div class="step-player" data-step-player>
                <button type="button" class="step-nav" data-step-prev>‹</button>
                <div class="step-viewport">
                    <% if (selectedRecipe != null && !recipeSteps.isEmpty()) { %>
                        <% for (int i = 0; i < recipeSteps.size(); i++) { %>
                        <article class="step-slide <%= i == 0 ? "is-active" : "" %>" data-step-slide <%= i == 0 ? "" : "hidden" %>>
                            <div class="recipe-visual recipe-visual--wide <%= recipeVariant(selectedRecipe.getId() + i) %>"></div>
                            <div class="step-copy"><div class="accent accent--small"></div><p class="eyebrow">Etape <%= i + 1 %> / <%= recipeSteps.size() %></p><p class="step-text"><%= esc(recipeSteps.get(i)) %></p></div>
                            <img class="chef chef--step" src="<%= ctx %>/assets/img/<%= stepChef(i) %>" alt="Sushef">
                        </article>
                        <% } %>
                        <article class="step-slide" data-step-slide hidden>
                            <div class="recipe-visual recipe-visual--wide recipe-visual--serving"></div>
                            <div class="step-copy step-copy--final"><div class="accent accent--small"></div><p class="eyebrow">Final</p><h3>Sushef dit 10/10 !</h3><p class="step-text">Bon appetit. Retournez aux recettes ou ajoutez encore cette preparation au panier.</p><div class="step-actions"><a class="button button--outline" href="#catalogue">Revenir aux recettes</a><a class="button button--ghost" href="#detail">Retour a la fiche</a></div></div>
                            <img class="chef chef--score" src="<%= ctx %>/assets/img/sushef-score.png" alt="Sushef final">
                        </article>
                    <% } else { %><article class="step-slide is-active" data-step-slide><p class="helper">Aucune etape disponible.</p></article><% } %>
                </div>
                <button type="button" class="step-nav" data-step-next>›</button>
            </div>
            <div class="step-footer"><span class="step-indicator" data-step-indicator></span></div>
        </div>
    </section>

    <section class="screen screen--utility">
        <div class="utility-grid">
            <article class="utility-card" id="auth-panel">
                <div class="section-head"><div><p class="eyebrow">Compte</p><h2><%= currentUser == null ? "Connexion" : "Session active" %></h2></div></div>
                <% if (currentUser == null) { %>
                <form method="post" action="<%= ctx %>/auth/login" class="stack-form">
                    <input type="hidden" name="returnRecipeId" value="<%= selectedRecipeParam %>">
                    <input type="hidden" name="returnSection" value="<%= selectedRecipe == null ? "auth-panel" : "detail" %>">
                    <label>Utilisateur<input type="text" name="username" placeholder="demo" required></label>
                    <label>Mot de passe<input type="password" name="password" placeholder="demo" required></label>
                    <button type="submit" class="button button--outline">Se connecter</button>
                </form>
                <p class="helper">Comptes de test: <strong>demo/demo</strong> et <strong>admin/admin</strong>.</p>
                <% } else { %>
                <div class="profile-box"><div class="avatar avatar--large"><%= esc(initials(currentUser)) %></div><div><p><strong><%= esc(currentUser.getUsername()) %></strong></p><p><%= currentUser.isAdmin() ? "Administrateur" : "Utilisateur" %></p></div></div>
                <form method="post" action="<%= ctx %>/auth/logout"><input type="hidden" name="returnSection" value="catalogue"><button type="submit" class="button button--ghost">Se deconnecter</button></form>
                <% } %>
            </article>

            <article class="utility-card" id="cart-panel">
                <div class="section-head"><div><p class="eyebrow">Panier</p><h2><%= currentUser == null ? "Connexion requise" : "Votre selection" %></h2></div></div>
                <% if (currentUser == null) { %>
                <p class="helper">Connectez-vous pour ajouter des recettes au panier et commander.</p>
                <% } else if (currentUser.getPanier().isEmpty()) { %>
                <p class="helper">Votre panier est vide.</p>
                <% } else { double totalPanier = 0D; %>
                <div class="cart-stack">
                    <% for (PanierItem item : currentUser.getPanier()) { Recette recette = recettesById.get(item.getRecetteId()); if (recette == null) continue; double sousTotal = recette.getPrix() * item.getQuantite(); totalPanier += sousTotal; %>
                    <div class="cart-item"><div><strong><%= esc(recette.getTitre()) %></strong><p><%= item.getQuantite() %> x <%= money.format(recette.getPrix()) %> €</p></div><div class="cart-actions"><form method="post" action="<%= ctx %>/cart/remove"><input type="hidden" name="recipeId" value="<%= recette.getId() %>"><input type="hidden" name="quantity" value="1"><input type="hidden" name="returnSection" value="cart-panel"><button type="submit" class="icon-pill">-</button></form><form method="post" action="<%= ctx %>/cart/add"><input type="hidden" name="recipeId" value="<%= recette.getId() %>"><input type="hidden" name="quantity" value="1"><input type="hidden" name="returnSection" value="cart-panel"><button type="submit" class="icon-pill">+</button></form></div></div>
                    <% } %>
                </div>
                <div class="cart-footer"><p>Total <strong><%= money.format(totalPanier) %> €</strong></p><form method="post" action="<%= ctx %>/orders/checkout"><input type="hidden" name="returnSection" value="cart-panel"><button type="submit" class="button button--outline">Commander</button></form></div>
                <% } %>
            </article>

            <article class="utility-card">
                <div class="section-head"><div><p class="eyebrow"><%= currentUser != null ? "Historique" : "API" %></p><h2><%= currentUser != null ? "Dernieres commandes" : "Endpoints" %></h2></div></div>
                <% if (currentUser != null) { %>
                    <% if (userCommandes.isEmpty()) { %><p class="helper">Aucune commande pour le moment.</p><% } else { %>
                    <div class="order-stack"><% for (Commande commande : userCommandes.subList(0, Math.min(userCommandes.size(), 3))) { %><article class="order-card"><div class="order-card__head"><strong>Commande #<%= commande.getId() %></strong><span><%= money.format(commande.getTotal()) %> €</span></div><p><%= esc(commande.getDateCreation()) %></p></article><% } %></div>
                    <% } %>
                <% } else { %>
                    <div class="api-list"><code>GET <%= ctx %>/api/recipes</code><code>GET <%= ctx %>/api/me</code><code>POST <%= ctx %>/api/session/login</code><code>POST <%= ctx %>/api/cart/add</code><code>POST <%= ctx %>/api/orders/checkout</code></div>
                <% } %>
            </article>
        </div>
    </section>

    <% if (currentUser != null && currentUser.isAdmin()) { %>
    <section class="screen" id="admin-board">
        <div class="panel panel--admin-menu">
            <div class="section-head"><div><p class="eyebrow">Back Office</p><h2>Tableau de bord</h2></div><p>Version exploitable du menu admin du Figma.</p></div>
            <div class="admin-grid"><a class="admin-tile" href="#recipe-maker"><span>＋</span><strong>Ajouter une recette</strong></a><a class="admin-tile" href="#recipe-maker"><span>◫</span><strong>Gestion des recettes</strong></a><a class="admin-tile" href="#stock-board"><span>▣</span><strong>Gestion du stock</strong></a><a class="admin-tile" href="#order-board"><span>◎</span><strong>Gestion des commandes</strong></a></div>
            <img class="chef chef--admin" src="<%= ctx %>/assets/img/sushef-happy.png" alt="Sushef admin">
        </div>
    </section>

    <section class="screen" id="recipe-maker">
        <div class="panel">
            <div class="section-head"><div><p class="eyebrow">Recette Maker</p><h2><%= recetteEdition == null ? "Creer une recette" : "Modifier une recette" %></h2></div><p>Le formulaire garde le vrai CRUD tout en adoptant le style builder de vos maquettes.</p></div>
            <div class="maker-layout">
                <form method="post" action="<%= ctx %>/admin/recipes/save" class="maker-form">
                    <% if (recetteEdition != null) { %><input type="hidden" name="recipeId" value="<%= recetteEdition.getId() %>"><% } %>
                    <input type="hidden" name="returnSection" value="recipe-maker">
                    <input type="hidden" name="returnRecipeId" value="<%= selectedRecipeParam %>">
                    <% if (recetteEdition != null) { %><input type="hidden" name="returnEditRecipeId" value="<%= recetteEdition.getId() %>"><% } %>
                    <div class="builder-chip"><%= recetteEdition == null ? "Page Principale" : "Edition" %></div>
                    <label>Titre<input type="text" name="title" value="<%= recetteEdition == null ? "" : esc(recetteEdition.getTitre()) %>" required></label>
                    <div class="form-row"><label>Prix<input type="number" step="0.01" min="0" name="price" value="<%= recetteEdition == null ? "" : money.format(recetteEdition.getPrix()).replace(',', '.') %>" required></label><label>Temps affiche<input type="text" value="<%= recetteEdition == null ? "20 min" : prepMinutes(recetteEdition) + " min" %>" disabled></label></div>
                    <label>Description / etapes<textarea name="description" rows="7" required><%= recetteEdition == null ? "" : esc(recetteEdition.getDescriptionEtapes()) %></textarea></label>
                    <div class="section-head"><div><p class="eyebrow">Ingredients</p><h2>Composition</h2></div><button type="button" class="button button--ghost" data-add-ingredient>Ajouter une ligne</button></div>
                    <div id="ingredient-rows">
                        <% if (ingredientsEdition.isEmpty()) { %>
                        <div class="ingredient-row"><select name="ingredientProductId" required><option value="">Produit</option><% for (Produit produit : produits) { %><option value="<%= produit.getId() %>" data-unit="<%= esc(produit.getUnite()) %>"><%= esc(produit.getNom()) %></option><% } %></select><input type="number" step="0.01" min="0" name="ingredientQuantity" placeholder="Quantite" required><input type="text" name="ingredientUnit" placeholder="Unite"><button type="button" class="icon-pill" data-remove-ingredient>×</button></div>
                        <% } else { for (Ingredient ingredient : ingredientsEdition) { %>
                        <div class="ingredient-row"><select name="ingredientProductId" required><option value="">Produit</option><% for (Produit produit : produits) { boolean selected = ingredient.getProduit() != null && ingredient.getProduit().getId() == produit.getId(); %><option value="<%= produit.getId() %>" data-unit="<%= esc(produit.getUnite()) %>" <%= selected ? "selected" : "" %>><%= esc(produit.getNom()) %></option><% } %></select><input type="number" step="0.01" min="0" name="ingredientQuantity" value="<%= qty.format(ingredient.getQuantite()).replace(',', '.') %>" required><input type="text" name="ingredientUnit" value="<%= esc(ingredient.getUnite()) %>"><button type="button" class="icon-pill" data-remove-ingredient>×</button></div>
                        <% }} %>
                    </div>
                    <div class="maker-actions"><button type="submit" class="button button--outline"><%= recetteEdition == null ? "Enregistrer la recette" : "Sauvegarder" %></button><% if (recetteEdition != null) { %><a class="button button--ghost" href="<%= selectedRecipeLink %>#recipe-maker">Nouvelle recette</a><% } %></div>
                </form>
                <aside class="maker-sidebar">
                    <div class="section-head"><div><p class="eyebrow">Gestion</p><h2>Recettes existantes</h2></div></div>
                    <div class="admin-recipe-list">
                        <% for (Recette recette : recettes) { %>
                        <article class="admin-recipe-item"><div><strong><%= esc(recette.getTitre()) %></strong><p>#<%= recette.getId() %> · <%= money.format(recette.getPrix()) %> €</p></div><div class="admin-recipe-actions"><a class="button button--ghost" href="<%= ctx %>/app?editRecipeId=<%= recette.getId() %>&recipeId=<%= selectedRecipeParam %>#recipe-maker">Modifier</a><form method="post" action="<%= ctx %>/admin/recipes/delete"><input type="hidden" name="recipeId" value="<%= recette.getId() %>"><input type="hidden" name="returnSection" value="recipe-maker"><input type="hidden" name="returnRecipeId" value="<%= selectedRecipeParam %>"><button type="submit" class="danger-button">Supprimer</button></form></div></article>
                        <% } %>
                    </div>
                </aside>
            </div>
        </div>
    </section>

    <section class="screen" id="stock-board">
        <div class="panel">
            <div class="section-head"><div><p class="eyebrow">Stock</p><h2>Gestion des ingredients</h2></div><p>Creation et mise a jour des produits.</p></div>
            <form method="post" action="<%= ctx %>/admin/products/save" class="stock-create-form"><input type="hidden" name="returnSection" value="stock-board"><input type="hidden" name="returnRecipeId" value="<%= selectedRecipeParam %>"><label>Nom<input type="text" name="name" required></label><label>Stock<input type="number" step="0.01" min="0" name="stock" required></label><label>Unite<input type="text" name="unit" required></label><label>Prix<input type="number" step="0.01" min="0" name="price" required></label><button type="submit" class="button button--outline">Ajouter</button></form>
            <div class="stock-grid">
                <% for (Produit produit : produits) { %>
                <form method="post" action="<%= ctx %>/admin/products/save" class="stock-card"><input type="hidden" name="productId" value="<%= produit.getId() %>"><input type="hidden" name="returnSection" value="stock-board"><input type="hidden" name="returnRecipeId" value="<%= selectedRecipeParam %>"><label>Nom<input type="text" name="name" value="<%= esc(produit.getNom()) %>" required></label><label>Stock<input type="number" step="0.01" min="0" name="stock" value="<%= qty.format(produit.getStock()).replace(',', '.') %>" required></label><label>Unite<input type="text" name="unit" value="<%= esc(produit.getUnite()) %>" required></label><label>Prix<input type="number" step="0.01" min="0" name="price" value="<%= money.format(produit.getPrixUnitaire()).replace(',', '.') %>" required></label><button type="submit" class="button button--ghost">Mettre a jour</button></form>
                <% } %>
            </div>
        </div>
    </section>

    <section class="screen" id="order-board">
        <div class="panel">
            <div class="section-head"><div><p class="eyebrow">Commandes</p><h2>Vue administrateur</h2></div><p>Suivi des commandes enregistrees dans le XML.</p></div>
            <% if (allCommandes.isEmpty()) { %><p class="helper">Aucune commande enregistree.</p><% } else { %>
            <div class="order-stack"><% for (Commande commande : allCommandes) { %><article class="order-card order-card--admin"><div class="order-card__head"><strong>Commande #<%= commande.getId() %> · <%= esc(commande.getUsername()) %></strong><span><%= money.format(commande.getTotal()) %> €</span></div><p><%= esc(commande.getDateCreation()) %></p><ul class="admin-order-items"><% for (CommandeItem item : commande.getItems()) { %><li><%= esc(item.getRecetteTitre()) %> · <%= item.getQuantite() %> × <%= money.format(item.getPrixUnitaire()) %> €</li><% } %></ul></article><% } %></div>
            <% } %>
        </div>
    </section>
    <% } %>
</main>

<template id="ingredient-template">
    <div class="ingredient-row"><select name="ingredientProductId" required><option value="">Produit</option><% for (Produit produit : produits) { %><option value="<%= produit.getId() %>" data-unit="<%= esc(produit.getUnite()) %>"><%= esc(produit.getNom()) %></option><% } %></select><input type="number" step="0.01" min="0" name="ingredientQuantity" placeholder="Quantite" required><input type="text" name="ingredientUnit" placeholder="Unite"><button type="button" class="icon-pill" data-remove-ingredient>×</button></div>
</template>
<script src="<%= ctx %>/assets/app.js"></script>
</body>
</html>
