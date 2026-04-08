package sushi.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.SushiService;
import sushi.User;

import java.io.IOException;

@WebServlet("/workspace")
public class WorkspaceServlet extends BaseServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Integer editedRecipeId = optionalInt(request, "editRecipeId");
        SushiService.DashboardData dashboard = service(request).getDashboardData(currentUserId(request), editedRecipeId);
        Flash flash = consumeFlash(request);

        request.setAttribute("dashboard", dashboard);
        request.setAttribute("workspaceMode", normalizeMode(request.getParameter("mode"), dashboard.currentUser()));
        if (flash != null) {
            request.setAttribute("flashType", flash.type());
            request.setAttribute("flashMessage", flash.message());
        }
        request.getRequestDispatcher("/WEB-INF/views/workspace.jsp").forward(request, response);
    }

    private String normalizeMode(String rawMode, User currentUser) {
        String mode = rawMode == null || rawMode.isBlank() ? "account" : rawMode.trim();
        mode = switch (mode) {
            case "account", "cart", "admin", "recipes", "stock", "orders" -> mode;
            default -> "account";
        };

        boolean admin = currentUser != null && currentUser.isAdmin();
        if (!admin && ("admin".equals(mode) || "recipes".equals(mode) || "stock".equals(mode) || "orders".equals(mode))) {
            return "account";
        }

        return mode;
    }
}
