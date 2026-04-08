package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import sushi.Commande;
import sushi.JsonUtil;
import sushi.Produit;
import sushi.Recette;
import sushi.SushiException;
import sushi.SushiService;
import sushi.User;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@WebServlet("/api/*")
public class ApiServlet extends BaseServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json; charset=UTF-8");

        try {
            String path = normalizePath(request.getPathInfo());
            switch (path) {
                case "/recipes" -> handleRecipes(request, response);
                case "/products" -> handleProducts(request, response);
                case "/me" -> handleMe(request, response);
                case "/orders" -> handleOrders(request, response);
                default -> sendJson(response, HttpServletResponse.SC_NOT_FOUND, JsonUtil.error("Endpoint API introuvable."));
            }
        } catch (IllegalArgumentException | SushiException exception) {
            sendJson(response, statusFor(exception.getMessage()), JsonUtil.error(exception.getMessage()));
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");

        try {
            String path = normalizePath(request.getPathInfo());
            switch (path) {
                case "/session/login" -> handleLogin(request, response);
                case "/session/register" -> handleRegister(request, response);
                case "/session/logout" -> handleLogout(request, response);
                case "/favorites/toggle" -> handleFavoriteToggle(request, response);
                case "/cart/add" -> handleCartAdd(request, response);
                case "/cart/remove" -> handleCartRemove(request, response);
                case "/orders/checkout" -> handleCheckout(request, response);
                case "/admin/recipes/save" -> handleAdminRecipeSave(request, response);
                case "/admin/recipes/delete" -> handleAdminRecipeDelete(request, response);
                case "/admin/products/save" -> handleAdminProductSave(request, response);
                default -> sendJson(response, HttpServletResponse.SC_NOT_FOUND, JsonUtil.error("Endpoint API introuvable."));
            }
        } catch (IllegalArgumentException | SushiException exception) {
            sendJson(response, statusFor(exception.getMessage()), JsonUtil.error(exception.getMessage()));
        }
    }

    private void handleRecipes(HttpServletRequest request, HttpServletResponse response) throws IOException {
        SushiService.DashboardData dashboard = service(request).getDashboardData(currentUserId(request), null);
        User currentUser = dashboard.currentUser();
        Set<Integer> favorites = currentUser == null ? new HashSet<>() : new HashSet<>(currentUser.getFavoris());
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("OK",
                JsonUtil.recipes(dashboard.recettes(), dashboard.disponibilites(), favorites)));
    }

    private void handleProducts(HttpServletRequest request, HttpServletResponse response) throws IOException {
        SushiService.DashboardData dashboard = service(request).getDashboardData(currentUserId(request), null);
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("OK", JsonUtil.products(dashboard.produits())));
    }

    private void handleMe(HttpServletRequest request, HttpServletResponse response) throws IOException {
        SushiService.DashboardData dashboard = service(request).getDashboardData(currentUserId(request), null);
        if (dashboard.currentUser() == null) {
            throw new SushiException("Connexion requise.");
        }

        Map<Integer, Recette> recipesById = recipesById(dashboard.recettes());
        String dataJson = "{"
                + "\"user\":" + JsonUtil.user(dashboard.currentUser(), recipesById)
                + ",\"orders\":" + JsonUtil.orders(dashboard.userCommandes())
                + "}";
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("OK", dataJson));
    }

    private void handleOrders(HttpServletRequest request, HttpServletResponse response) throws IOException {
        SushiService.DashboardData dashboard = service(request).getDashboardData(currentUserId(request), null);
        User currentUser = dashboard.currentUser();
        if (currentUser == null) {
            throw new SushiException("Connexion requise.");
        }

        List<Commande> orders = currentUser.isAdmin() ? dashboard.allCommandes() : dashboard.userCommandes();
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("OK", JsonUtil.orders(orders)));
    }

    private void handleLogin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        User user = service(request).login(request.getParameter("username"), request.getParameter("password"));
        HttpSession session = request.getSession(true);
        session.setAttribute("userId", user.getId());

        SushiService.DashboardData dashboard = service(request).getDashboardData(user.getId(), null);
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Connexion reussie",
                JsonUtil.user(user, recipesById(dashboard.recettes()))));
    }

    private void handleRegister(HttpServletRequest request, HttpServletResponse response) throws IOException {
        User user = service(request).register(
                request.getParameter("username"),
                request.getParameter("password"),
                request.getParameter("confirmPassword")
        );
        HttpSession session = request.getSession(true);
        session.setAttribute("userId", user.getId());

        SushiService.DashboardData dashboard = service(request).getDashboardData(user.getId(), null);
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Compte cree",
                JsonUtil.user(user, recipesById(dashboard.recettes()))));
    }

    private void handleLogout(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Deconnexion reussie"));
    }

    private void handleFavoriteToggle(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Integer userId = currentUserId(request);
        if (userId == null) {
            throw new SushiException("Connexion requise.");
        }

        service(request).toggleFavorite(userId, requiredInt(request, "recipeId"));
        SushiService.DashboardData dashboard = service(request).getDashboardData(userId, null);
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Favoris mis a jour",
                JsonUtil.user(dashboard.currentUser(), recipesById(dashboard.recettes()))));
    }

    private void handleCartAdd(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Integer userId = currentUserId(request);
        if (userId == null) {
            throw new SushiException("Connexion requise.");
        }

        service(request).addToCart(userId, requiredInt(request, "recipeId"), optionalInt(request, "quantity", 1));
        SushiService.DashboardData dashboard = service(request).getDashboardData(userId, null);
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Panier mis a jour",
                JsonUtil.user(dashboard.currentUser(), recipesById(dashboard.recettes()))));
    }

    private void handleCartRemove(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Integer userId = currentUserId(request);
        if (userId == null) {
            throw new SushiException("Connexion requise.");
        }

        service(request).removeFromCart(userId, requiredInt(request, "recipeId"), optionalInt(request, "quantity", 1));
        SushiService.DashboardData dashboard = service(request).getDashboardData(userId, null);
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Panier mis a jour",
                JsonUtil.user(dashboard.currentUser(), recipesById(dashboard.recettes()))));
    }

    private void handleCheckout(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Integer userId = currentUserId(request);
        if (userId == null) {
            throw new SushiException("Connexion requise.");
        }

        Commande commande = service(request).checkout(userId);
        List<Commande> orders = new ArrayList<>();
        orders.add(commande);
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Commande validee", JsonUtil.orders(orders)));
    }

    private void handleAdminRecipeSave(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Integer userId = currentUserId(request);
        if (userId == null) {
            throw new SushiException("Connexion requise.");
        }

        List<SushiService.IngredientForm> ingredients = new ArrayList<>();
        String[] productIds = request.getParameterValues("ingredientProductId");
        String[] quantities = request.getParameterValues("ingredientQuantity");
        String[] units = request.getParameterValues("ingredientUnit");

        if (productIds != null) {
            for (int i = 0; i < productIds.length; i++) {
                String productId = productIds[i];
                String quantity = quantities != null && quantities.length > i ? quantities[i] : null;
                String unit = units != null && units.length > i ? units[i] : null;
                if (productId == null || productId.isBlank() || quantity == null || quantity.isBlank()) {
                    continue;
                }
                ingredients.add(new SushiService.IngredientForm(
                        Integer.parseInt(productId.trim()),
                        Double.parseDouble(quantity.trim().replace(',', '.')),
                        unit
                ));
            }
        }

        Recette recette = service(request).saveRecipe(
                userId,
                optionalInt(request, "recipeId"),
                request.getParameter("title"),
                request.getParameter("description"),
                requiredDouble(request, "price"),
                ingredients
        );

        SushiService.DashboardData dashboard = service(request).getDashboardData(userId, null);
        boolean favorite = dashboard.currentUser() != null && dashboard.currentUser().getFavoris().contains(recette.getId());
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Recette enregistree",
                JsonUtil.recipe(recette, dashboard.disponibilites().getOrDefault(recette.getId(), 0), favorite)));
    }

    private void handleAdminRecipeDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Integer userId = currentUserId(request);
        if (userId == null) {
            throw new SushiException("Connexion requise.");
        }

        service(request).deleteRecipe(userId, requiredInt(request, "recipeId"));
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Recette supprimee"));
    }

    private void handleAdminProductSave(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Integer userId = currentUserId(request);
        if (userId == null) {
            throw new SushiException("Connexion requise.");
        }

        Produit produit = service(request).saveProduct(
                userId,
                optionalInt(request, "productId"),
                request.getParameter("name"),
                requiredDouble(request, "stock"),
                request.getParameter("unit"),
                requiredDouble(request, "price")
        );

        List<Produit> products = new ArrayList<>();
        products.add(produit);
        sendJson(response, HttpServletResponse.SC_OK, JsonUtil.success("Produit enregistre", JsonUtil.products(products)));
    }

    private Map<Integer, Recette> recipesById(List<Recette> recettes) {
        Map<Integer, Recette> recipes = new HashMap<>();
        for (Recette recette : recettes) {
            recipes.put(recette.getId(), recette);
        }
        return recipes;
    }

    private int statusFor(String message) {
        if ("Connexion requise.".equals(message)) {
            return HttpServletResponse.SC_UNAUTHORIZED;
        }
        if ("Acces reserve a l'administrateur.".equals(message)) {
            return HttpServletResponse.SC_FORBIDDEN;
        }
        return HttpServletResponse.SC_BAD_REQUEST;
    }

    private void sendJson(HttpServletResponse response, int status, String body) throws IOException {
        response.setStatus(status);
        response.getWriter().write(body);
    }
}

