package sushi;

public class PanierItem {
    private int produitId;
    private double quantite;
    private String unite;

    public PanierItem() {}

    public PanierItem(int produitId, double quantite, String unite) {
        this.produitId = produitId;
        this.quantite = quantite;
        this.unite = unite;
    }

    public int getProduitId() {
        return produitId;
    }

    public void setProduitId(int produitId) {
        this.produitId = produitId;
    }

    public double getQuantite() {
        return quantite;
    }

    public void setQuantite(double quantite) {
        this.quantite = quantite;
    }

    public String getUnite() {
        return unite;
    }

    public void setUnite(String unite) {
        this.unite = unite;
    }
}
