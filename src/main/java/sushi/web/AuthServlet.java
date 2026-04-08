package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import sushi.SushiException;
import sushi.User;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet(urlPatterns = {"/auth/login", "/auth/logout", "/auth/register"})
public class AuthServlet extends BaseServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");

        String mode = request.getServletPath().endsWith("/register") ? "register" : "login";

        try {
            if (request.getServletPath().endsWith("/login")) {
                handleLogin(request);
                redirectAfterSuccess(request, response);
                return;
            }
            if (request.getServletPath().endsWith("/register")) {
                handleRegister(request);
                redirectAfterSuccess(request, response);
                return;
            }
            handleLogout(request);
            redirectToApp(request, response);
        } catch (IllegalArgumentException | SushiException exception) {
            setFlash(request, "error", exception.getMessage());
            redirectToAuthPage(request, response, mode);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.sendRedirect(request.getContextPath() + "/auth");
    }

    private void handleLogin(HttpServletRequest request) {
        User user = service(request).login(request.getParameter("username"), request.getParameter("password"));
        HttpSession session = request.getSession(true);
        session.setAttribute("userId", user.getId());
        setFlash(request, "success", "Connexion reussie pour " + user.getUsername() + ".");
    }

    private void handleRegister(HttpServletRequest request) {
        User user = service(request).register(
                request.getParameter("username"),
                request.getParameter("password"),
                request.getParameter("confirmPassword")
        );
        HttpSession session = request.getSession(true);
        session.setAttribute("userId", user.getId());
        setFlash(request, "success", "Compte cree pour " + user.getUsername() + ".");
    }

    private void handleLogout(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
    }

    private void redirectAfterSuccess(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String returnPage = request.getParameter("returnPage");
        String returnMode = request.getParameter("returnMode");
        String returnSection = request.getParameter("returnSection");

        if (returnPage == null || returnPage.isBlank() || "auth".equals(returnPage)) {
            returnPage = "workspace";
            if (returnMode == null || returnMode.isBlank()) {
                returnMode = "account";
            }
        }

        response.sendRedirect(buildRedirectTarget(
                request.getContextPath(),
                returnPage,
                request.getParameter("returnRecipeId"),
                request.getParameter("returnEditRecipeId"),
                returnMode,
                returnSection
        ));
    }

    private void redirectToAuthPage(HttpServletRequest request, HttpServletResponse response, String mode) throws IOException {
        StringBuilder target = new StringBuilder(request.getContextPath()).append("/auth");
        List<String> query = new ArrayList<>();
        appendQuery(query, "mode", mode);
        appendQuery(query, "returnPage", request.getParameter("returnPage"));
        appendQuery(query, "returnRecipeId", request.getParameter("returnRecipeId"));
        appendQuery(query, "returnEditRecipeId", request.getParameter("returnEditRecipeId"));
        appendQuery(query, "returnMode", request.getParameter("returnMode"));
        appendQuery(query, "returnSection", request.getParameter("returnSection"));

        if (!query.isEmpty()) {
            target.append('?').append(String.join("&", query));
        }

        response.sendRedirect(target.toString());
    }
}