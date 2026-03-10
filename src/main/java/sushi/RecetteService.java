package sushi;

import java.util.ArrayList;
import java.util.List;

public class RecetteService {

    public static class Resultat {
        private final Recette recette;
        private final List<String> erreurs;

        public Resultat(Recette recette, List<String> erreurs) {
            this.recette = recette;
            this.erreurs = erreurs;
        }

        public Recette getRecette() { return recette; }
        public List<String> getErreurs() { return erreurs; }
        public boolean isOk() { return erreurs == null || erreurs.isEmpty(); }
    }

    public Resultat construireRecette(String titre,
                                     String etapes,
                                     String[] produitIds,
                                     String[] produitNoms,
                                     String[] quantites,
                                     String[] unites) {

        List<String> erreurs = new ArrayList<>();

        if (titre == null || titre.trim().isEmpty()) erreurs.add("Titre obligatoire.");
        if (etapes == null || etapes.trim().isEmpty()) erreurs.add("Étapes/description obligatoire.");

        if (produitIds == null || quantites == null || produitIds.length == 0) {
            erreurs.add("Au moins un ingrédient est requis.");
        } else {
            if (produitNoms != null && produitNoms.length != produitIds.length)
                erreurs.add("Ingrédients invalides : produitNom n'a pas la bonne taille.");
            if (unites != null && unites.length != produitIds.length)
                erreurs.add("Ingrédients invalides : unite n'a pas la bonne taille.");
        }

        // Si erreurs  on s’arrête
        if (!erreurs.isEmpty()) {
            return new Resultat(null, erreurs);
        }

        Recette r = new Recette();
        r.setTitre(titre.trim());
        r.setDescriptionEtapes(etapes.trim());

        for (int i = 0; i < produitIds.length; i++) {
            String pidStr = produitIds[i];
            String qteStr = quantites[i];

            if (pidStr == null || pidStr.trim().isEmpty()) continue;
            if (qteStr == null || qteStr.trim().isEmpty()) continue;

            int pid;
            double qte;

            try {
                pid = Integer.parseInt(pidStr.trim());
            } catch (NumberFormatException ex) {
                continue;
            }

            try {
                qte = Double.parseDouble(qteStr.trim().replace(',', '.'));
            } catch (NumberFormatException ex) {
                continue;
            }

            String nom = (produitNoms != null && produitNoms[i] != null) ? produitNoms[i].trim() : null;
            String unite = (unites != null && unites[i] != null) ? unites[i].trim() : null;

            Produit p = new Produit();
            p.setId(pid);
            if (nom != null && !nom.isEmpty()) p.setNom(nom);

            Ingredient ing = new Ingredient();
            ing.setProduit(p);
            ing.setQuantite(qte);
            ing.setUnite(unite);

            r.getIngredients().add(ing);
        }

        if (r.getIngredients().isEmpty()) {
            erreurs.add("Aucun ingrédient valide (ids/quantités incorrects).");
            return new Resultat(null, erreurs);
        }

        return new Resultat(r, erreurs);
    }
}
