<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*,sushi.*,sushi.SushiService.DashboardData" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private int countCartItems(User user) {
        if (user == null) return 0;
        int total = 0;
        for (PanierItem item : user.getPanier()) total += item.getQuantite();
        return total;
    }

    private String initials(User user) {
        if (user == null || user.getUsername() == null || user.getUsername().isBlank()) return "G";
        return user.getUsername().substring(0, 1).toUpperCase(Locale.ROOT);
    }

    private int prepMinutes(Recette recette) {
        if (recette == null) return 0;
        return Math.max(18, recette.getIngredients().size() * 4);
    }

    private String difficultyLabel(Recette recette) {
        if (recette == null) return "Facile";
        int score = Math.max(1, Math.min(5, (int) Math.ceil(recette.getIngredients().size() / 2.0)));
        if (score <= 2) return "Facile";
        if (score == 3) return "Intermediaire";
        return "Expert";
    }

    private String difficultyFlowers(Recette recette) {
        if (recette == null) return "✿";
        int score = Math.max(1, Math.min(3, (int) Math.ceil(recette.getIngredients().size() / 3.0)));
        StringBuilder flowers = new StringBuilder();
        for (int i = 0; i < score; i++) flowers.append("✿");
        return flowers.toString();
    }

    private String visualClass(int recipeId) {
        int mod = Math.floorMod(recipeId, 3);
        if (mod == 0) return "recipe-visual--left";
        if (mod == 1) return "recipe-visual--center";
        return "recipe-visual--right";
    }
%>
<%
    DashboardData dashboard = (DashboardData) request.getAttribute("dashboard");
    Recette recette = (Recette) request.getAttribute("selectedRecipe");
    User currentUser = dashboard.currentUser();
    String ctx = request.getContextPath();
    int cartCount = countCartItems(currentUser);
    boolean favorite = currentUser != null && currentUser.getFavoris().contains(recette.getId());
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fiche recette</title>
    <link rel="stylesheet" href="<%= ctx %>/assets/app.css">
</head>
<body class="app-page app-page--catalog">
<header class="topbar topbar--catalog">
    <a class="brand brand--landing" href="<%= ctx %>/">
        <span>Sushef</span>
    </a>
    <div class="top-meta">
        <a class="cart-link cart-link--light" href="<%= currentUser != null ? ctx + "/workspace#cart-panel" : ctx + "/auth?returnPage=workspace&returnSection=cart-panel" %>" aria-label="Panier">
            🧺
            <% if (cartCount > 0) { %><span class="cart-badge"><%= cartCount %></span><% } %>
        </a>
        <a class="account-photo" href="<%= ctx + "/auth?returnPage=recipe&returnRecipeId=" + (recette != null ? recette.getId() : 0) %>" aria-label="<%= currentUser != null ? "Compte " + esc(currentUser.getUsername()) : "Compte" %>">
            <span><%= esc(initials(currentUser)) %></span>
        </a>
    </div>
</header>

<main class="catalog-shell">
    <section class="catalog-panel recipe-panel">
        <% if (recette == null) { %>
        <p class="helper">Aucune recette disponible.</p>
        <% } else { %>
        <div class="recipe-layout">
            <div class="recipe-quadrant recipe-quadrant--media">
                <% if (currentUser != null) { %>
                <form class="favorite-form favorite-form--detail" method="post" action="<%= ctx %>/favorites/toggle">
                    <input type="hidden" name="recipeId" value="<%= recette.getId() %>">
                    <input type="hidden" name="returnPage" value="recipe">
                    <input type="hidden" name="returnRecipeId" value="<%= recette.getId() %>">
                    <button type="submit" class="favorite-button"><%= favorite ? "♥" : "♡" %></button>
                </form>
                <% } %>
                <div class="recipe-visual recipe-detail-visual <%= visualClass(recette.getId()) %>"></div>
            </div>

            <div class="recipe-quadrant recipe-quadrant--summary">
                <h1 class="recipe-detail-title"><%= esc(recette.getTitre()) %></h1>
                <ul class="recipe-detail-meta">
                    <li><span class="catalog-icon">⏱</span><strong><%= prepMinutes(recette) %> min</strong></li>
                    <li><span class="catalog-icon"><%= difficultyFlowers(recette) %></span><strong><%= difficultyLabel(recette) %></strong></li>
                    <li><span class="catalog-icon">🧺</span><strong><%= recette.getIngredients().size() %> ingredients</strong></li>
                </ul>
            </div>

            <div class="recipe-quadrant recipe-quadrant--ingredients">
                <ul class="recipe-ingredient-list">
                    <% for (Ingredient ingredient : recette.getIngredients()) { %>
                    <li>
                        <span><%= esc(ingredient.getProduit().getNom()) %></span>
                        <strong><%= ingredient.getQuantite() %> <%= esc(ingredient.getUnite()) %></strong>
                    </li>
                    <% } %>
                </ul>
            </div>

            <div class="recipe-quadrant recipe-quadrant--actions">
                <a class="button button--ghost button--wide" href="<%= ctx %>/app">Retour au catalogue</a>
                <% if (currentUser != null) { %>
                <form method="post" action="<%= ctx %>/cart/add" class="recipe-action-form">
                    <input type="hidden" name="recipeId" value="<%= recette.getId() %>">
                    <input type="hidden" name="quantity" value="1">
                    <input type="hidden" name="returnPage" value="recipe">
                    <input type="hidden" name="returnRecipeId" value="<%= recette.getId() %>">
                    <button type="submit" class="button button--outline button--wide">Ajouter au panier</button>
                </form>
                <% } else { %>
                <a class="button button--outline button--wide" href="<%= ctx + "/auth?returnPage=recipe&returnRecipeId=" + (recette != null ? recette.getId() : 0) %>">Ajouter au panier</a>
                <% } %>
                <a class="button button--ghost button--wide" href="<%= ctx %>/cook?id=<%= recette.getId() %>">Commencer la recette</a>
            </div>
        </div>
        <% } %>
    </section>
</main>
</body>
</html>


