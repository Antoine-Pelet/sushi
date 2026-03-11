package td8web;

import java.util.HashMap;
import java.util.HashSet;

public class Recette {
	String name;
	String description;
	String steps;
	String image;
	HashMap<Ingredient, Integer> quantities;
	static HashSet<Recette> recipeList = new HashSet<>();
	
	public Recette(String name, String description, String steps, String image, HashMap<Ingredient, Integer> quantities) {
		super();
		this.name = name;
		this.description = description;
		this.steps = steps;
		this.image = image;
		this.quantities = quantities;
		recipeList.add(this);
	}

	public String getName() {
		return name;
	}
	
	public void setName(String name) {
		this.name = name;
	}
	
	public String getDescription() {
		return description;
	}
	
	public void setDescription(String description) {
		this.description = description;
	}
	
	public String getSteps() {
		return steps;
	}
	
	public void setRecipe(String steps) {
		this.steps = steps;
	}
	
	public String getImage() {
		return image;
	}
	
	public void setImage(String image) {
		this.image = image;
	}
	
	public HashMap<Ingredient, Integer> getQuantities() {
		return quantities;
	}
	
	public void setQuantities(HashMap<Ingredient, Integer> quantities) {
		this.quantities = quantities;
	}
	
	public void addIngredient(Ingredient ingredient, int quantity) {
		this.quantities.put(ingredient, quantity);
	}
	
	public void removeIngredient(Ingredient ingredient) {
		this.quantities.remove(ingredient);
	}
	
	public static HashSet<Recette> getListeRecette() {
		return recipeList;
	}
}
