<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.text.DecimalFormat,java.util.*,sushi.*,sushi.SushiService.DashboardData" %>
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
        return Math.max(20, recette.getIngredients().size() * 4);
    }

    private int difficultyScore(Recette recette) {
        if (recette == null) return 1;
        return Math.max(1, Math.min(5, (int) Math.ceil(recette.getIngredients().size() / 2.0)));
    }

    private String ingredientLine(Ingredient ingredient) {
        if (ingredient == null || ingredient.getProduit() == null) return "";
        DecimalFormat qty = new DecimalFormat("0.##");
        String quantity = qty.format(ingredient.getQuantite());
        String unit = ingredient.getUnite() == null ? "" : ingredient.getUnite().trim();
        String product = ingredient.getProduit().getNom() == null ? "" : ingredient.getProduit().getNom().trim();
        return (quantity + (unit.isBlank() ? " " : " " + unit + " ") + product).trim();
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
    <link rel="stylesheet" href="<%= ctx %>/assets/app.css">
</head>
<body class="app-page app-page--catalog">
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
        <div class="recipe-showcase">
            <h1 class="recipe-showcase__title"><%= esc(recette.getTitre().toUpperCase(Locale.ROOT)) %></h1>

            <div class="recipe-showcase__card">
                <div class="recipe-showcase__media">
                    <div class="recipe-showcase__photo-frame">
                        <% if (currentUser != null) { %>
                        <form class="favorite-form favorite-form--detail" method="post" action="<%= ctx %>/favorites/toggle">
                            <input type="hidden" name="recipeId" value="<%= recette.getId() %>">
                            <input type="hidden" name="returnPage" value="recipe">
                            <input type="hidden" name="returnRecipeId" value="<%= recette.getId() %>">
                            <button type="submit" class="favorite-button favorite-button--detail"><%= favorite ? "♥" : "♡" %></button>
                        </form>
                        <% } else { %>
                        <a class="favorite-button favorite-button--detail" href="<%= ctx %>/auth?returnPage=recipe&returnRecipeId=<%= recette.getId() %>" aria-label="Ajouter aux favoris">♡</a>
                        <% } %>
                        <img class="recipe-showcase__photo" src="<%= ctx %>/assets/img/recipe-step-finish.png" alt="Presentation de <%= esc(recette.getTitre()) %>">
                    </div>

                    <div class="recipe-showcase__stats">
                        <div class="recipe-showcase__metric recipe-showcase__metric--difficulty">
                            <span class="recipe-showcase__metric-icon recipe-showcase__metric-icon--petal">✿</span>
                            <span class="recipe-showcase__metric-label">Difficulte <%= difficultyScore(recette) %></span>
                        </div>
                        <div class="recipe-showcase__divider"></div>
                        <div class="recipe-showcase__metric recipe-showcase__metric--time">
                            <span class="recipe-showcase__metric-icon" aria-hidden="true">
                                <svg viewBox="0 0 64 64" role="presentation" focusable="false">
                                    <circle cx="32" cy="34" r="22"></circle>
                                    <path d="M32 20v15l10 8"></path>
                                    <path d="M24 10h16"></path>
                                </svg>
                            </span>
                            <span class="recipe-showcase__metric-label"><%= prepMinutes(recette) %> minutes</span>
                        </div>
                    </div>
                </div>

                <div class="recipe-showcase__side">
                    <div class="recipe-showcase__basket">
                        <span class="recipe-showcase__basket-icon" aria-hidden="true">
                            <svg viewBox="0 0 64 64" role="presentation" focusable="false">
                                <path d="M18 25h28l-4 24H22z"></path>
                                <path d="M24 25V17a8 8 0 0 1 16 0v8"></path>
                                <path d="M14 25h36"></path>
                            </svg>
                        </span>
                        <strong class="recipe-showcase__basket-count"><%= ingredientCount %></strong>
                    </div>

                    <div class="recipe-showcase__divider recipe-showcase__divider--side"></div>

                    <ul class="recipe-showcase__ingredients">
                        <% for (Ingredient ingredient : recette.getIngredients()) { %>
                        <li class="recipe-showcase__ingredient"><%= esc(ingredientLine(ingredient)) %></li>
                        <% } %>
                    </ul>

                    <div class="recipe-showcase__actions">
                        <% if (currentUser != null) { %>
                        <form method="post" action="<%= ctx %>/cart/add" class="recipe-action-form recipe-action-form--stack">
                            <input type="hidden" name="recipeId" value="<%= recette.getId() %>">
                            <input type="hidden" name="quantity" value="1">
                            <input type="hidden" name="returnPage" value="recipe">
                            <input type="hidden" name="returnRecipeId" value="<%= recette.getId() %>">
                            <button type="submit" class="button button--outline recipe-detail-button recipe-detail-button--wide">Ajouter la recette au panier</button>
                        </form>
                        <% } else { %>
                        <a class="button button--outline recipe-detail-button recipe-detail-button--wide" href="<%= ctx %>/auth?returnPage=recipe&returnRecipeId=<%= recette.getId() %>">Ajouter la recette au panier</a>
                        <% } %>

                        <a class="button button--outline recipe-detail-button" href="<%= ctx %>/cook?id=<%= recette.getId() %>">Commencer la recette</a>
                        <a class="recipe-showcase__back" href="<%= ctx %>/app">Retour au catalogue</a>
                    </div>
                </div>
            </div>
        </div>
        <% } %>
    </section>
</main>
</body>
</html>