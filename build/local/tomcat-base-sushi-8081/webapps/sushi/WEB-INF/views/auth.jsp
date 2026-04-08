<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.net.URLEncoder,java.nio.charset.StandardCharsets,sushi.*,sushi.SushiService.DashboardData" %>
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
        return user.getUsername().substring(0, 1).toUpperCase();
    }

    private String authLink(String ctx, String mode, String returnPage, String returnRecipeId, String returnEditRecipeId, String returnSection, String anchor) {
        StringBuilder link = new StringBuilder(ctx).append("/auth");
        appendQuery(link, "mode", mode);
        appendQuery(link, "returnPage", returnPage);
        appendQuery(link, "returnRecipeId", returnRecipeId);
        appendQuery(link, "returnEditRecipeId", returnEditRecipeId);
        appendQuery(link, "returnSection", returnSection);
        if (anchor != null && !anchor.isBlank()) {
            link.append('#').append(anchor);
        }
        return link.toString();
    }

    private void appendQuery(StringBuilder link, String key, String value) {
        if (value == null || value.isBlank()) {
            return;
        }
        link.append(link.indexOf("?") >= 0 ? '&' : '?')
            .append(URLEncoder.encode(key, StandardCharsets.UTF_8))
            .append('=')
            .append(URLEncoder.encode(value, StandardCharsets.UTF_8));
    }
%>
<%
    DashboardData dashboard = (DashboardData) request.getAttribute("dashboard");
    User currentUser = dashboard.currentUser();
    String flashType = (String) request.getAttribute("flashType");
    String flashMessage = (String) request.getAttribute("flashMessage");
    String authMode = (String) request.getAttribute("authMode");
    String returnPage = (String) request.getAttribute("returnPage");
    String returnRecipeId = (String) request.getAttribute("returnRecipeId");
    String returnEditRecipeId = (String) request.getAttribute("returnEditRecipeId");
    String returnSection = (String) request.getAttribute("returnSection");
    String ctx = request.getContextPath();
    int cartCount = countCartItems(currentUser);

    if (returnPage == null || returnPage.isBlank()) returnPage = "workspace";
    if ((returnSection == null || returnSection.isBlank()) && ("workspace".equals(returnPage) || "app".equals(returnPage))) returnSection = "auth-panel";
    if (authMode == null || authMode.isBlank()) authMode = "login";

    boolean showRegister = "register".equals(authMode);
    String pageTitle = showRegister ? "Inscription Sushef" : "Connexion Sushef";
    String switchHref = authLink(ctx, showRegister ? "login" : "register", returnPage, returnRecipeId, returnEditRecipeId, returnSection, showRegister ? "login-card" : "register-card");
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= pageTitle %></title>
    <link rel="stylesheet" href="<%= ctx %>/assets/app.css">
</head>
<body class="app-page auth-page">
<header class="topbar topbar--catalog">
    <a class="brand brand--landing" href="<%= ctx %>/">
        <span>Sushef</span>
    </a>
    <div class="top-meta">
        <a class="cart-link cart-link--light" href="<%= currentUser != null ? ctx + "/workspace#cart-panel" : ctx + "/auth?returnPage=workspace&returnSection=cart-panel" %>" aria-label="Panier">
            🧺
            <% if (cartCount > 0) { %><span class="cart-badge"><%= cartCount %></span><% } %>
        </a>
        <a class="account-photo" href="<%= ctx %>/auth" aria-label="Compte Sushef">
            <span><%= esc(initials(currentUser)) %></span>
        </a>
    </div>
</header>

<main class="auth-shell">
    <section class="auth-layout">
        <article class="auth-hero">
            <div class="flowers flowers--left"><span></span><span></span><span></span><span></span><span></span></div>
            <div class="flowers flowers--right"><span></span><span></span><span></span><span></span><span></span></div>
            <div class="auth-copy">
                <p class="eyebrow">Acces compte</p>
                <div class="accent"></div>
                <h1><%= showRegister ? "Creer votre compte" : "Reprendre votre session" %></h1>
                <p class="auth-lead"><%= showRegister ? "Créez votre profil Sushef pour enregistrer vos favoris, votre panier et vos commandes." : "Connectez-vous pour retrouver vos favoris, votre panier, vos commandes et votre espace de travail Sushef." %></p>
            </div>
            <div class="auth-highlights">
                <span class="auth-pill">Favoris sauvegardes</span>
                <span class="auth-pill">Panier synchronise</span>
                <span class="auth-pill">Commandes conservees</span>
            </div>
            <div class="auth-demo">
                <p class="helper">Comptes de test : <strong>demo/demo</strong> et <strong>admin/admin</strong>.</p>
                <a class="button button--ghost" href="<%= ctx %>/app">Voir le catalogue</a>
            </div>
            <img class="chef chef--auth" src="<%= ctx %>/assets/img/sushef-right.png" alt="Sushef">
        </article>

        <div class="auth-stack">
            <% if (flashMessage != null && !flashMessage.isBlank()) { %>
            <div class="flash flash--<%= esc(flashType == null ? "info" : flashType) %>"><%= esc(flashMessage) %></div>
            <% } %>

            <% if (currentUser == null) { %>
            <article class="auth-card auth-card--active" id="<%= showRegister ? "register-card" : "login-card" %>">
                <div class="section-head auth-card__head">
                    <div>
                        <p class="eyebrow"><%= showRegister ? "Inscription" : "Connexion" %></p>
                        <h2><%= showRegister ? "Creer un compte utilisateur" : "Saisir vos identifiants" %></h2>
                    </div>
                </div>

                <% if (showRegister) { %>
                <form method="post" action="<%= ctx %>/auth/register" class="auth-form">
                    <input type="hidden" name="returnPage" value="<%= esc(returnPage) %>">
                    <input type="hidden" name="returnRecipeId" value="<%= esc(returnRecipeId) %>">
                    <input type="hidden" name="returnEditRecipeId" value="<%= esc(returnEditRecipeId) %>">
                    <input type="hidden" name="returnSection" value="<%= esc(returnSection) %>">
                    <label>Nom d'utilisateur<input type="text" name="username" placeholder="chef_maki" required></label>
                    <label>Mot de passe<input type="password" name="password" placeholder="Au moins 4 caracteres" required></label>
                    <label>Confirmation<input type="password" name="confirmPassword" placeholder="Retapez le mot de passe" required></label>
                    <button type="submit" class="button button--outline">Creer mon compte</button>
                </form>
                <p class="helper">Le compte cree est un compte utilisateur classique, sans droits administrateur.</p>
                <p class="helper">Deja inscrit ? <a class="auth-inline-link" href="<%= switchHref %>">Se connecter</a></p>
                <% } else { %>
                <form method="post" action="<%= ctx %>/auth/login" class="auth-form">
                    <input type="hidden" name="returnPage" value="<%= esc(returnPage) %>">
                    <input type="hidden" name="returnRecipeId" value="<%= esc(returnRecipeId) %>">
                    <input type="hidden" name="returnEditRecipeId" value="<%= esc(returnEditRecipeId) %>">
                    <input type="hidden" name="returnSection" value="<%= esc(returnSection) %>">
                    <label>Nom d'utilisateur<input type="text" name="username" placeholder="demo" required></label>
                    <label>Mot de passe<input type="password" name="password" placeholder="demo" required></label>
                    <button type="submit" class="button button--outline">Se connecter</button>
                </form>
                <p class="helper">Pas encore inscrit ? <a class="auth-inline-link" href="<%= switchHref %>">Creer un compte</a></p>
                <% } %>
            </article>
            <% } else { %>
            <article class="auth-card auth-card--active auth-card--session">
                <div class="profile-box">
                    <div class="avatar avatar--large"><%= esc(initials(currentUser)) %></div>
                    <div>
                        <p><strong><%= esc(currentUser.getUsername()) %></strong></p>
                        <p><%= currentUser.isAdmin() ? "Administrateur" : "Utilisateur" %></p>
                    </div>
                </div>
                <p class="helper">Votre session est active. Vous pouvez retourner a votre espace de travail, continuer votre navigation ou vous deconnecter.</p>
                <div class="auth-actions">
                    <a class="button button--outline" href="<%= ctx %>/workspace#auth-panel">Aller a mon espace</a>
                    <a class="button button--ghost" href="<%= ctx %>/app">Voir les recettes</a>
                    <form method="post" action="<%= ctx %>/auth/logout">
                        <input type="hidden" name="returnPage" value="auth">
                        <button type="submit" class="danger-button">Se deconnecter</button>
                    </form>
                </div>
            </article>
            <% } %>
        </div>
    </section>
</main>
</body>
</html>
