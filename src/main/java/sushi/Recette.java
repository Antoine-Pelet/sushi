package sushi;

import java.util.ArrayList;
import java.util.List;

public class Recette {
    private int id;
    private String titre;
    private String descriptionEtapes;
    private String imageCouverture;
    private String imageSushef;
    private double prix;
    private int tempsPreparationMinutes;
    private int difficulte;
    private boolean necessiteRizVinaigre = true;
    private List<Ingredient> ingredients = new ArrayList<>();
    private List<EtapeRecette> etapes = new ArrayList<>();

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }

    public String getDescriptionEtapes() { return descriptionEtapes; }
    public void setDescriptionEtapes(String descriptionEtapes) { this.descriptionEtapes = descriptionEtapes; }

    public String getImageCouverture() { return imageCouverture; }
    public void setImageCouverture(String imageCouverture) { this.imageCouverture = imageCouverture; }

    public String getImageSushef() { return imageSushef; }
    public void setImageSushef(String imageSushef) { this.imageSushef = imageSushef; }

    public double getPrix() { return prix; }
    public void setPrix(double prix) { this.prix = prix; }

    public int getTempsPreparationMinutes() { return tempsPreparationMinutes; }
    public void setTempsPreparationMinutes(int tempsPreparationMinutes) { this.tempsPreparationMinutes = tempsPreparationMinutes; }

    public int getDifficulte() { return difficulte; }
    public void setDifficulte(int difficulte) { this.difficulte = difficulte; }

    public boolean isNecessiteRizVinaigre() { return necessiteRizVinaigre; }
    public void setNecessiteRizVinaigre(boolean necessiteRizVinaigre) { this.necessiteRizVinaigre = necessiteRizVinaigre; }

    public List<Ingredient> getIngredients() { return ingredients; }
    public void setIngredients(List<Ingredient> ingredients) { this.ingredients = ingredients; }

    public List<EtapeRecette> getEtapes() { return etapes; }
    public void setEtapes(List<EtapeRecette> etapes) { this.etapes = etapes; }
}
