package sushi;

import java.util.ArrayList;
import java.util.List;

public class Recette {
    private int id;
    private String titre;
    private String descriptionEtapes;
    private List<Ingredient> ingredients = new ArrayList<>();

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTitre() { return titre; }
    public void setTitre(String titre) { this.titre = titre; }

    public String getDescriptionEtapes() { return descriptionEtapes; }
    public void setDescriptionEtapes(String descriptionEtapes) { this.descriptionEtapes = descriptionEtapes; }

    public List<Ingredient> getIngredients() { return ingredients; }
    public void setIngredients(List<Ingredient> ingredients) { this.ingredients = ingredients; }
}

