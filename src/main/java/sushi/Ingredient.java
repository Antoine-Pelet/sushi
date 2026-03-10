package sushi;

public class Ingredient {
    private Produit produit;
    private double quantite;
    private String unite;

    public Ingredient() {}

    public Ingredient(Produit produit, double quantite, String unite) {
        this.produit = produit;
        this.quantite = quantite;
        this.unite = unite;
    }

    public Produit getProduit() { return produit; }
    public void setProduit(Produit produit) { this.produit = produit; }

    public double getQuantite() { return quantite; }
    public void setQuantite(double quantite) { this.quantite = quantite; }

    public String getUnite() { return unite; }
    public void setUnite(String unite) { this.unite = unite; }
}
