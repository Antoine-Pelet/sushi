package td8web;

import java.time.Instant;
import java.util.Date;
import java.util.HashMap;

public class Commande {
	int id;
	Date date;
	User user;
	Float price;
	HashMap<Recette, Integer> basket;
	
	public Commande(User user) {
		//this.id = id
		this.date = Date.from(Instant.now());
		this.user = user;
		this.basket = user.basket;
		user.deleteBasket();
		this.price = 0f;
		for (Recette r : basket.keySet()) {
			for (Ingredient i : r.quantities.keySet()) {
				this.price = this.price + basket.get(r) * r.quantities.get(i) * i.price;
			}
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
	
	public User getUser() {
		return user;
	}
	
	public Float getPrice() {
		return price;
	}
	
	public HashMap<Recette, Integer> getBasket() {
		return basket;
	}
}
