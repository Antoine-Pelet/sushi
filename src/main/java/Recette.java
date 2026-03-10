package td8web;

import java.util.HashMap;
import java.util.HashSet;

public class Recette {
	String name;
	String description;
	String recette;
	String image;
	HashMap<Ingredient, Float> quantities;
	static HashSet<Recette> listeRecette = new HashSet<>();
	
	public Recette(String name, String description, String recette, String image, HashMap<Ingredient, Float> quantities) {
		super();
		this.name = name;
		this.description = description;
		this.recette = recette;
		this.image = image;
		this.quantities = quantities;
		listeRecette.add(this);
	}
	
	public static HashSet<Recette> getListeRecette() {
		return listeRecette;
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
	public String getRecette() {
		return recette;
	}
	public void setRecette(String recette) {
		this.recette = recette;
	}	
	public String getImage() {
		return image;
	}
	public void setImage(String image) {
		this.image = image;
	}
	public HashMap<Ingredient, Float> getQuantities() {
		return quantities;
	}
	public void setQuantities(HashMap<Ingredient, Float> quantities) {
		this.quantities = quantities;
	}
}
