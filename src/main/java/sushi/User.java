package sushi;

import java.util.ArrayList;
import java.util.List;

public class User {
    private int id;
    private String username;
    private String passwordHash;
    private boolean admin;
    private List<Integer> favoris = new ArrayList<>();
    private List<PanierItem> panier = new ArrayList<>();

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public boolean isAdmin() {
        return admin;
    }

    public void setAdmin(boolean admin) {
        this.admin = admin;
    }

    public List<Integer> getFavoris() {
        return favoris;
    }

    public void setFavoris(List<Integer> favoris) {
        this.favoris = favoris;
    }

    public List<PanierItem> getPanier() {
        return panier;
    }

    public void setPanier(List<PanierItem> panier) {
        this.panier = panier;
    }

    public boolean hasFavori(int recetteId) {
        return favoris.contains(recetteId);
    }
}
