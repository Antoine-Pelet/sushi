package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.SushiException;

import java.io.IOException;

@WebServlet("/favorites/toggle")
public class FavoriteServlet extends BaseServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            Integer userId = currentUserId(request);
            if (userId == null) {
                throw new SushiException("Connexion requise.");
            }
            service(request).toggleFavorite(userId, requiredInt(request, "recipeId"));
            setFlash(request, "success", "Favoris mis a jour.");
        } catch (IllegalArgumentException | SushiException exception) {
            setFlash(request, "error", exception.getMessage());
        }

        redirectToApp(request, response);
    }
}
