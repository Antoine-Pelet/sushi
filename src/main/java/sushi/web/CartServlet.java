package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.SushiException;

import java.io.IOException;

@WebServlet(urlPatterns = {"/cart/add", "/cart/remove", "/cart/clear"})
public class CartServlet extends BaseServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            Integer userId = currentUserId(request);
            if (userId == null) {
                throw new SushiException("Connexion requise.");
            }

            if (request.getServletPath().endsWith("/add")) {
                int recipeId = requiredInt(request, "recipeId");
                int quantity = optionalInt(request, "quantity", 1);
                service(request).addToCart(userId, recipeId, quantity);
                setFlash(request, "success", "Recette ajoutee au panier.");
            } else if (request.getServletPath().endsWith("/clear")) {
                service(request).clearCart(userId);
                setFlash(request, "success", "Panier vide.");
            } else {
                int recipeId = requiredInt(request, "recipeId");
                int quantity = optionalInt(request, "quantity", 1);
                service(request).removeFromCart(userId, recipeId, quantity);
                setFlash(request, "success", "Panier mis a jour.");
            }
        } catch (IllegalArgumentException | SushiException exception) {
            setFlash(request, "error", exception.getMessage());
        }

        redirectToApp(request, response);
    }
}
