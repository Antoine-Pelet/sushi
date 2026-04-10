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

    private int prepMinutes(Recette recette) {
        if (recette == null) return 0;
        if (recette.getTempsPreparationMinutes() > 0) return recette.getTempsPreparationMinutes();
        return Math.max(18, recette.getIngredients().size() * 4);
    }

    private String difficultyLabel(Recette recette) {
        if (recette == null) return "Facile";
        int score = recette.getDifficulte();
        if (score <= 1) return "Facile";
        if (score == 2) return "Moyen";
        return "Difficile";
    }

    private String difficultyFlowers(Recette recette) {
        if (recette == null) return "✿";
        int score = recette.getDifficulte();
        if (score < 1 || score > 3) score = 1;
        StringBuilder flowers = new StringBuilder();
        for (int i = 0; i < score; i++) flowers.append("✿");
        return flowers.toString();
    }

    private String visualClass(int index) {
        int mod = Math.floorMod(index, 3);
        if (mod == 0) return "recipe-visual--left";
        if (mod == 1) return "recipe-visual--center";
        return "recipe-visual--right";
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
    User currentUser = dashboard.currentUser();
    List<Recette> recettes = dashboard.recettes();
    String ctx = request.getContextPath();
    int cartCount = countCartItems(currentUser);
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Catalogue Sushef</title>
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
        <a class="account-photo" href="<%= currentUser != null ? ctx + "/workspace?mode=account" : ctx + "/auth?returnPage=workspace&returnMode=account" %>" aria-label="<%= currentUser != null ? "Compte " + esc(currentUser.getUsername()) : "Compte" %>">
            <span><%= esc(initials(currentUser)) %></span>
        </a>
    </div>
</header>

<main class="catalog-shell">
    <section class="catalog-panel">
        <div class="catalog-panel__head">
            <p class="eyebrow">Catalogue de recettes</p>
        </div>

        <div class="catalog-scroll">
            <% if (recettes.isEmpty()) { %>
            <p class="helper">Aucune recette disponible pour le moment.</p>
            <% } else { %>
            <div class="catalog-grid">
                <% for (int i = 0; i < recettes.size(); i++) {
                    Recette recette = recettes.get(i);
                %>
                <article class="catalog-card">
                    <div class="catalog-card__media">
                        <a class="recipe-visual catalog-card__visual <%= visualClass(i) %>" href="<%= ctx %>/recipe?id=<%= recette.getId() %>" style="background-image: linear-gradient(rgba(18, 18, 18, 0.06), rgba(18, 18, 18, 0.26)), url('<%= esc(imageSrc(ctx, recette.getImageCouverture())) %>');"></a>
                    </div>
                    <div class="catalog-card__body">
                        <h2><a href="<%= ctx %>/recipe?id=<%= recette.getId() %>"><%= esc(recette.getTitre()) %></a></h2>
                        <ul class="catalog-card__meta">
                            <li><span class="catalog-icon">⏱</span><strong><%= prepMinutes(recette) %> min</strong></li>
                            <li><span class="catalog-icon"><%= difficultyFlowers(recette) %></span><strong><%= difficultyLabel(recette) %></strong></li>
                            <li><span class="catalog-icon">🧺</span><strong><%= recette.getIngredients().size() %> ingredients</strong></li>
                        </ul>
                    </div>
                </article>
                <% } %>
            </div>
            <% } %>
        </div>
    </section>
</main>
</body>
</html>
