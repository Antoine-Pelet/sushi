<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.text.DecimalFormat,java.util.*,sushi.*,sushi.SushiService.DashboardData" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
%>
<%
    DashboardData dashboard = (DashboardData) request.getAttribute("dashboard");
    User currentUser = dashboard.currentUser();
    List<Recette> recettes = dashboard.recettes();
    List<Produit> produits = dashboard.produits();
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
<header class="hero">
    <div>
        <p class="eyebrow">Servlets Java + XML + Tomcat</p>
        <h1>Sushef</h1>
        <p>Catalogue de recettes, favoris, panier, commandes, administration des recettes et gestion des stocks avec une API JSON partageant la meme logique metier.</p>
    </div>
    <div class="hero-card">
        <p><strong>Compte demo:</strong> demo / demo</p>
        <p><strong>Compte admin:</strong> admin / admin</p>
        <p><strong>Stockage:</strong> <code><%= esc(dashboard.dataPath().toString()) %></code></p>
    </div>
</header>

<% if (flashMessage != null && !flashMessage.isBlank()) { %>
    <div class="flash flash--<%= esc(flashType == null ? "info" : flashType) %>"><%= esc(flashMessage) %></div>
<% } %>

<main class="layout">
    <section class="panel">
        <div class="section-head">
            <h2>Connexion</h2>
            <p>Les utilisateurs connectes peuvent gerer leurs favoris, leur panier et leurs commandes.</p>
        </div>
        <% if (currentUser == null) { %>
            <form method="post" action="<%= ctx %>/auth/login" class="grid two">
                <label>Utilisateur<input type="text" name="username" required></label>
                <label>Mot de passe<input type="password" name="password" required></label>
                <button type="submit">Se connecter</button>
            </form>
        <% } else { %>
            <div class="row spread">
                <div>
                    <p><strong>Connecte:</strong> <%= esc(currentUser.getUsername()) %></p>
                    <p><strong>Role:</strong> <%= currentUser.isAdmin() ? "Administrateur" : "Utilisateur" %></p>
                </div>
                <form method="post" action="<%= ctx %>/auth/logout"><button class="secondary" type="submit">Se deconnecter</button></form>
            </div>
        <% } %>
    </section>

    <section class="panel">
        <div class="section-head">
            <h2>Recettes</h2>
            <p>Consultation publique et actions utilisateur si une session est active.</p>
        </div>
        <div class="cards">
            <% for (Recette recette : recettes) { int disponible = disponibilites.getOrDefault(recette.getId(), 0); %>
                <article class="card">
                    <div class="row spread top">
                        <div>
                            <p class="eyebrow">#<%= recette.getId() %></p>
                            <h3><%= esc(recette.getTitre()) %></h3>
                        </div>
                        <strong><%= money.format(recette.getPrix()) %> EUR</strong>
                    </div>
                    <p class="description"><%= esc(recette.getDescriptionEtapes()) %></p>
                    <ul>
                        <% for (Ingredient ingredient : recette.getIngredients()) { %>
                            <li><%= esc(ingredient.getProduit().getNom()) %> - <%= qty.format(ingredient.getQuantite()) %> <%= esc(ingredient.getUnite()) %></li>
                        <% } %>
                    </ul>
                    <p class="badge <%= disponible > 0 ? "ok" : "empty" %>">Disponibles: <%= disponible %></p>
                    <% if (currentUser != null) { %>
                        <div class="row wrap">
                            <form method="post" action="<%= ctx %>/favorites/toggle">
                                <input type="hidden" name="recipeId" value="<%= recette.getId() %>">
                                <button class="secondary" type="submit"><%= favoris.contains(recette.getId()) ? "Retirer favori" : "Ajouter favori" %></button>
                            </form>
                            <form method="post" action="<%= ctx %>/cart/add" class="row">
                                <input type="hidden" name="recipeId" value="<%= recette.getId() %>">
                                <input type="number" name="quantity" min="1" value="1" <%= disponible == 0 ? "disabled" : "" %>>
                                <button type="submit" <%= disponible == 0 ? "disabled" : "" %>>Ajouter au panier</button>
                            </form>
                        </div>
                    <% } else { %>
                        <p class="muted">Connectez-vous pour agir sur cette recette.</p>
                    <% } %>
                </article>
            <% } %>
        </div>
    </section>

    <% if (currentUser != null) { %>
        <section class="panel">
            <div class="section-head"><h2>Panier</h2><p>Ajout et retrait de recettes avant commande.</p></div>
            <% if (currentUser.getPanier().isEmpty()) { %>
                <p class="muted">Votre panier est vide.</p>
            <% } else { double totalPanier = 0D; %>
                <% for (PanierItem item : currentUser.getPanier()) {
                    Recette recette = recettesById.get(item.getRecetteId());
                    if (recette == null) continue;
                    double sousTotal = recette.getPrix() * item.getQuantite();
                    totalPanier += sousTotal;
                %>
                    <div class="row spread cart-row">
                        <div><strong><%= esc(recette.getTitre()) %></strong><p><%= item.getQuantite() %> x <%= money.format(recette.getPrix()) %> EUR</p></div>
                        <div class="row wrap">
                            <form method="post" action="<%= ctx %>/cart/remove"><input type="hidden" name="recipeId" value="<%= recette.getId() %>"><input type="hidden" name="quantity" value="1"><button class="secondary" type="submit">-1</button></form>
                            <form method="post" action="<%= ctx %>/cart/add"><input type="hidden" name="recipeId" value="<%= recette.getId() %>"><input type="hidden" name="quantity" value="1"><button type="submit">+1</button></form>
                        </div>
                        <strong><%= money.format(sousTotal) %> EUR</strong>
                    </div>
                <% } %>
                <div class="row spread">
                    <p>Total estime: <strong><%= money.format(totalPanier) %> EUR</strong></p>
                    <form method="post" action="<%= ctx %>/orders/checkout"><button type="submit">Commander</button></form>
                </div>
            <% } %>
        </section>

        <section class="panel">
            <div class="section-head"><h2>Commandes</h2><p>Historique des commandes du compte courant.</p></div>
            <% if (dashboard.userCommandes().isEmpty()) { %>
                <p class="muted">Aucune commande pour l'instant.</p>
            <% } else { %>
                <% for (Commande commande : dashboard.userCommandes()) { %>
                    <article class="card">
                        <div class="row spread top"><div><h3>Commande #<%= commande.getId() %></h3><p><%= esc(commande.getDateCreation()) %></p></div><strong><%= money.format(commande.getTotal()) %> EUR</strong></div>
                        <ul>
                            <% for (CommandeItem item : commande.getItems()) { %>
                                <li><%= esc(item.getRecetteTitre()) %> - <%= item.getQuantite() %> x <%= money.format(item.getPrixUnitaire()) %> EUR</li>
                            <% } %>
                        </ul>
                    </article>
                <% } %>
            <% } %>
        </section>
    <% } %>

    <% if (currentUser != null && currentUser.isAdmin()) { %>
        <section class="panel">
            <div class="section-head"><h2>Administration des recettes</h2><p>Creation, modification et suppression.</p></div>
            <form method="post" action="<%= ctx %>/admin/recipes/save" class="grid two">
                <% if (recetteEdition != null) { %><input type="hidden" name="recipeId" value="<%= recetteEdition.getId() %>"><% } %>
                <label>Titre<input type="text" name="title" value="<%= recetteEdition == null ? "" : esc(recetteEdition.getTitre()) %>" required></label>
                <label>Prix de vente (EUR)<input type="number" step="0.01" min="0" name="price" value="<%= recetteEdition == null ? "" : money.format(recetteEdition.getPrix()).replace(',', '.') %>" required></label>
                <label class="full">Description<textarea name="description" rows="5" required><%= recetteEdition == null ? "" : esc(recetteEdition.getDescriptionEtapes()) %></textarea></label>
                <div class="full">
                    <div class="row spread"><h3>Ingredients</h3><button type="button" class="secondary" data-add-ingredient>Ajouter une ligne</button></div>
                    <div id="ingredient-rows">
                        <% if (ingredientsEdition.isEmpty()) { %>
                            <div class="ingredient-row">
                                <select name="ingredientProductId" required><option value="">Produit</option><% for (Produit produit : produits) { %><option value="<%= produit.getId() %>" data-unit="<%= esc(produit.getUnite()) %>"><%= esc(produit.getNom()) %></option><% } %></select>
                                <input type="number" step="0.01" min="0" name="ingredientQuantity" placeholder="Quantite" required>
                                <input type="text" name="ingredientUnit" placeholder="Unite">
                                <button type="button" class="secondary" data-remove-ingredient>Retirer</button>
                            </div>
                        <% } else { for (Ingredient ingredient : ingredientsEdition) { %>
                            <div class="ingredient-row">
                                <select name="ingredientProductId" required>
                                    <option value="">Produit</option>
                                    <% for (Produit produit : produits) { boolean selected = ingredient.getProduit() != null && ingredient.getProduit().getId() == produit.getId(); %>
                                        <option value="<%= produit.getId() %>" data-unit="<%= esc(produit.getUnite()) %>" <%= selected ? "selected" : "" %>><%= esc(produit.getNom()) %></option>
                                    <% } %>
                                </select>
                                <input type="number" step="0.01" min="0" name="ingredientQuantity" value="<%= qty.format(ingredient.getQuantite()).replace(',', '.') %>" required>
                                <input type="text" name="ingredientUnit" value="<%= esc(ingredient.getUnite()) %>">
                                <button type="button" class="secondary" data-remove-ingredient>Retirer</button>
                            </div>
                        <% }} %>
                    </div>
                </div>
                <button type="submit"><%= recetteEdition == null ? "Creer la recette" : "Enregistrer la recette" %></button>
                <% if (recetteEdition != null) { %><a href="<%= ctx %>/app" class="button-link secondary-link">Nouvelle recette</a><% } %>
            </form>

            <% for (Recette recette : recettes) { %>
                <div class="row spread cart-row">
                    <div><strong><%= esc(recette.getTitre()) %></strong><p>#<%= recette.getId() %> - <%= money.format(recette.getPrix()) %> EUR</p></div>
                    <div class="row wrap">
                        <a href="<%= ctx %>/app?editRecipeId=<%= recette.getId() %>" class="button-link secondary-link">Modifier</a>
                        <form method="post" action="<%= ctx %>/admin/recipes/delete"><input type="hidden" name="recipeId" value="<%= recette.getId() %>"><button class="danger" type="submit">Supprimer</button></form>
                    </div>
                </div>
            <% } %>
        </section>

        <section class="panel">
            <div class="section-head"><h2>Gestion des stocks</h2><p>Creation et mise a jour des produits.</p></div>
            <form method="post" action="<%= ctx %>/admin/products/save" class="grid four">
                <label>Nom<input type="text" name="name" required></label>
                <label>Stock<input type="number" step="0.01" min="0" name="stock" required></label>
                <label>Unite<input type="text" name="unit" required></label>
                <label>Prix unitaire<input type="number" step="0.01" min="0" name="price" required></label>
                <button type="submit">Ajouter un produit</button>
            </form>
            <% for (Produit produit : produits) { %>
                <form method="post" action="<%= ctx %>/admin/products/save" class="grid four stock-row">
                    <input type="hidden" name="productId" value="<%= produit.getId() %>">
                    <label>Nom<input type="text" name="name" value="<%= esc(produit.getNom()) %>" required></label>
                    <label>Stock<input type="number" step="0.01" min="0" name="stock" value="<%= qty.format(produit.getStock()).replace(',', '.') %>" required></label>
                    <label>Unite<input type="text" name="unit" value="<%= esc(produit.getUnite()) %>" required></label>
                    <label>Prix unitaire<input type="number" step="0.01" min="0" name="price" value="<%= money.format(produit.getPrixUnitaire()).replace(',', '.') %>" required></label>
                    <button class="secondary" type="submit">Mettre a jour</button>
                </form>
            <% } %>
        </section>
    <% } %>

    <section class="panel">
        <div class="section-head"><h2>API</h2><p>Exemples: GET <code><%= ctx %>/api/recipes</code>, POST <code><%= ctx %>/api/session/login</code>, POST <code><%= ctx %>/api/orders/checkout</code>.</p></div>
    </section>
</main>

<template id="ingredient-template">
    <div class="ingredient-row">
        <select name="ingredientProductId" required><option value="">Produit</option><% for (Produit produit : produits) { %><option value="<%= produit.getId() %>" data-unit="<%= esc(produit.getUnite()) %>"><%= esc(produit.getNom()) %></option><% } %></select>
        <input type="number" step="0.01" min="0" name="ingredientQuantity" placeholder="Quantite" required>
        <input type="text" name="ingredientUnit" placeholder="Unite">
        <button type="button" class="secondary" data-remove-ingredient>Retirer</button>
    </div>
</template>
<script src="<%= ctx %>/assets/app.js"></script>
</body>
</html>
