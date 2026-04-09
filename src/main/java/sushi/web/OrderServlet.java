package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.SushiException;

import java.io.IOException;

@WebServlet("/orders/checkout")
public class OrderServlet extends BaseServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            Integer userId = currentUserId(request);
            if (userId == null) {
                throw new SushiException("Connexion requise.");
            }
            ensureAdminSiteAccessDenied(request);
            service(request).checkout(userId);
            setFlash(request, "success", "Commande validee et stock mis a jour.");
        } catch (SushiException exception) {
            setFlash(request, "error", exception.getMessage());
        }

        redirectToApp(request, response);
    }
}
