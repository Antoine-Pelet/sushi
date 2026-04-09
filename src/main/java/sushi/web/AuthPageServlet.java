package sushi.web;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.SushiService;

import java.io.IOException;

@WebServlet("/auth")
public class AuthPageServlet extends BaseServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (redirectAdminToDashboard(request, response)) {
            return;
        }
        SushiService.DashboardData dashboard = service(request).getDashboardData(currentUserId(request), null);
        Flash flash = consumeFlash(request);

        request.setAttribute("dashboard", dashboard);
        request.setAttribute("authMode", normalizeMode(request.getParameter("mode")));
        request.setAttribute("returnPage", safe(request.getParameter("returnPage")));
        request.setAttribute("returnRecipeId", safe(request.getParameter("returnRecipeId")));
        request.setAttribute("returnEditRecipeId", safe(request.getParameter("returnEditRecipeId")));
        request.setAttribute("returnMode", safe(request.getParameter("returnMode")));
        request.setAttribute("returnSection", safe(request.getParameter("returnSection")));

        if (flash != null) {
            request.setAttribute("flashType", flash.type());
            request.setAttribute("flashMessage", flash.message());
        }

        request.getRequestDispatcher("/WEB-INF/views/auth.jsp").forward(request, response);
    }

    private String normalizeMode(String mode) {
        return "register".equalsIgnoreCase(mode) ? "register" : "login";
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }
}
