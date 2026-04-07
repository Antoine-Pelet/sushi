package sushi;

public class PanierItem {
    private int recetteId;
    private int quantite;

    public PanierItem() {}

    public PanierItem(int recetteId, int quantite) {
        this.recetteId = recetteId;
        this.quantite = quantite;
    }

    public int getRecetteId() {
        return recetteId;
    }

    public void setRecetteId(int recetteId) {
        this.recetteId = recetteId;
    }

    public int getQuantite() {
        return quantite;
    }

    public void setQuantite(int quantite) {
        this.quantite = quantite;
    }
}
