package td8web;

import java.util.HashMap;
import java.util.HashSet;

public class User {
	String name;
	String password;
	boolean admin;
	String avatar;
	HashSet<Recette> favoris;
	HashMap<Recette, Integer> panier;
	
	
	public User(String name, String password) {
		this.name = name;
		this.password = password;
		this.admin = false;
		this.favoris = new HashSet<>();
		this.panier = new HashMap<>();
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

	public HashSet<Recette> getFavoris() {
		return favoris;
	}

	public void addFavoris(Recette recette) {
		this.favoris.add(recette);
	}
	
	public void removeFavoris(Recette recette) {
		this.favoris.remove(recette);
	}
	
	public void addPanier(Recette recette, int quantity) {
		//Vérification qu'on a le stocks
		this.panier.putIfAbsent(recette, 0);
		this.panier.put(recette, this.panier.get(recette) + quantity);
	}
	
	public void removePanier(Recette recette, int quantity) {
		//TODO
	}
}
