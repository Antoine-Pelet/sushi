<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="jakarta.servlet.http.HttpSession,sushi.PanierItem,sushi.SushiService,sushi.User,sushi.web.AppServices" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private Integer currentUserId(HttpSession session) {
        if (session == null) return null;
        Object raw = session.getAttribute("userId");
        if (raw instanceof Integer) return (Integer) raw;
        if (raw instanceof String) {
            String text = (String) raw;
            try {
                return Integer.parseInt(text);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    private int cartCount(User user) {
        if (user == null) return 0;
        return user.getPanier().size();
    }

    private String initial(User user) {
        if (user == null || user.getUsername() == null || user.getUsername().isBlank()) return "?";
        return user.getUsername().substring(0, 1).toUpperCase();
    }
%>
<%
    String ctx = request.getContextPath();
    HttpSession sessionRef = request.getSession(false);
    Integer userId = currentUserId(sessionRef);
    User currentUser = null;
    int panierCount = 0;

    if (userId != null) {
        SushiService.DashboardData dashboard = AppServices.getService(application).getDashboardData(userId, null);
        currentUser = dashboard.currentUser();
        panierCount = cartCount(currentUser);
        if (currentUser != null && currentUser.isAdmin()) {
            response.sendRedirect(ctx + "/workspace?mode=admin");
            return;
        }
    }
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sushef</title>
    <link rel="stylesheet" href="<%= ctx %>/assets/app.css?v=responsive-stack-1">
</head>
<body class="landing-page">
<header class="topbar topbar--landing">
    <a class="brand brand--landing" href="<%= ctx %>/">
        <span>Sushef</span>
    </a>
    <div class="top-meta">
        <a class="cart-link cart-link--light" href="<%= currentUser != null ? ctx + "/workspace?mode=cart" : ctx + "/auth?returnPage=workspace&returnMode=cart" %>" aria-label="Panier">
            🧺
            <% if (panierCount > 0) { %><span class="cart-badge"><%= panierCount %></span><% } %>
        </a>
        <a class="account-photo" href="<%= currentUser != null ? ctx + "/workspace?mode=account" : ctx + "/auth?returnPage=workspace&returnMode=account" %>" aria-label="<%= currentUser != null ? "Compte " + esc(currentUser.getUsername()) : "Compte" %>">
            <% if (currentUser != null) { %><span><%= esc(initial(currentUser)) %></span><% } else { %><img src="<%= ctx %>/assets/img/sushef-happy.png" alt="Compte Sushef"><% } %>
        </a>
    </div>
</header>

<main class="landing-shell">
    <section class="landing-hero">
        <div class="landing-copy">
            <h1>Be your own Sushi chef</h1>
            <a class="landing-cta" href="<%= ctx %>/app">Découvrir</a>
        </div>
    </section>
</main>
</body>
</html>
