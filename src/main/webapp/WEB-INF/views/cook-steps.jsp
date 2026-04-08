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

    private List<List<String>> chunkSteps(List<String> steps, int size) {
        List<List<String>> chunks = new ArrayList<>();
        if (steps == null || steps.isEmpty()) return chunks;
        for (int i = 0; i < steps.size(); i += size) {
            chunks.add(new ArrayList<>(steps.subList(i, Math.min(i + size, steps.size()))));
        }
        return chunks;
    }
%>
<%
    DashboardData dashboard = (DashboardData) request.getAttribute("dashboard");
    Recette recette = (Recette) request.getAttribute("selectedRecipe");
    List<String> recipeSteps = (List<String>) request.getAttribute("recipeSteps");
    List<List<String>> stepGroups = chunkSteps(recipeSteps, 4);
    User currentUser = dashboard.currentUser();
    String ctx = request.getContextPath();
    int cartCount = countCartItems(currentUser);
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Realisation</title>
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
        <a class="account-photo" href="<%= currentUser != null ? ctx + "/workspace?mode=account" : ctx + "/auth?returnPage=cook-steps&returnRecipeId=" + (recette != null ? recette.getId() : 0) %>" aria-label="<%= currentUser != null ? "Compte " + esc(currentUser.getUsername()) : "Compte" %>">
            <span><%= esc(initials(currentUser)) %></span>
        </a>
    </div>
</header>

<main class="catalog-shell">
    <section class="catalog-panel cook-panel">
        <div class="cook-back-row">
            <a class="back-link cook-back-link" href="<%= recette != null ? ctx + "/cook?id=" + recette.getId() : ctx + "/app" %>" data-history-back>Retour</a>
        </div>
        <% if (recette == null) { %>
        <p class="helper">Aucune recette disponible.</p>
        <% } else { %>
        <div class="cook-player" data-step-player>
            <div class="cook-viewport">
                <% for (int i = 0; i < stepGroups.size(); i++) { List<String> group = stepGroups.get(i); %>
                <article class="cook-slide cook-slide--step <%= i == 0 ? "is-active" : "" %>" data-step-slide <%= i == 0 ? "" : "hidden" %>>
                    <% if (i > 0) { %><button type="button" class="cook-nav cook-nav--inline cook-nav--inline-left" data-step-prev>‹</button><% } %>
                    <button type="button" class="cook-nav cook-nav--inline cook-nav--inline-right" data-step-next>›</button>
                    <div class="cook-blossom cook-blossom--left"></div>
                    <img class="cook-photo" src="<%= ctx %>/assets/img/recipe-step-prep.png" alt="Preparation recette">
                    <div class="cook-step-text">
                        <% for (String step : group) { %>
                        <p><%= esc(step) %></p>
                        <% } %>
                    </div>
                    <img class="cook-chef cook-chef--right" src="<%= ctx %>/assets/img/sushef-focused.png" alt="Sushef">
                </article>
                <% } %>

                <article class="cook-slide cook-slide--final" data-step-slide hidden>
                    <button type="button" class="cook-nav cook-nav--inline cook-nav--inline-left" data-step-prev>‹</button>
                    <img class="cook-photo cook-photo--final" src="<%= ctx %>/assets/img/recipe-step-finish.png" alt="Recette terminee">
                    <div class="cook-blossom cook-blossom--right"></div>
                    <div class="cook-final-copy">
                        <h2>Sushef dit 10/10&nbsp;!</h2>
                        <p>Bon appetit</p>
                        <a class="button button--outline" href="<%= ctx %>/app">Revenir aux recettes</a>
                    </div>
                    <img class="cook-chef cook-chef--score" src="<%= ctx %>/assets/img/sushef-score.png" alt="Sushef final">
                </article>
            </div>
        </div>
        <% } %>
    </section>
</main>

<script src="<%= ctx %>/assets/app.js"></script>
</body>
</html>

