package td8web;

import java.util.HashSet;

public class Ingredient {
	String name;
	int stock;
	String unit;
	Float price;
	static HashSet<Ingredient> ingredientList = new HashSet<>();
	
	public Ingredient (String name, String unit, Float price) {
		this.name = name;
		this.stock = 0;
		this.unit = unit;
		this.price = price;
		ingredientList.add(this);
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}
	
	public int getStock() {
		return stock;
	}

	public void setStock(int stock) {
		this.stock = stock;
	}
	
	public void addStock(int stock) {
		this.stock = this.stock + stock;
	}

	public String getUnit() {
		return unit;
	}

	public void setUnit(String unit) {
		this.unit = unit;
	}

	public Float getPrice() {
		return price;
	}

	public void setPrice(Float price) {
		this.price = price;
	}

	public static HashSet<Ingredient> getIngredientList() {
		return ingredientList;
	}
}
