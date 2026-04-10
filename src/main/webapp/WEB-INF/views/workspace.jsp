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

    private String stepText(Object step) {
        if (step == null) return "";
        try {
            Object value = step.getClass().getMethod("getTexte").invoke(step);
            return value == null ? "" : value.toString();
        } catch (Exception ignored) {
            return "";
        }
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

    private List<?> recipeSteps(Object recette) {
        if (recette == null) return Collections.emptyList();
        try {
            Object value = recette.getClass().getMethod("getEtapes").invoke(recette);
            if (value instanceof List<?>) {
                return (List<?>) value;
            }
        } catch (Exception ignored) {
        }
        return Collections.emptyList();
    }

    private boolean sameImage(String current, String expected) {
        return current != null && current.trim().equals(expected);
    }

    private boolean containsImage(Collection<String> imagePaths, String current) {
        if (imagePaths == null || imagePaths.isEmpty()) return false;
        for (String imagePath : imagePaths) {
            if (sameImage(current, imagePath)) return true;
        }
        return false;
    }

    private String fileName(String path) {
        if (path == null || path.isBlank()) return "";
        int slash = path.lastIndexOf('/');
        return slash >= 0 ? path.substring(slash + 1) : path;
    }

    private boolean isSushefImage(String path) {
        return path != null && path.toLowerCase(Locale.ROOT).contains("sushef");
    }

    private String imageSrc(String ctx, String image, String fallback) {
        String value = image == null || image.isBlank() ? fallback : image.trim();
        if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("data:")) return value;
        return value.startsWith("/") ? ctx + value : ctx + "/" + value;
    }
%>
<%
    DashboardData dashboard = (DashboardData) request.getAttribute("dashboard");
    User currentUser = dashboard.currentUser();
    List<Recette> recettes = dashboard.recettes();
    List<Produit> produits = dashboard.produits();
    List<User> users = dashboard.users();
    List<Commande> userCommandes = dashboard.userCommandes();
    List<Commande> allCommandes = dashboard.allCommandes();
    Recette recetteEdition = dashboard.recetteEdition();
    String workspaceMode = (String) request.getAttribute("workspaceMode");
    String flashType = (String) request.getAttribute("flashType");
    String flashMessage = (String) request.getAttribute("flashMessage");
    String ctx = request.getContextPath();
    List<String> contentImages = new ArrayList<>();
    List<String> sushefImages = new ArrayList<>();
    Set<String> assetResourcePaths = application.getResourcePaths("/assets/img/");
    if (assetResourcePaths != null) {
        for (String assetPath : assetResourcePaths) {
            if (assetPath == null || assetPath.endsWith("/")) continue;
            String lowerPath = assetPath.toLowerCase(Locale.ROOT);
            if (lowerPath.endsWith(".png") || lowerPath.endsWith(".jpg") || lowerPath.endsWith(".jpeg") || lowerPath.endsWith(".gif") || lowerPath.endsWith(".webp") || lowerPath.endsWith(".svg")) {
                if (isSushefImage(assetPath)) {
                    sushefImages.add(assetPath);
                } else {
                    contentImages.add(assetPath);
                }
            }
        }
    }
    Collections.sort(contentImages);
    Collections.sort(sushefImages);
    if (contentImages.isEmpty()) {
        contentImages.add("/assets/img/recipe-step-finish.png");
        contentImages.add("/assets/img/recipe-step-prep.png");
    }
    if (sushefImages.isEmpty()) {
        sushefImages.add("/assets/img/sushef-focused.png");
        sushefImages.add("/assets/img/sushef-happy.png");
        sushefImages.add("/assets/img/sushef-score.png");
    }
    String defaultCoverImage = containsImage(contentImages, "/assets/img/recipe-step-finish.png") ? "/assets/img/recipe-step-finish.png" : contentImages.get(0);
    String defaultStepImage = containsImage(contentImages, "/assets/img/recipe-step-prep.png") ? "/assets/img/recipe-step-prep.png" : contentImages.get(0);
    String defaultRecipeSushefImage = containsImage(sushefImages, "/assets/img/sushef-happy.png") ? "/assets/img/sushef-happy.png" : sushefImages.get(0);
    String defaultStepSushefImage = containsImage(sushefImages, "/assets/img/sushef-focused.png") ? "/assets/img/sushef-focused.png" : defaultRecipeSushefImage;
    DecimalFormat money = new DecimalFormat("0.00");
    DecimalFormat qty = new DecimalFormat("0.##");
    int cartCount = countCartItems(currentUser);
    boolean admin = currentUser != null && currentUser.isAdmin();
    int favoritesCount = currentUser == null ? 0 : currentUser.getFavoris().size();
    Map<Integer, Recette> recettesById = new HashMap<>();
    for (Recette recette : recettes) recettesById.put(recette.getId(), recette);
    Map<Integer, Produit> produitsById = new HashMap<>();
    for (Produit produit : produits) produitsById.put(produit.getId(), produit);
    List<Ingredient> ingredientsEdition = recetteEdition == null ? Collections.emptyList() : recetteEdition.getIngredients();
    List<?> recipeStepsEdition = recipeSteps(recetteEdition);
    if (workspaceMode == null || workspaceMode.isBlank()) workspaceMode = "account";
%>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Espace Sushef</title>
    <link rel="stylesheet" href="<%= ctx %>/assets/app.css?v=admin-orders-scroll-1">
</head>
<body class="app-page app-page--catalog workspace-page <%= "cart".equals(workspaceMode) ? "workspace-page--cart" : "" %> <%= "recipes".equals(workspaceMode) ? "workspace-page--recipes" : "" %> <%= "stock".equals(workspaceMode) ? "workspace-page--stock" : "" %> <%= "orders".equals(workspaceMode) ? "workspace-page--orders" : "" %> <%= "users".equals(workspaceMode) ? "workspace-page--users" : "" %> <%= "admin".equals(workspaceMode) ? "workspace-page--admin" : "" %>">
<header class="topbar topbar--catalog">
    <a class="brand brand--landing" href="<%= ctx %>/">
        <span>Sushef</span>
    </a>
    <div class="top-meta">
        <a class="cart-link cart-link--light" href="<%= currentUser != null ? ctx + "/workspace?mode=cart" : ctx + "/auth?returnPage=workspace&returnMode=cart" %>">🧺<% if (cartCount > 0) { %><span class="cart-badge"><%= cartCount %></span><% } %></a>
        <a class="account-photo" href="<%= currentUser != null ? ctx + "/workspace?mode=account" : ctx + "/auth?returnPage=workspace&returnMode=account" %>" aria-label="<%= currentUser != null ? "Compte " + esc(currentUser.getUsername()) : "Compte" %>"><span><%= esc(initials(currentUser)) %></span></a>
    </div>
</header>

<% if (flashMessage != null && !flashMessage.isBlank()) { %>
<div class="flash flash--<%= esc(flashType == null ? "info" : flashType) %>"><%= esc(flashMessage) %></div>
<% } %>

<main class="catalog-shell workspace-shell <%= "recipes".equals(workspaceMode) ? "workspace-shell--recipes" : "" %>">
    <section class="catalog-panel workspace-panel <%= "recipes".equals(workspaceMode) ? "workspace-panel--recipes" : "" %>">
        <div class="workspace-panel__inner <%= "recipes".equals(workspaceMode) ? "workspace-panel__inner--recipes" : "" %>">
            <% if ("account".equals(workspaceMode)) { %>
                <div class="catalog-panel__head workspace-panel__head">
                    <p class="eyebrow">Mon compte</p>
                </div>
                <% if (currentUser == null) { %>
                    <div class="utility-grid account-grid account-grid--guest">
                        <article class="utility-card account-card account-card--guest">
                            <p class="helper">Connectez-vous ou créez un compte pour retrouver vos favoris, votre panier et vos commandes</p>
                            <div class="auth-actions">
                                <a class="button button--outline" href="<%= ctx %>/auth?returnPage=workspace&returnMode=account">Se connecter</a>
                                <a class="button button--ghost" href="<%= ctx %>/auth?mode=register&returnPage=workspace&returnMode=account">Créer un compte</a>
                            </div>
                        </article>
                        <article class="utility-card account-card account-card--guest">
                            <p class="helper">Vous pouvez déjà parcourir les recettes et revenir ici après connexion</p>
                            <div class="auth-actions"><a class="button button--ghost" href="<%= ctx %>/app">Voir le catalogue</a></div>
                        </article>
                    </div>
                <% } else { %>
                    <div class="utility-grid account-grid">
                        <article class="utility-card account-card">
                            <div class="profile-box"><div class="avatar avatar--large"><%= esc(initials(currentUser)) %></div><div><p><strong><%= esc(currentUser.getUsername()) %></strong></p><p><%= admin ? "Administrateur" : "Utilisateur" %></p></div></div>
                            <div class="auth-highlights"><span class="auth-pill">Favoris : <%= favoritesCount %></span><span class="auth-pill">Panier : <%= cartCount %></span><span class="auth-pill">Commandes : <%= userCommandes.size() %></span></div>
                            <div class="favorite-mini-list">
                                <p class="eyebrow">Favoris sauvegardés</p>
                                <% if (favoritesCount == 0) { %>
                                    <p class="helper">Aucune recette favorite pour le moment</p>
                                <% } else { %>
                                    <ul>
                                        <% for (Integer favoriteId : currentUser.getFavoris()) { Recette favorite = recettesById.get(favoriteId); if (favorite != null) { %>
                                            <li><a href="<%= ctx %>/recipe?id=<%= favorite.getId() %>"><%= esc(favorite.getTitre()) %></a></li>
                                        <% }} %>
                                    </ul>
                                <% } %>
                            </div>
                            <p class="helper">Votre espace est maintenant découpé en pages dédiées pour que chaque action ait son propre écran</p>
                            <div class="auth-actions"><a class="button button--outline" href="<%= ctx %>/workspace?mode=cart">Voir le panier</a><a class="button button--ghost" href="<%= ctx %>/app">Retour au catalogue</a><% if (admin) { %><a class="button button--ghost" href="<%= ctx %>/workspace?mode=admin">Ouvrir l'admin</a><% } %><form method="post" action="<%= ctx %>/auth/logout"><input type="hidden" name="returnPage" value="workspace"><input type="hidden" name="returnMode" value="account"><button type="submit" class="danger-button">Se déconnecter</button></form></div>
                        </article>
                        <article class="utility-card account-card">
                            <div class="section-head"><div><p class="eyebrow">Historique</p><h2>Mes commandes</h2></div></div>
                            <% if (userCommandes.isEmpty()) { %>
                                <p class="helper">Aucune commande pour le moment</p>
                            <% } else { %>
                                <div class="order-stack">
                                    <% for (Commande commande : userCommandes.subList(0, Math.min(userCommandes.size(), 4))) { %>
                                        <article class="order-card"><div class="order-card__head"><strong>Commande #<%= commande.getId() %></strong><span><%= money.format(commande.getTotal()) %> €</span></div><p><%= esc(commande.getDateCreation()) %></p></article>
                                    <% } %>
                                </div>
                            <% } %>
                        </article>
                    </div>
                <% } %>

            <% } else if ("cart".equals(workspaceMode)) { %>
                <% double totalPanier = 0D; int lignesPanier = 0; %>
                <% if (currentUser == null) { %>
                <% } else if (currentUser != null) { for (PanierItem item : currentUser.getPanier()) { Produit produit = produitsById.get(item.getProduitId()); if (produit == null) continue; totalPanier += produit.getPrixUnitaire() * item.getQuantite(); lignesPanier++; }} %>
                <div class="catalog-panel__head workspace-panel__head">
                    <p class="eyebrow">Panier</p>
                </div>
                <div class="cart-page cart-page--workspace">
                    <div class="cart-grid">
                        <article class="utility-card cart-card cart-card--list">
                            <% if (currentUser == null) { %>
                                <div class="cart-empty-state">
                                    <p class="helper">Connectez-vous pour accéder à votre panier et finaliser une commande</p>
                                    <a class="button button--outline button--wide" href="<%= ctx %>/auth?returnPage=workspace&returnMode=cart">Se connecter</a>
                                    <a class="button button--ghost button--wide" href="<%= ctx %>/auth?mode=register&returnPage=workspace&returnMode=cart">Créer un compte</a>
                                </div>
                            <% } else if (currentUser.getPanier().isEmpty()) { %>
                                <div class="cart-empty-state">
                                    <p class="helper">Votre panier est vide</p>
                                    <a class="button button--outline button--wide" href="<%= ctx %>/app">Ajouter une recette</a>
                                </div>
                            <% } else { %>
                                <ul class="cart-ingredient-list">
                                    <% for (PanierItem item : currentUser.getPanier()) { Produit produit = produitsById.get(item.getProduitId()); if (produit == null) continue; double sousTotal = produit.getPrixUnitaire() * item.getQuantite(); %>
                                        <li>
                                            <div class="cart-ingredient-list__main">
                                                <span><%= qty.format(item.getQuantite()) %> <%= esc(item.getUnite()) %> <%= esc(produit.getNom()) %></span>
                                                <strong><%= money.format(sousTotal) %> €</strong>
                                            </div>
                                            <div class="cart-ingredient-list__aside">
                                                <form method="post" action="<%= ctx %>/cart/remove">
                                                    <input type="hidden" name="productId" value="<%= produit.getId() %>">
                                                    <input type="hidden" name="returnPage" value="workspace">
                                                    <input type="hidden" name="returnMode" value="cart">
                                                    <button type="submit" class="icon-pill cart-line__remove">×</button>
                                                </form>
                                            </div>
                                        </li>
                                    <% } %>
                                </ul>
                                <form method="post" action="<%= ctx %>/cart/clear" class="cart-clear-form">
                                    <input type="hidden" name="returnPage" value="workspace">
                                    <input type="hidden" name="returnMode" value="cart">
                                    <button type="submit" class="button button--ghost button--wide">Vider le panier</button>
                                </form>
                            <% } %>
                        </article>

                        <aside class="utility-card cart-card cart-card--summary">
                            <div class="cart-summary">
                                <p class="eyebrow">Total</p>
                                <h3><%= money.format(totalPanier) %> €</h3>
                                <div class="auth-highlights">
                                    <span class="auth-pill">Articles : <%= cartCount %></span>
                                    <span class="auth-pill">Ingrédients : <%= lignesPanier %></span>
                                </div>
                            </div>
                            <div class="cart-summary__actions">
                                <a class="button button--ghost button--wide" href="<%= ctx %>/app">Retour au catalogue</a>
                                <form method="post" action="<%= ctx %>/orders/checkout" class="cart-summary__form">
                                    <input type="hidden" name="returnPage" value="workspace">
                                    <input type="hidden" name="returnMode" value="cart">
                                    <button type="submit" class="button button--outline button--wide" <%= currentUser == null || currentUser.getPanier().isEmpty() ? "disabled" : "" %>>Passer commande</button>
                                </form>
                            </div>
                        </aside>
                    </div>
                </div>

            <% } else if ("admin".equals(workspaceMode)) { %>
                <div class="section-head"><div><p class="eyebrow">Back Office</p><h2>Tableau de bord</h2></div></div>
                <div class="admin-grid"><a class="admin-tile" href="<%= ctx %>/workspace?mode=recipes"><span>＋</span><strong>Recettes</strong></a><a class="admin-tile" href="<%= ctx %>/workspace?mode=stock"><span>▣</span><strong>Stock</strong></a><a class="admin-tile" href="<%= ctx %>/workspace?mode=orders"><span>◎</span><strong>Commandes</strong></a><a class="admin-tile" href="<%= ctx %>/workspace?mode=users"><span>◉</span><strong>Utilisateurs</strong></a></div>
                <div class="admin-dashboard-actions"><form method="post" action="<%= ctx %>/auth/logout"><input type="hidden" name="returnPage" value="app"><button type="submit" class="button button--ghost">Déconnexion / retour au site</button></form></div>

            <% } else if ("users".equals(workspaceMode)) { %>
                <div class="section-head"><div><p class="eyebrow">Utilisateurs</p><h2>Gestion des comptes</h2></div><div class="auth-actions"><a class="button button--ghost" href="<%= ctx %>/workspace?mode=admin">Retour au menu admin</a></div></div>
                <div class="admin-user-table-wrap">
                    <table class="admin-user-table">
                        <thead>
                            <tr><th>Identifiant</th><th>Mot de passe (hash)</th><th>Rôle</th><th>Action</th></tr>
                        </thead>
                        <tbody>
                            <% for (User user : users) { %>
                                <tr>
                                    <td><strong><%= esc(user.getUsername()) %></strong><span>#<%= user.getId() %></span></td>
                                    <td><code><%= esc(user.getPasswordHash()) %></code></td>
                                    <td><%= user.isAdmin() ? "Administrateur" : "Utilisateur" %></td>
                                    <td>
                                        <% if (currentUser != null && user.getId() == currentUser.getId()) { %>
                                            <span class="admin-user-table__note">Compte connecté</span>
                                        <% } else { %>
                                            <form method="post" action="<%= ctx %>/admin/users/delete"><input type="hidden" name="userId" value="<%= user.getId() %>"><input type="hidden" name="returnPage" value="workspace"><input type="hidden" name="returnMode" value="users"><button type="submit" class="danger-button">Supprimer</button></form>
                                        <% } %>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>

            <% } else if ("recipes".equals(workspaceMode)) { %>
                <div class="section-head"><div><p class="eyebrow">Recette Maker</p><h2><%= recetteEdition == null ? "Créer une recette" : "Modifier une recette" %></h2></div><div class="auth-actions"><a class="button button--ghost" href="<%= ctx %>/workspace?mode=admin">Retour au menu admin</a></div></div>
                <div class="maker-layout">
                    <form method="post" action="<%= ctx %>/admin/recipes/save" class="maker-form">
                        <% if (recetteEdition != null) { %><input type="hidden" name="recipeId" value="<%= recetteEdition.getId() %>"><input type="hidden" name="returnEditRecipeId" value="<%= recetteEdition.getId() %>"><% } %>
                        <input type="hidden" name="returnPage" value="workspace">
                        <input type="hidden" name="returnMode" value="recipes">
                        <div class="builder-chip"><%= recetteEdition == null ? "Nouvelle recette" : "Edition" %></div>
                        <label>Titre<input type="text" name="title" value="<%= recetteEdition == null ? "" : esc(recetteEdition.getTitre()) %>" required></label>
                        <% String coverImage = recetteEdition == null || recetteEdition.getImageCouverture() == null || recetteEdition.getImageCouverture().isBlank() ? defaultCoverImage : recetteEdition.getImageCouverture().trim(); %>
                        <% String recipeSushefImage = recetteEdition == null || recetteEdition.getImageSushef() == null || recetteEdition.getImageSushef().isBlank() ? defaultRecipeSushefImage : recetteEdition.getImageSushef().trim(); %>
                        <label class="maker-image-field">Image de couverture
                            <span class="maker-image-picker">
                                <img class="maker-image-preview" data-image-preview src="<%= esc(imageSrc(ctx, coverImage, defaultCoverImage)) %>" alt="Aperçu couverture">
                                <select name="coverImage" data-image-choice required>
                                    <% for (String contentImage : contentImages) { %>
                                        <option value="<%= esc(contentImage) %>" <%= sameImage(coverImage, contentImage) ? "selected" : "" %>><%= esc(fileName(contentImage)) %></option>
                                    <% } %>
                                    <% if (!coverImage.isBlank() && !containsImage(contentImages, coverImage)) { %><option value="<%= esc(coverImage) %>" selected>actuelle - <%= esc(fileName(coverImage)) %></option><% } %>
                                </select>
                            </span>
                        </label>
                        <label class="maker-image-field">Image Sushef
                            <span class="maker-image-picker maker-image-picker--chef">
                                <img class="maker-image-preview maker-image-preview--chef" data-image-preview src="<%= esc(imageSrc(ctx, recipeSushefImage, defaultRecipeSushefImage)) %>" alt="Aperçu Sushef">
                                <select name="sushefImage" data-image-choice required>
                                    <% for (String sushefImage : sushefImages) { %>
                                        <option value="<%= esc(sushefImage) %>" <%= sameImage(recipeSushefImage, sushefImage) ? "selected" : "" %>><%= esc(fileName(sushefImage)) %></option>
                                    <% } %>
                                    <% if (!recipeSushefImage.isBlank() && !containsImage(sushefImages, recipeSushefImage)) { %><option value="<%= esc(recipeSushefImage) %>" selected>actuelle - <%= esc(fileName(recipeSushefImage)) %></option><% } %>
                                </select>
                            </span>
                        </label>
                        <div class="form-row"><label>Temps de préparation<input type="number" min="1" name="prepMinutes" value="<%= recetteEdition == null || recetteEdition.getTempsPreparationMinutes() <= 0 ? "" : recetteEdition.getTempsPreparationMinutes() %>" required></label></div>
                        <div class="form-row"><label>Difficulté<select name="difficulty" required><option value="1" <%= recetteEdition != null && recetteEdition.getDifficulte() == 1 ? "selected" : "" %>>Facile</option><option value="2" <%= recetteEdition != null && recetteEdition.getDifficulte() == 2 ? "selected" : "" %>>Moyen</option><option value="3" <%= recetteEdition != null && recetteEdition.getDifficulte() == 3 ? "selected" : "" %>>Difficile</option></select></label></div>
                        <label class="checkbox-field"><input type="checkbox" name="needsVinegaredRice" value="true" <%= recetteEdition == null || recetteEdition.isNecessiteRizVinaigre() ? "checked" : "" %>><span>Cette recette nécessite du riz vinaigré</span></label>
                        <div class="section-head"><div><p class="eyebrow">Étapes</p><h2>Réalisation</h2></div><button type="button" class="button button--ghost" data-add-step>Ajouter une étape</button></div>
                        <div id="step-rows">
                            <% if (recetteEdition == null || recipeStepsEdition.isEmpty()) { %>
                                <div class="step-row"><label>Texte<textarea name="stepText" rows="3" placeholder="Cuire et assaisonner le riz." required></textarea></label><label class="maker-image-field">Image de l'étape<span class="maker-image-picker maker-image-picker--step"><img class="maker-image-preview" data-image-preview src="<%= esc(imageSrc(ctx, defaultStepImage, defaultStepImage)) %>" alt="Aperçu étape"><select name="stepImage" data-image-choice><% for (String contentImage : contentImages) { %><option value="<%= esc(contentImage) %>" <%= sameImage(defaultStepImage, contentImage) ? "selected" : "" %>><%= esc(fileName(contentImage)) %></option><% } %></select></span></label><label class="maker-image-field">Image Sushef<span class="maker-image-picker maker-image-picker--step maker-image-picker--chef"><img class="maker-image-preview maker-image-preview--chef" data-image-preview src="<%= esc(imageSrc(ctx, defaultStepSushefImage, defaultStepSushefImage)) %>" alt="Aperçu Sushef"><select name="stepSushefImage" data-image-choice><% for (String sushefImage : sushefImages) { %><option value="<%= esc(sushefImage) %>" <%= sameImage(defaultStepSushefImage, sushefImage) ? "selected" : "" %>><%= esc(fileName(sushefImage)) %></option><% } %></select></span></label><button type="button" class="icon-pill" data-remove-step>×</button></div>
                            <% } else { for (Object etape : recipeStepsEdition) { %>
                                <% String currentStepImage = stepImage(etape); if (currentStepImage == null || currentStepImage.isBlank()) currentStepImage = defaultStepImage; else currentStepImage = currentStepImage.trim(); %>
                                <% String currentStepSushefImage = stepSushefImage(etape); if (currentStepSushefImage == null || currentStepSushefImage.isBlank()) currentStepSushefImage = defaultStepSushefImage; else currentStepSushefImage = currentStepSushefImage.trim(); %>
                                <div class="step-row"><label>Texte<textarea name="stepText" rows="3" placeholder="Décrivez cette étape." required><%= esc(stepText(etape)) %></textarea></label><label class="maker-image-field">Image de l'étape<span class="maker-image-picker maker-image-picker--step"><img class="maker-image-preview" data-image-preview src="<%= esc(imageSrc(ctx, currentStepImage, defaultStepImage)) %>" alt="Aperçu étape"><select name="stepImage" data-image-choice><% for (String contentImage : contentImages) { %><option value="<%= esc(contentImage) %>" <%= sameImage(currentStepImage, contentImage) ? "selected" : "" %>><%= esc(fileName(contentImage)) %></option><% } %><% if (!currentStepImage.isBlank() && !containsImage(contentImages, currentStepImage)) { %><option value="<%= esc(currentStepImage) %>" selected>actuelle - <%= esc(fileName(currentStepImage)) %></option><% } %></select></span></label><label class="maker-image-field">Image Sushef<span class="maker-image-picker maker-image-picker--step maker-image-picker--chef"><img class="maker-image-preview maker-image-preview--chef" data-image-preview src="<%= esc(imageSrc(ctx, currentStepSushefImage, defaultStepSushefImage)) %>" alt="Aperçu Sushef"><select name="stepSushefImage" data-image-choice><% for (String sushefImage : sushefImages) { %><option value="<%= esc(sushefImage) %>" <%= sameImage(currentStepSushefImage, sushefImage) ? "selected" : "" %>><%= esc(fileName(sushefImage)) %></option><% } %><% if (!currentStepSushefImage.isBlank() && !containsImage(sushefImages, currentStepSushefImage)) { %><option value="<%= esc(currentStepSushefImage) %>" selected>actuelle - <%= esc(fileName(currentStepSushefImage)) %></option><% } %></select></span></label><button type="button" class="icon-pill" data-remove-step>×</button></div>
                            <% }} %>
                        </div>
                        <div class="section-head"><div><p class="eyebrow">Ingrédients</p><h2>Composition</h2></div><button type="button" class="button button--ghost" data-add-ingredient>Ajouter une ligne</button></div>
                        <div id="ingredient-rows">
                            <% if (ingredientsEdition.isEmpty()) { %>
                                <div class="ingredient-row"><select name="ingredientProductId" required><option value="">Produit</option><% for (Produit produit : produits) { %><option value="<%= produit.getId() %>" data-unit="<%= esc(produit.getUnite()) %>"><%= esc(produit.getNom()) %></option><% } %></select><input type="number" step="0.01" min="0" name="ingredientQuantity" placeholder="Quantité" required><input type="text" name="ingredientUnit" placeholder="Unité"><button type="button" class="icon-pill" data-remove-ingredient>×</button></div>
                            <% } else { for (Ingredient ingredient : ingredientsEdition) { %>
                                <div class="ingredient-row"><select name="ingredientProductId" required><option value="">Produit</option><% for (Produit produit : produits) { boolean selected = ingredient.getProduit() != null && ingredient.getProduit().getId() == produit.getId(); %><option value="<%= produit.getId() %>" data-unit="<%= esc(produit.getUnite()) %>" <%= selected ? "selected" : "" %>><%= esc(produit.getNom()) %></option><% } %></select><input type="number" step="0.01" min="0" name="ingredientQuantity" value="<%= qty.format(ingredient.getQuantite()).replace(',', '.') %>" required><input type="text" name="ingredientUnit" value="<%= esc(ingredient.getUnite()) %>"><button type="button" class="icon-pill" data-remove-ingredient>×</button></div>
                            <% }} %>
                        </div>
                        <div class="maker-actions"><button type="submit" class="button button--outline"><%= recetteEdition == null ? "Enregistrer la recette" : "Sauvegarder" %></button><a class="button button--ghost" href="<%= ctx %>/workspace?mode=recipes">Nouvelle recette</a></div>
                    </form>
                    <aside class="maker-sidebar">
                        <div class="section-head"><div><p class="eyebrow">Gestion</p><h2>Recettes existantes</h2></div></div>
                        <div class="admin-recipe-list">
                            <% for (Recette recette : recettes) { %>
                                <article class="admin-recipe-item"><div><strong><%= esc(recette.getTitre()) %></strong><p>#<%= recette.getId() %> · <%= recette.getIngredients().size() %> ingrédients</p></div><div class="admin-recipe-actions"><a class="button button--ghost" href="<%= ctx %>/workspace?mode=recipes&editRecipeId=<%= recette.getId() %>">Modifier</a><form method="post" action="<%= ctx %>/admin/recipes/delete"><input type="hidden" name="recipeId" value="<%= recette.getId() %>"><input type="hidden" name="returnPage" value="workspace"><input type="hidden" name="returnMode" value="recipes"><button type="submit" class="danger-button">Supprimer</button></form></div></article>
                            <% } %>
                        </div>
                    </aside>
                </div>

            <% } else if ("stock".equals(workspaceMode)) { %>
                <div class="section-head"><div><p class="eyebrow">Stock</p><h2>Gestion des ingrédients</h2></div><div class="auth-actions"><a class="button button--ghost" href="<%= ctx %>/workspace?mode=admin">Retour au menu admin</a></div></div>
                <form method="post" action="<%= ctx %>/admin/products/save" class="stock-create-form"><input type="hidden" name="returnPage" value="workspace"><input type="hidden" name="returnMode" value="stock"><label>Nom<input type="text" name="name" required></label><label>Stock<input type="number" step="0.01" min="0" name="stock" required></label><label>Unité<input type="text" name="unit" required></label><label>Prix<input type="number" step="0.01" min="0" name="price" required></label><button type="submit" class="button button--outline">Ajouter</button></form>
                <div class="stock-grid">
                    <% for (Produit produit : produits) { %>
                        <form method="post" action="<%= ctx %>/admin/products/save" class="stock-card"><input type="hidden" name="productId" value="<%= produit.getId() %>"><input type="hidden" name="returnPage" value="workspace"><input type="hidden" name="returnMode" value="stock"><label>Nom<input type="text" name="name" value="<%= esc(produit.getNom()) %>" required></label><label>Stock<input type="number" step="0.01" min="0" name="stock" value="<%= qty.format(produit.getStock()).replace(',', '.') %>" required></label><label>Unité<input type="text" name="unit" value="<%= esc(produit.getUnite()) %>" required></label><label>Prix<input type="number" step="0.01" min="0" name="price" value="<%= money.format(produit.getPrixUnitaire()).replace(',', '.') %>" required></label><button type="submit" class="button button--ghost">Mettre à jour</button></form>
                    <% } %>
                </div>

            <% } else if ("orders".equals(workspaceMode)) { %>
                <div class="section-head"><div><p class="eyebrow">Commandes</p><h2>Vue administrateur</h2></div><div class="auth-actions"><a class="button button--ghost" href="<%= ctx %>/workspace?mode=admin">Retour au menu admin</a></div></div>
                <% if (allCommandes.isEmpty()) { %>
                    <p class="helper">Aucune commande enregistrée</p>
                <% } else { %>
                    <div class="order-stack"><% for (Commande commande : allCommandes) { %><article class="order-card order-card--admin"><div class="order-card__head"><strong>Commande #<%= commande.getId() %> · <%= esc(commande.getUsername()) %></strong><span><%= money.format(commande.getTotal()) %> €</span></div><p><%= esc(commande.getDateCreation()) %></p><ul class="admin-order-items"><% for (CommandeItem item : commande.getItems()) { %><li><%= esc(item.getRecetteTitre()) %> · <%= item.getQuantite() %> × <%= money.format(item.getPrixUnitaire()) %> €</li><% } %></ul></article><% } %></div>
                <% } %>
            <% } %>
        </div>
    </section>
</main>

<script src="<%= ctx %>/assets/app.js?v=responsive-stack-1"></script>
<template id="ingredient-template">
    <div class="ingredient-row"><select name="ingredientProductId" required><option value="">Produit</option><% for (Produit produit : produits) { %><option value="<%= produit.getId() %>" data-unit="<%= esc(produit.getUnite()) %>"><%= esc(produit.getNom()) %></option><% } %></select><input type="number" step="0.01" min="0" name="ingredientQuantity" placeholder="Quantité" required><input type="text" name="ingredientUnit" placeholder="Unité"><button type="button" class="icon-pill" data-remove-ingredient>×</button></div>
</template>
<template id="step-template">
    <div class="step-row"><label>Texte<textarea name="stepText" rows="3" placeholder="Décrivez cette étape." required></textarea></label><label class="maker-image-field">Image de l'étape<span class="maker-image-picker maker-image-picker--step"><img class="maker-image-preview" data-image-preview src="<%= esc(imageSrc(ctx, defaultStepImage, defaultStepImage)) %>" alt="Aperçu étape"><select name="stepImage" data-image-choice><% for (String contentImage : contentImages) { %><option value="<%= esc(contentImage) %>" <%= sameImage(defaultStepImage, contentImage) ? "selected" : "" %>><%= esc(fileName(contentImage)) %></option><% } %></select></span></label><label class="maker-image-field">Image Sushef<span class="maker-image-picker maker-image-picker--step maker-image-picker--chef"><img class="maker-image-preview maker-image-preview--chef" data-image-preview src="<%= esc(imageSrc(ctx, defaultStepSushefImage, defaultStepSushefImage)) %>" alt="Aperçu Sushef"><select name="stepSushefImage" data-image-choice><% for (String sushefImage : sushefImages) { %><option value="<%= esc(sushefImage) %>" <%= sameImage(defaultStepSushefImage, sushefImage) ? "selected" : "" %>><%= esc(fileName(sushefImage)) %></option><% } %></select></span></label><button type="button" class="icon-pill" data-remove-step>×</button></div>
</template>
</body>
</html>
