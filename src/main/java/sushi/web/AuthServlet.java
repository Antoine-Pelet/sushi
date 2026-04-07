package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import sushi.SushiException;
import sushi.User;

import java.io.IOException;

@WebServlet(urlPatterns = {"/auth/login", "/auth/logout"})
public class AuthServlet extends BaseServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");

        try {
            if (request.getServletPath().endsWith("/login")) {
                handleLogin(request);
            } else {
                handleLogout(request);
            }
        } catch (IllegalArgumentException | SushiException exception) {
            setFlash(request, "error", exception.getMessage());
        }

        redirectToApp(request, response);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        redirectToApp(request, response);
    }

    private void handleLogin(HttpServletRequest request) {
        User user = service(request).login(request.getParameter("username"), request.getParameter("password"));
        HttpSession session = request.getSession(true);
        session.setAttribute("userId", user.getId());
        setFlash(request, "success", "Connexion reussie pour " + user.getUsername() + ".");
    }

    private void handleLogout(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
    }
}
