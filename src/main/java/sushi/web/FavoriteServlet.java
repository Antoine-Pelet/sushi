package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.SushiException;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@WebServlet("/favorites/toggle")
public class FavoriteServlet extends BaseServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String returnPage = request.getParameter("returnPage");
        String returnRecipeId = request.getParameter("returnRecipeId");

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

        if ("recipe".equals(returnPage) && returnRecipeId != null && !returnRecipeId.isBlank()) {
            response.sendRedirect(
                    request.getContextPath()
                            + "/recipe?id="
                            + URLEncoder.encode(returnRecipeId.trim(), StandardCharsets.UTF_8)
            );
            return;
        }

        redirectToApp(request, response);
    }
}
