package sushi.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.Recette;
import sushi.SushiService;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/cook")
public class CookServlet extends BaseServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
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
        request.setAttribute("recipeSteps", splitSteps(selectedRecipe == null ? null : selectedRecipe.getDescriptionEtapes()));
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

    private List<String> splitSteps(String text) {
        List<String> steps = new ArrayList<>();
        if (text == null || text.isBlank()) {
            return steps;
        }

        for (String rawLine : text.split("\\r?\\n")) {
            String line = rawLine.trim();
            if (line.isEmpty()) {
                continue;
            }
            steps.add(line.replaceFirst("^\\d+\\)\\s*", ""));
        }

        if (steps.isEmpty()) {
            steps.add(text.trim());
        }
        return steps;
    }
}
