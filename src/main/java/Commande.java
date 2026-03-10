package td8web;

import java.util.Date;
import java.util.HashMap;

public class Commande {
	int id;
	Date date;
	User user;
	Float price;
	HashMap<Recette, Integer> panier;
	
	public Commande(User user) {
		//this.id = id
		//this.date = date;
		this.user = user;
		this.price = 0f;
		this.panier = user.panier;
		user.panier = null; //TODO
		for (Recette r : user.panier.keySet()) {
			//for (Ingredient i : r.quantities) {
				//this.price
			//}
		}
		
	}
	public int getId() {
		return id;
	}
	public Date getDate() {
		return date;
	}
	public void setDate(Date date) {
		this.date = date;
	}
	
}
