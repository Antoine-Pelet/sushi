package sushi;

public class CommandeItem {
    private int recetteId;
    private String recetteTitre;
    private int quantite;
    private double prixUnitaire;

    public int getRecetteId() {
        return recetteId;
    }

    public void setRecetteId(int recetteId) {
        this.recetteId = recetteId;
    }

    public String getRecetteTitre() {
        return recetteTitre;
    }

    public void setRecetteTitre(String recetteTitre) {
        this.recetteTitre = recetteTitre;
    }

    public int getQuantite() {
        return quantite;
    }

    public void setQuantite(int quantite) {
        this.quantite = quantite;
    }

    public double getPrixUnitaire() {
        return prixUnitaire;
    }

    public void setPrixUnitaire(double prixUnitaire) {
        this.prixUnitaire = prixUnitaire;
    }

    public double getSousTotal() {
        return prixUnitaire * quantite;
    }
}
