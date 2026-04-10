package sushi.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.SushiException;

import java.io.IOException;

@WebServlet("/admin/products/save")
public class AdminProductServlet extends BaseServlet {
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        request.setCharacterEncoding("UTF-8");

        try {
            Integer userId = currentUserId(request);
            if (userId == null) {
                throw new SushiException("Connexion requise.");
            }

            service(request).saveProduct(
                    userId,
                    optionalInt(request, "productId"),
                    request.getParameter("name"),
                    requiredDouble(request, "stock"),
                    request.getParameter("unit"),
                    requiredDouble(request, "price")
            );
            setFlash(request, "success", "Produit enregistré");
        } catch (IllegalArgumentException | SushiException exception) {
            setFlash(request, "error", exception.getMessage());
        }

        redirectToApp(request, response);
    }
}
