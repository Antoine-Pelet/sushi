import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import sushi.Recette;
import sushi.RecetteService;
import sushi.BD;

import java.io.IOException;

@WebServlet("/recette")
public class recette extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private final RecetteService recetteService = new RecetteService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String titre = request.getParameter("titre");
        String etapes = request.getParameter("etapes");

        String[] produitIds  = request.getParameterValues("produitId");
        String[] produitNoms = request.getParameterValues("produitNom");
        String[] quantites   = request.getParameterValues("quantite");
        String[] unites      = request.getParameterValues("unite");

        RecetteService.Resultat resultat = recetteService.construireRecette(
                titre, etapes, produitIds, produitNoms, quantites, unites
        );

        if (!resultat.isOk()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.setContentType("text/plain; charset=UTF-8");
            for (String e : resultat.getErreurs()) {
                response.getWriter().println("- " + e);
            }
            return;
        }

        Recette r = resultat.getRecette();

        
        String xmlPath = getServletContext().getRealPath("/donnee.xml");
        try {
            int newId = BD.ajouterRecette(r, xmlPath);
            r.setId(newId);
            request.setAttribute("xmlPath", xmlPath);
        } catch (Exception ex) {
            
            request.setAttribute("xmlPath", xmlPath);
            request.setAttribute("xmlError", ex.getMessage());
        }

        request.setAttribute("recette", r);
        request.getRequestDispatcher("/recetteResult.jsp").forward(request, response);

    }


    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("text/plain; charset=UTF-8");
        response.getWriter().println("Utilise POST /recette pour ajouter une recette dans donnee.xml.");
    }
}
