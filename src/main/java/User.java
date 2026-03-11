package td8web;

import java.util.HashMap;
import java.util.HashSet;

public class User {
	String name;
	String password;
	boolean admin;
	String avatar;
	HashSet<Recette> favorite;
	HashMap<Recette, Integer> basket;
	HashSet<Commande> history;
	
	public User(String name, String password) {
		this.name = name;
		this.password = password;
		this.admin = false;
		this.favorite = new HashSet<>();
		this.basket = new HashMap<>();
		this.history = new HashSet<>();
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public boolean isAdmin() {
		return admin;
	}

	public void setAdmin(boolean admin) {
		this.admin = admin;
	}

	public String getAvatar() {
		return avatar;
	}

	public void setAvatar(String avatar) {
		this.avatar = avatar;
	}

	public HashSet<Recette> getFavorite() {
		return favorite;
	}

	public void addFavorite(Recette recipe) {
		this.favorite.add(recipe);
	}
	
	public void removeFavorite(Recette recipe) {
		this.favorite.remove(recipe);
	}
	
	public void addBasket(Recette recipe, int quantity) {
		boolean ok = true;
		for (Ingredient i : recipe.quantities.keySet()) {
			if (recipe.quantities.get(i) < i.stock) {
				ok = false;
				break;
			}
		}
		if (ok) {
			this.basket.putIfAbsent(recipe, 0);
			this.basket.put(recipe, this.basket.get(recipe) + quantity);			
		} else {
			System.out.println("Stock insuffisant");
		}
	}
	
	public void removeBasket(Recette recipe, int quantity) {
		this.basket.put(recipe, this.basket.get(recipe) - quantity);
		if (this.basket.get(recipe) <= 0) this.basket.remove(recipe);
	}
	
	public void deleteBasket() {
		this.basket = null;
	}
	
	public HashSet<Commande> getHistory() {
		return history;
	}
	
	public void buy() {
		history.add(new Commande(this));
	}
}
