<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*,sushi.*,sushi.SushiService.DashboardData" %>
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

    private String imageSrc(String ctx, String image) {
        if (image == null || image.isBlank()) return ctx + "/assets/img/recipe-step-prep.png";
        String value = image.trim();
        if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("data:")) return value;
        return value.startsWith("/") ? ctx + value : ctx + "/" + value;
    }

    private String stepText(Object step) {
        if (step == null) return "";
        try {
            Object value = step.getClass().getMethod("getTexte").invoke(step);
            return value == null ? "" : value.toString();
        } catch (Exception ignored) {
            return "";
        }
    }

    private String fallbackStepText(int index) {
        String[] samples = {
            "Cuire et assaisonner le riz.",
            "Étaler le riz sur la feuille de nori.",
            "Ajouter la garniture puis rouler délicatement.",
            "Découper les makis et dresser l'assiette."
        };
        return samples[Math.floorMod(index, samples.length)];
    }

    private String stepImage(Object step) {
        if (step == null) return "";
        try {
            Object value = step.getClass().getMethod("getImage").invoke(step);
            return value == null ? "" : value.toString();
        } catch (Exception ignored) {
            return "";
        }
    }

    private String stepSushefImage(Object step) {
        if (step == null) return "";
        try {
            Object value = step.getClass().getMethod("getImageSushef").invoke(step);
            return value == null ? "" : value.toString();
        } catch (Exception ignored) {
            return "";
        }
    }
%>
<%
    DashboardData dashboard = (DashboardData) request.getAttribute("dashboard");
    Recette recette = (Recette) request.getAttribute("selectedRecipe");
    List<?> recipeSteps = (List<?>) request.getAttribute("recipeSteps");
    User currentUser = dashboard.currentUser();
    String ctx = request.getContextPath();
    int cartCount = countCartItems(currentUser);
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Réalisation</title>
    <link rel="stylesheet" href="<%= ctx %>/assets/app.css?v=responsive-stack-1">
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
                <% for (int i = 0; i < recipeSteps.size(); i++) { Object step = recipeSteps.get(i); %>
                <% String currentSushefImage = stepSushefImage(step); if (currentSushefImage == null || currentSushefImage.isBlank()) currentSushefImage = "/assets/img/sushef-focused.png"; %>
                <article class="cook-slide cook-slide--step <%= i == 0 ? "is-active" : "" %>" data-step-slide <%= i == 0 ? "" : "hidden" %>>
                    <% if (i > 0) { %><button type="button" class="cook-nav cook-nav--inline cook-nav--inline-left" data-step-prev>‹</button><% } %>
                    <button type="button" class="cook-nav cook-nav--inline cook-nav--inline-right" data-step-next>›</button>
                    <div class="cook-blossom cook-blossom--left"></div>
                    <img class="cook-photo" src="<%= esc(imageSrc(ctx, stepImage(step))) %>" alt="Etape <%= i + 1 %>">
                    <div class="cook-step-text">
                        <% String stepLabel = stepText(step); if (stepLabel == null || stepLabel.isBlank()) stepLabel = fallbackStepText(i); %>
                        <p><%= esc(stepLabel) %></p>
                    </div>
                    <img class="cook-chef cook-chef--right" src="<%= esc(imageSrc(ctx, currentSushefImage)) %>" alt="Sushef">
                </article>
                <% } %>

                <article class="cook-slide cook-slide--final" data-step-slide hidden>
                    <button type="button" class="cook-nav cook-nav--inline cook-nav--inline-left" data-step-prev>‹</button>
                    <img class="cook-photo cook-photo--final" src="<%= esc(imageSrc(ctx, recette.getImageCouverture())) %>" alt="Recette terminée">
                    <div class="cook-blossom cook-blossom--right"></div>
                    <div class="cook-final-copy">
                        <h2>Sushef dit 10/10&nbsp;!</h2>
                        <p>Bon appétit</p>
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
