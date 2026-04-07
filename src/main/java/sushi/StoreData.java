package sushi;

import java.util.ArrayList;
import java.util.List;

public class StoreData {
    private int nextUserId;
    private int nextProduitId;
    private int nextRecetteId;
    private int nextCommandeId;
    private List<User> users = new ArrayList<>();
    private List<Produit> produits = new ArrayList<>();
    private List<Recette> recettes = new ArrayList<>();
    private List<Commande> commandes = new ArrayList<>();

    public int getNextUserId() {
        return nextUserId;
    }

    public void setNextUserId(int nextUserId) {
        this.nextUserId = nextUserId;
    }

    public int getNextProduitId() {
        return nextProduitId;
    }

    public void setNextProduitId(int nextProduitId) {
        this.nextProduitId = nextProduitId;
    }

    public int getNextRecetteId() {
        return nextRecetteId;
    }

    public void setNextRecetteId(int nextRecetteId) {
        this.nextRecetteId = nextRecetteId;
    }

    public int getNextCommandeId() {
        return nextCommandeId;
    }

    public void setNextCommandeId(int nextCommandeId) {
        this.nextCommandeId = nextCommandeId;
    }

    public List<User> getUsers() {
        return users;
    }

    public void setUsers(List<User> users) {
        this.users = users;
    }

    public List<Produit> getProduits() {
        return produits;
    }

    public void setProduits(List<Produit> produits) {
        this.produits = produits;
    }

    public List<Recette> getRecettes() {
        return recettes;
    }

    public void setRecettes(List<Recette> recettes) {
        this.recettes = recettes;
    }

    public List<Commande> getCommandes() {
        return commandes;
    }

    public void setCommandes(List<Commande> commandes) {
        this.commandes = commandes;
    }
}
