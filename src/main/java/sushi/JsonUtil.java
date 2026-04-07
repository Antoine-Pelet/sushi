package sushi;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.StringJoiner;
import java.util.stream.Collectors;

public final class JsonUtil {
    private JsonUtil() {
    }

    public static String success(String message) {
        return success(message, null);
    }

    public static String success(String message, String dataJson) {
        StringBuilder builder = new StringBuilder();
        builder.append("{\"ok\":true");
        if (message != null) {
            builder.append(",\"message\":").append(quote(message));
        }
        if (dataJson != null) {
            builder.append(",\"data\":").append(dataJson);
        }
        builder.append("}");
        return builder.toString();
    }

    public static String error(String message) {
        return "{\"ok\":false,\"message\":" + quote(message) + "}";
    }

    public static String recipes(List<Recette> recettes, Map<Integer, Integer> availability, Set<Integer> favoriteIds) {
        StringJoiner joiner = new StringJoiner(",", "[", "]");
        for (Recette recette : recettes) {
            joiner.add(recipe(recette, availability.getOrDefault(recette.getId(), 0), favoriteIds.contains(recette.getId())));
        }
        return joiner.toString();
    }

    public static String recipe(Recette recette, int available, boolean favorite) {
        StringJoiner ingredients = new StringJoiner(",", "[", "]");
        for (Ingredient ingredient : recette.getIngredients()) {
            ingredients.add("{"
                    + "\"productId\":" + ingredient.getProduit().getId()
                    + ",\"productName\":" + quote(ingredient.getProduit().getNom())
                    + ",\"quantity\":" + number(ingredient.getQuantite())
                    + ",\"unit\":" + quote(ingredient.getUnite())
                    + "}");
        }

        return "{"
                + "\"id\":" + recette.getId()
                + ",\"title\":" + quote(recette.getTitre())
                + ",\"description\":" + quote(recette.getDescriptionEtapes())
                + ",\"price\":" + number(recette.getPrix())
                + ",\"available\":" + available
                + ",\"favorite\":" + favorite
                + ",\"ingredients\":" + ingredients
                + "}";
    }

    public static String products(List<Produit> produits) {
        StringJoiner joiner = new StringJoiner(",", "[", "]");
        for (Produit produit : produits) {
            joiner.add("{"
                    + "\"id\":" + produit.getId()
                    + ",\"name\":" + quote(produit.getNom())
                    + ",\"stock\":" + number(produit.getStock())
                    + ",\"unit\":" + quote(produit.getUnite())
                    + ",\"unitPrice\":" + number(produit.getPrixUnitaire())
                    + "}");
        }
        return joiner.toString();
    }

    public static String user(User user, Map<Integer, Recette> recipesById) {
        String favorites = user.getFavoris().stream()
                .map(String::valueOf)
                .collect(Collectors.joining(",", "[", "]"));

        StringJoiner cart = new StringJoiner(",", "[", "]");
        for (PanierItem item : user.getPanier()) {
            Recette recette = recipesById.get(item.getRecetteId());
            cart.add("{"
                    + "\"recipeId\":" + item.getRecetteId()
                    + ",\"title\":" + quote(recette == null ? "" : recette.getTitre())
                    + ",\"quantity\":" + item.getQuantite()
                    + ",\"unitPrice\":" + number(recette == null ? 0D : recette.getPrix())
                    + "}");
        }

        return "{"
                + "\"id\":" + user.getId()
                + ",\"username\":" + quote(user.getUsername())
                + ",\"admin\":" + user.isAdmin()
                + ",\"favorites\":" + favorites
                + ",\"cart\":" + cart
                + "}";
    }

    public static String orders(List<Commande> commandes) {
        StringJoiner joiner = new StringJoiner(",", "[", "]");
        for (Commande commande : commandes) {
            StringJoiner items = new StringJoiner(",", "[", "]");
            for (CommandeItem item : commande.getItems()) {
                items.add("{"
                        + "\"recipeId\":" + item.getRecetteId()
                        + ",\"title\":" + quote(item.getRecetteTitre())
                        + ",\"quantity\":" + item.getQuantite()
                        + ",\"unitPrice\":" + number(item.getPrixUnitaire())
                        + ",\"subtotal\":" + number(item.getSousTotal())
                        + "}");
            }

            joiner.add("{"
                    + "\"id\":" + commande.getId()
                    + ",\"userId\":" + commande.getUserId()
                    + ",\"username\":" + quote(commande.getUsername())
                    + ",\"createdAt\":" + quote(commande.getDateCreation())
                    + ",\"total\":" + number(commande.getTotal())
                    + ",\"items\":" + items
                    + "}");
        }
        return joiner.toString();
    }

    public static String quote(String value) {
        if (value == null) {
            return "null";
        }

        StringBuilder builder = new StringBuilder("\"");
        for (int i = 0; i < value.length(); i++) {
            char current = value.charAt(i);
            switch (current) {
                case '\\' -> builder.append("\\\\");
                case '"' -> builder.append("\\\"");
                case '\n' -> builder.append("\\n");
                case '\r' -> builder.append("\\r");
                case '\t' -> builder.append("\\t");
                default -> {
                    if (current < 32) {
                        builder.append(String.format("\\u%04x", (int) current));
                    } else {
                        builder.append(current);
                    }
                }
            }
        }
        builder.append('"');
        return builder.toString();
    }

    private static String number(double value) {
        return BigDecimal.valueOf(value).stripTrailingZeros().toPlainString();
    }
}
