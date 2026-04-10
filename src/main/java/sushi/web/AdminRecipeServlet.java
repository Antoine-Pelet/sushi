package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.Recette;
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
                Recette recette = handleSave(request, userId);
                setFlash(request, "success", "Recette enregistree.");
                response.sendRedirect(buildRedirectTarget(
                        request.getContextPath(),
                        request.getParameter("returnPage"),
                        request.getParameter("returnRecipeId"),
                        Integer.toString(recette.getId()),
                        request.getParameter("returnMode"),
                        request.getParameter("returnSection")
                ));
                return;
            } else {
                service(request).deleteRecipe(userId, requiredInt(request, "recipeId"));
                setFlash(request, "success", "Recette supprimee.");
            }
        } catch (IllegalArgumentException | SushiException exception) {
            setFlash(request, "error", exception.getMessage());
        }

        redirectToApp(request, response);
    }

    private Recette handleSave(HttpServletRequest request, int userId) {
        Integer recipeId = optionalInt(request, "recipeId");
        String[] productIds = request.getParameterValues("ingredientProductId");
        String[] quantities = request.getParameterValues("ingredientQuantity");
        String[] units = request.getParameterValues("ingredientUnit");
        String[] stepTexts = request.getParameterValues("stepText");
        String[] stepImages = request.getParameterValues("stepImage");

        List<SushiService.IngredientForm> ingredients = new ArrayList<>();
        List<SushiService.StepForm> steps = new ArrayList<>();
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

        if (stepTexts != null) {
            for (int i = 0; i < stepTexts.length; i++) {
                String text = stepTexts[i];
                String image = stepImages != null && stepImages.length > i ? stepImages[i] : null;
                if (text == null || text.isBlank()) {
                    continue;
                }
                steps.add(new SushiService.StepForm(text, image));
            }
        }

        return service(request).saveRecipe(
                userId,
                recipeId,
                request.getParameter("title"),
                request.getParameter("coverImage"),
                requiredInt(request, "prepMinutes"),
                requiredInt(request, "difficulty"),
                request.getParameter("needsVinegaredRice") != null,
                ingredients,
                steps
        );
    }
}
