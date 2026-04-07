package sushi.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.Recette;
import sushi.SushiService;

import java.io.IOException;

@WebServlet("/recipe")
public class RecipeServlet extends BaseServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Integer recipeId = optionalInt(request, "id");
        SushiService.DashboardData dashboard = service(request).getDashboardData(currentUserId(request), null);
        Flash flash = consumeFlash(request);

        Recette selectedRecipe = null;
        if (recipeId != null) {
            for (Recette recette : dashboard.recettes()) {
                if (recette.getId() == recipeId.intValue()) {
                    selectedRecipe = recette;
                    break;
                }
            }
        }

        if (selectedRecipe == null && !dashboard.recettes().isEmpty()) {
            selectedRecipe = dashboard.recettes().get(0);
        }

        request.setAttribute("dashboard", dashboard);
        request.setAttribute("selectedRecipe", selectedRecipe);
        if (flash != null) {
            request.setAttribute("flashType", flash.type());
            request.setAttribute("flashMessage", flash.message());
        }
        request.getRequestDispatcher("/WEB-INF/views/recipe.jsp").forward(request, response);
    }
}
