<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.text.DecimalFormat,java.util.*,sushi.*,sushi.SushiService.DashboardData" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private int countCartItems(User user) {
        if (user == null) return 0;
        return user.getPanier().size();
    }

    private String initials(User user) {
        if (user == null || user.getUsername() == null || user.getUsername().isBlank()) return "G";
        return user.getUsername().substring(0, 1).toUpperCase(Locale.ROOT);
    }

    private int prepMinutes(Recette recette) {
        if (recette == null) return 0;
        if (recette.getTempsPreparationMinutes() > 0) return recette.getTempsPreparationMinutes();
        return Math.max(20, recette.getIngredients().size() * 4);
    }

    private int difficultyScore(Recette recette) {
        if (recette == null) return 1;
        int score = recette.getDifficulte();
        if (score < 1 || score > 3) return 1;
        return score;
    }

    private String difficultyFlowers(Recette recette) {
        int score = difficultyScore(recette);
        StringBuilder flowers = new StringBuilder();
        for (int i = 0; i < score; i++) flowers.append("✿");
        return flowers.toString();
    }

    private String ingredientLine(Ingredient ingredient) {
        if (ingredient == null || ingredient.getProduit() == null) return "";
        DecimalFormat qty = new DecimalFormat("0.##");
        String quantity = qty.format(ingredient.getQuantite());
        String unit = ingredient.getUnite() == null ? "" : ingredient.getUnite().trim();
        String product = ingredient.getProduit().getNom() == null ? "" : ingredient.getProduit().getNom().trim();
        return (quantity + (unit.isBlank() ? " " : " " + unit + " ") + product).trim();
    }

    private String ingredientPrice(Ingredient ingredient) {
        if (ingredient == null || ingredient.getProduit() == null) return "";
        DecimalFormat money = new DecimalFormat("0.00");
        return money.format(ingredient.getQuantite() * ingredient.getProduit().getPrixUnitaire()) + " €";
    }

    private String imageSrc(String ctx, String image) {
        if (image == null || image.isBlank()) return ctx + "/assets/img/recipe-step-finish.png";
        String value = image.trim();
        if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("data:")) return value;
        return value.startsWith("/") ? ctx + value : ctx + "/" + value;
    }
%>
<%
    DashboardData dashboard = (DashboardData) request.getAttribute("dashboard");
    Recette recette = (Recette) request.getAttribute("selectedRecipe");
    User currentUser = dashboard.currentUser();
    String ctx = request.getContextPath();
    int cartCount = countCartItems(currentUser);
    boolean favorite = currentUser != null && recette != null && currentUser.getFavoris().contains(recette.getId());
    int ingredientCount = recette == null ? 0 : recette.getIngredients().size();
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fiche recette</title>
    <link rel="stylesheet" href="<%= ctx %>/assets/app.css?v=responsive-stack-1">
</head>
<body class="app-page app-page--catalog recipe-page">
<header class="topbar topbar--catalog">
    <a class="brand brand--landing" href="<%= ctx %>/">
        <span>Sushef</span>
    </a>
    <div class="top-meta">
        <a class="cart-link cart-link--light" href="<%= currentUser != null ? ctx + "/workspace?mode=cart" : ctx + "/auth?returnPage=workspace&returnMode=cart" %>" aria-label="Panier">
            🧺
            <% if (cartCount > 0) { %><span class="cart-badge"><%= cartCount %></span><% } %>
        </a>
        <a class="account-photo" href="<%= currentUser != null ? ctx + "/workspace?mode=account" : ctx + "/auth?returnPage=recipe&returnRecipeId=" + (recette != null ? recette.getId() : 0) %>" aria-label="<%= currentUser != null ? "Compte " + esc(currentUser.getUsername()) : "Compte" %>">
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
                    <button type="submit" class="favorite-button favorite-button--detail"><%= favorite ? "♥" : "♡" %></button>
                </form>
                <% } %>
                <img class="recipe-detail-visual recipe-showcase__photo" src="<%= esc(imageSrc(ctx, recette.getImageCouverture())) %>" alt="Presentation de <%= esc(recette.getTitre()) %>">
            </div>

            <div class="recipe-quadrant recipe-quadrant--summary">
                <h1 class="recipe-detail-title"><%= esc(recette.getTitre().toUpperCase(Locale.ROOT)) %></h1>
                <ul class="recipe-detail-meta">
                    <li>
                        <span class="recipe-showcase__metric-icon" aria-hidden="true">
                            <svg viewBox="0 0 64 64" role="presentation" focusable="false">
                                <circle cx="32" cy="34" r="22"></circle>
                                <path d="M32 20v15l10 8"></path>
                                <path d="M24 10h16"></path>
                            </svg>
                        </span>
                        <strong><%= prepMinutes(recette) %> minutes</strong>
                    </li>
                    <li>
                        <span class="recipe-showcase__metric-icon recipe-showcase__metric-icon--petal">✿</span>
                        <strong><%= difficultyFlowers(recette) %> <%= difficultyScore(recette) == 1 ? "Facile" : difficultyScore(recette) == 2 ? "Moyen" : "Difficile" %></strong>
                    </li>
                    <li>
                        <span class="recipe-showcase__basket-icon" aria-hidden="true">
                            <svg viewBox="0 0 64 64" role="presentation" focusable="false">
                                <path d="M18 25h28l-4 24H22z"></path>
                                <path d="M24 25V17a8 8 0 0 1 16 0v8"></path>
                                <path d="M14 25h36"></path>
                            </svg>
                        </span>
                        <strong><%= ingredientCount %> ingredients</strong>
                    </li>
                </ul>
            </div>

            <div class="recipe-quadrant recipe-quadrant--ingredients">
                <ul class="recipe-ingredient-list">
                    <% for (Ingredient ingredient : recette.getIngredients()) { %>
                    <li><span><%= esc(ingredientLine(ingredient)) %></span><strong><%= esc(ingredientPrice(ingredient)) %></strong></li>
                    <% } %>
                </ul>
            </div>

            <div class="recipe-quadrant recipe-quadrant--actions">
                <% if (currentUser != null) { %>
                <form method="post" action="<%= ctx %>/cart/add" class="recipe-action-form">
                    <input type="hidden" name="recipeId" value="<%= recette.getId() %>">
                    <input type="hidden" name="quantity" value="1">
                    <input type="hidden" name="returnPage" value="recipe">
                    <input type="hidden" name="returnRecipeId" value="<%= recette.getId() %>">
                    <button type="submit" class="button button--outline recipe-detail-button recipe-detail-button--wide">Ajouter la recette au panier</button>
                </form>
                <% } else { %>
                <a class="button button--outline recipe-detail-button recipe-detail-button--wide" href="<%= ctx %>/auth?returnPage=recipe&returnRecipeId=<%= recette.getId() %>">Ajouter la recette au panier</a>
                <% } %>
                <a class="button button--outline recipe-detail-button recipe-detail-button--wide" href="<%= ctx %>/cook?id=<%= recette.getId() %>">Commencer la recette</a>
                <a class="button button--outline recipe-detail-button recipe-detail-button--wide" href="<%= ctx %>/app">Retour au catalogue</a>
            </div>
        </div>
        <% } %>
    </section>
</main>
</body>
</html>
