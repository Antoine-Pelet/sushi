package sushi;

import java.util.ArrayList;
import java.util.List;

public class Commande {
    private int id;
    private int userId;
    private String username;
    private String dateCreation;
    private double total;
    private List<CommandeItem> items = new ArrayList<>();

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getDateCreation() {
        return dateCreation;
    }

    public void setDateCreation(String dateCreation) {
        this.dateCreation = dateCreation;
    }

    public double getTotal() {
        return total;
    }

    public void setTotal(double total) {
        this.total = total;
    }

    public List<CommandeItem> getItems() {
        return items;
    }

    public void setItems(List<CommandeItem> items) {
        this.items = items;
    }
}
