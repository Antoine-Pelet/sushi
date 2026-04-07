package sushi;

public class Produit {
    private int id;
    private String nom;
    private double stock;
    private String unite;
    private double prixUnitaire;

    public Produit() {}
    public Produit(int id, String nom) {
        this.id = id;
        this.nom = nom;
    }

    public Produit(int id, String nom, double stock, String unite, double prixUnitaire) {
        this.id = id;
        this.nom = nom;
        this.stock = stock;
        this.unite = unite;
        this.prixUnitaire = prixUnitaire;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public double getStock() { return stock; }
    public void setStock(double stock) { this.stock = stock; }

    public String getUnite() { return unite; }
    public void setUnite(String unite) { this.unite = unite; }

    public double getPrixUnitaire() { return prixUnitaire; }
    public void setPrixUnitaire(double prixUnitaire) { this.prixUnitaire = prixUnitaire; }
}
