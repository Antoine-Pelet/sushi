package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.SushiException;
import sushi.SushiService;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet(urlPatterns = {"/admin/recipes/save", "/admin/recipes/delete"})
public class AdminRecipeServlet extends BaseServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");

        try {
            Integer userId = currentUserId(request);
            if (userId == null) {
                throw new SushiException("Connexion requise.");
            }

            if (request.getServletPath().endsWith("/save")) {
                handleSave(request, userId);
                setFlash(request, "success", "Recette enregistree.");
            } else {
                service(request).deleteRecipe(userId, requiredInt(request, "recipeId"));
                setFlash(request, "success", "Recette supprimee.");
            }
        } catch (IllegalArgumentException | SushiException exception) {
            setFlash(request, "error", exception.getMessage());
        }

        redirectToApp(request, response);
    }

    private void handleSave(HttpServletRequest request, int userId) {
        Integer recipeId = optionalInt(request, "recipeId");
        String[] productIds = request.getParameterValues("ingredientProductId");
        String[] quantities = request.getParameterValues("ingredientQuantity");
        String[] units = request.getParameterValues("ingredientUnit");

        List<SushiService.IngredientForm> ingredients = new ArrayList<>();
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

        service(request).saveRecipe(
                userId,
                recipeId,
                request.getParameter("title"),
                request.getParameter("description"),
                requiredDouble(request, "price"),
                ingredients
        );
    }
}
