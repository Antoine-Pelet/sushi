package sushi.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.Recette;
import sushi.EtapeRecette;
import sushi.SushiService;

import java.io.IOException;
import java.util.List;

@WebServlet("/cook")
public class CookServlet extends BaseServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (redirectAdminToDashboard(request, response)) {
            return;
        }
        Integer recipeId = optionalInt(request, "id");
        int startIndex = optionalInt(request, "start", defaultStartIndex());
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
        request.setAttribute("recipeSteps", selectedRecipe == null ? List.of() : selectedRecipe.getEtapes());
        request.setAttribute("startIndex", Math.max(0, startIndex));
        if (flash != null) {
            request.setAttribute("flashType", flash.type());
            request.setAttribute("flashMessage", flash.message());
        }
        request.getRequestDispatcher(viewPath()).forward(request, response);
    }

    protected int defaultStartIndex() {
        return 0;
    }

    protected String viewPath() {
        return "/WEB-INF/views/cook.jsp";
    }
}
