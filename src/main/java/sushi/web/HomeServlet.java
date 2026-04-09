package sushi.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.SushiService;

import java.io.IOException;

@WebServlet("/app")
public class HomeServlet extends BaseServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (redirectAdminToDashboard(request, response)) {
            return;
        }
        Integer editedRecipeId = optionalInt(request, "editRecipeId");
        SushiService.DashboardData dashboard = service(request).getDashboardData(currentUserId(request), editedRecipeId);
        Flash flash = consumeFlash(request);

        request.setAttribute("dashboard", dashboard);
        if (flash != null) {
            request.setAttribute("flashType", flash.type());
            request.setAttribute("flashMessage", flash.message());
        }
        request.getRequestDispatcher("/WEB-INF/views/app.jsp").forward(request, response);
    }
}
