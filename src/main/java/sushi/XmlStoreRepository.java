package sushi;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class XmlStoreRepository {
    private final Path storePath;

    public XmlStoreRepository(Path storePath) {
        this.storePath = storePath;
    }

    public Path getStorePath() {
        return storePath;
    }

    public void ensureInitialized() {
        try {
            if (Files.exists(storePath)) {
                return;
            }
            Path parent = storePath.getParent();
            if (parent != null) {
                Files.createDirectories(parent);
            }
            save(createDefaultStore());
        } catch (Exception exception) {
            throw new IllegalStateException("Impossible d'initialiser le stockage XML", exception);
        }
    }

    public StoreData load() {
        ensureInitialized();
        try (InputStream inputStream = Files.newInputStream(storePath)) {
            Document document = newDocumentBuilder().parse(inputStream);
            document.getDocumentElement().normalize();

            StoreData data = new StoreData();
            Element root = document.getDocumentElement();

            Element usersElement = firstChild(root, "users");
            data.setNextUserId(attrInt(usersElement, "nextId", 1));
            data.setUsers(parseUsers(usersElement));

            Element productsElement = firstChild(root, "products");
            data.setNextProduitId(attrInt(productsElement, "nextId", 1));
            data.setProduits(parseProducts(productsElement));

            Map<Integer, Produit> productsById = new HashMap<>();
            for (Produit produit : data.getProduits()) {
                productsById.put(produit.getId(), produit);
            }

            Element recipesElement = firstChild(root, "recipes");
            data.setNextRecetteId(attrInt(recipesElement, "nextId", 1));
            data.setRecettes(parseRecipes(recipesElement, productsById));

            Element ordersElement = firstChild(root, "orders");
            data.setNextCommandeId(attrInt(ordersElement, "nextId", 1));
            data.setCommandes(parseOrders(ordersElement));

            return data;
        } catch (Exception exception) {
            throw new IllegalStateException("Impossible de lire le stockage XML", exception);
        }
    }

    public void save(StoreData data) {
        try {
            Path parent = storePath.getParent();
            if (parent != null) {
                Files.createDirectories(parent);
            }

            Document document = newDocumentBuilder().newDocument();
            Element root = document.createElement("store");
            document.appendChild(root);

            writeUsers(document, root, data);
            writeProducts(document, root, data);
            writeRecipes(document, root, data);
            writeOrders(document, root, data);

            TransformerFactory transformerFactory = TransformerFactory.newInstance();
            Transformer transformer = transformerFactory.newTransformer();
            transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
            transformer.setOutputProperty(OutputKeys.INDENT, "yes");
            try {
                transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2");
            } catch (Exception ignored) {
            }

            try (OutputStream outputStream = Files.newOutputStream(storePath)) {
                transformer.transform(new DOMSource(document), new StreamResult(outputStream));
            }
        } catch (Exception exception) {
            throw new IllegalStateException("Impossible d'enregistrer le stockage XML", exception);
        }
    }

    private List<User> parseUsers(Element usersElement) {
        List<User> users = new ArrayList<>();
        if (usersElement == null) {
            return users;
        }

        NodeList nodes = usersElement.getElementsByTagName("user");
        for (int index = 0; index < nodes.getLength(); index++) {
            Node current = nodes.item(index);
            if (!(current instanceof Element userElement)) {
                continue;
            }

            User user = new User();
            user.setId(attrInt(userElement, "id", 0));
            user.setUsername(userElement.getAttribute("username"));
            user.setPasswordHash(userElement.getAttribute("passwordHash"));
            user.setAdmin(Boolean.parseBoolean(userElement.getAttribute("admin")));

            List<Integer> favoris = new ArrayList<>();
            Element favoritesElement = firstChild(userElement, "favorites");
            if (favoritesElement != null) {
                NodeList refs = favoritesElement.getElementsByTagName("recipeRef");
                for (int i = 0; i < refs.getLength(); i++) {
                    if (refs.item(i) instanceof Element refElement) {
                        favoris.add(attrInt(refElement, "id", 0));
                    }
                }
            }
            user.setFavoris(favoris);

            List<PanierItem> panier = new ArrayList<>();
            Element cartElement = firstChild(userElement, "cart");
            if (cartElement != null) {
                NodeList items = cartElement.getElementsByTagName("item");
                for (int i = 0; i < items.getLength(); i++) {
                    if (items.item(i) instanceof Element itemElement) {
                        panier.add(new PanierItem(
                                attrInt(itemElement, "recipeId", 0),
                                attrInt(itemElement, "quantity", 0)
                        ));
                    }
                }
            }
            user.setPanier(panier);
            users.add(user);
        }
        return users;
    }

    private List<Produit> parseProducts(Element productsElement) {
        List<Produit> products = new ArrayList<>();
        if (productsElement == null) {
            return products;
        }

        NodeList nodes = productsElement.getElementsByTagName("product");
        for (int index = 0; index < nodes.getLength(); index++) {
            Node current = nodes.item(index);
            if (!(current instanceof Element productElement)) {
                continue;
            }

            Produit produit = new Produit();
            produit.setId(attrInt(productElement, "id", 0));
            produit.setNom(productElement.getAttribute("name"));
            produit.setStock(attrDouble(productElement, "stock", 0D));
            produit.setUnite(productElement.getAttribute("unit"));
            produit.setPrixUnitaire(attrDouble(productElement, "price", 0D));
            products.add(produit);
        }
        return products;
    }

    private List<Recette> parseRecipes(Element recipesElement, Map<Integer, Produit> productsById) {
        List<Recette> recipes = new ArrayList<>();
        if (recipesElement == null) {
            return recipes;
        }

        NodeList nodes = recipesElement.getElementsByTagName("recipe");
        for (int index = 0; index < nodes.getLength(); index++) {
            Node current = nodes.item(index);
            if (!(current instanceof Element recipeElement)) {
                continue;
            }

            Recette recette = new Recette();
            recette.setId(attrInt(recipeElement, "id", 0));
            recette.setPrix(attrDouble(recipeElement, "price", 0D));
            recette.setTitre(textOf(firstChild(recipeElement, "title")));
            recette.setDescriptionEtapes(textOf(firstChild(recipeElement, "description")));

            List<Ingredient> ingredients = new ArrayList<>();
            Element ingredientsElement = firstChild(recipeElement, "ingredients");
            if (ingredientsElement != null) {
                NodeList ingredientNodes = ingredientsElement.getElementsByTagName("ingredient");
                for (int i = 0; i < ingredientNodes.getLength(); i++) {
                    if (!(ingredientNodes.item(i) instanceof Element ingredientElement)) {
                        continue;
                    }

                    int productId = attrInt(ingredientElement, "productId", 0);
                    Produit product = productsById.get(productId);
                    if (product == null) {
                        continue;
                    }

                    Ingredient ingredient = new Ingredient();
                    ingredient.setProduit(product);
                    ingredient.setQuantite(attrDouble(ingredientElement, "quantity", 0D));
                    ingredient.setUnite(ingredientElement.getAttribute("unit"));
                    ingredients.add(ingredient);
                }
            }
            recette.setIngredients(ingredients);
            recipes.add(recette);
        }
        return recipes;
    }

    private List<Commande> parseOrders(Element ordersElement) {
        List<Commande> orders = new ArrayList<>();
        if (ordersElement == null) {
            return orders;
        }

        NodeList nodes = ordersElement.getElementsByTagName("order");
        for (int index = 0; index < nodes.getLength(); index++) {
            Node current = nodes.item(index);
            if (!(current instanceof Element orderElement)) {
                continue;
            }

            Commande commande = new Commande();
            commande.setId(attrInt(orderElement, "id", 0));
            commande.setUserId(attrInt(orderElement, "userId", 0));
            commande.setUsername(orderElement.getAttribute("username"));
            commande.setDateCreation(orderElement.getAttribute("createdAt"));
            commande.setTotal(attrDouble(orderElement, "total", 0D));

            List<CommandeItem> items = new ArrayList<>();
            NodeList itemNodes = orderElement.getElementsByTagName("item");
            for (int i = 0; i < itemNodes.getLength(); i++) {
                if (!(itemNodes.item(i) instanceof Element itemElement)) {
                    continue;
                }
                CommandeItem item = new CommandeItem();
                item.setRecetteId(attrInt(itemElement, "recipeId", 0));
                item.setRecetteTitre(itemElement.getAttribute("recipeTitle"));
                item.setQuantite(attrInt(itemElement, "quantity", 0));
                item.setPrixUnitaire(attrDouble(itemElement, "unitPrice", 0D));
                items.add(item);
            }

            commande.setItems(items);
            orders.add(commande);
        }
        return orders;
    }

    private void writeUsers(Document document, Element root, StoreData data) {
        Element usersElement = document.createElement("users");
        usersElement.setAttribute("nextId", Integer.toString(data.getNextUserId()));
        root.appendChild(usersElement);

        for (User user : data.getUsers()) {
            Element userElement = document.createElement("user");
            userElement.setAttribute("id", Integer.toString(user.getId()));
            userElement.setAttribute("username", safe(user.getUsername()));
            userElement.setAttribute("passwordHash", safe(user.getPasswordHash()));
            userElement.setAttribute("admin", Boolean.toString(user.isAdmin()));
            usersElement.appendChild(userElement);

            Element favoritesElement = document.createElement("favorites");
            for (Integer favoriteId : user.getFavoris()) {
                Element favoriteElement = document.createElement("recipeRef");
                favoriteElement.setAttribute("id", Integer.toString(favoriteId));
                favoritesElement.appendChild(favoriteElement);
            }
            userElement.appendChild(favoritesElement);

            Element cartElement = document.createElement("cart");
            for (PanierItem item : user.getPanier()) {
                Element itemElement = document.createElement("item");
                itemElement.setAttribute("recipeId", Integer.toString(item.getRecetteId()));
                itemElement.setAttribute("quantity", Integer.toString(item.getQuantite()));
                cartElement.appendChild(itemElement);
            }
            userElement.appendChild(cartElement);
        }
    }

    private void writeProducts(Document document, Element root, StoreData data) {
        Element productsElement = document.createElement("products");
        productsElement.setAttribute("nextId", Integer.toString(data.getNextProduitId()));
        root.appendChild(productsElement);

        for (Produit produit : data.getProduits()) {
            Element productElement = document.createElement("product");
            productElement.setAttribute("id", Integer.toString(produit.getId()));
            productElement.setAttribute("name", safe(produit.getNom()));
            productElement.setAttribute("stock", number(produit.getStock()));
            productElement.setAttribute("unit", safe(produit.getUnite()));
            productElement.setAttribute("price", number(produit.getPrixUnitaire()));
            productsElement.appendChild(productElement);
        }
    }

    private void writeRecipes(Document document, Element root, StoreData data) {
        Element recipesElement = document.createElement("recipes");
        recipesElement.setAttribute("nextId", Integer.toString(data.getNextRecetteId()));
        root.appendChild(recipesElement);

        for (Recette recette : data.getRecettes()) {
            Element recipeElement = document.createElement("recipe");
            recipeElement.setAttribute("id", Integer.toString(recette.getId()));
            recipeElement.setAttribute("price", number(recette.getPrix()));
            recipesElement.appendChild(recipeElement);

            appendText(document, recipeElement, "title", recette.getTitre());
            appendText(document, recipeElement, "description", recette.getDescriptionEtapes());

            Element ingredientsElement = document.createElement("ingredients");
            recipeElement.appendChild(ingredientsElement);
            for (Ingredient ingredient : recette.getIngredients()) {
                if (ingredient.getProduit() == null) {
                    continue;
                }
                Element ingredientElement = document.createElement("ingredient");
                ingredientElement.setAttribute("productId", Integer.toString(ingredient.getProduit().getId()));
                ingredientElement.setAttribute("quantity", number(ingredient.getQuantite()));
                ingredientElement.setAttribute("unit", safe(ingredient.getUnite()));
                ingredientsElement.appendChild(ingredientElement);
            }
        }
    }

    private void writeOrders(Document document, Element root, StoreData data) {
        Element ordersElement = document.createElement("orders");
        ordersElement.setAttribute("nextId", Integer.toString(data.getNextCommandeId()));
        root.appendChild(ordersElement);

        for (Commande commande : data.getCommandes()) {
            Element orderElement = document.createElement("order");
            orderElement.setAttribute("id", Integer.toString(commande.getId()));
            orderElement.setAttribute("userId", Integer.toString(commande.getUserId()));
            orderElement.setAttribute("username", safe(commande.getUsername()));
            orderElement.setAttribute("createdAt", safe(commande.getDateCreation()));
            orderElement.setAttribute("total", number(commande.getTotal()));
            ordersElement.appendChild(orderElement);

            for (CommandeItem item : commande.getItems()) {
                Element itemElement = document.createElement("item");
                itemElement.setAttribute("recipeId", Integer.toString(item.getRecetteId()));
                itemElement.setAttribute("recipeTitle", safe(item.getRecetteTitre()));
                itemElement.setAttribute("quantity", Integer.toString(item.getQuantite()));
                itemElement.setAttribute("unitPrice", number(item.getPrixUnitaire()));
                orderElement.appendChild(itemElement);
            }
        }
    }

    private void appendText(Document document, Element parent, String tagName, String value) {
        Element element = document.createElement(tagName);
        element.setTextContent(safe(value));
        parent.appendChild(element);
    }

    private Element firstChild(Element parent, String tagName) {
        if (parent == null) {
            return null;
        }
        NodeList children = parent.getChildNodes();
        for (int i = 0; i < children.getLength(); i++) {
            Node child = children.item(i);
            if (child instanceof Element element && tagName.equals(element.getTagName())) {
                return element;
            }
        }
        return null;
    }

    private String textOf(Element element) {
        return element == null ? "" : safe(element.getTextContent()).trim();
    }

    private int attrInt(Element element, String name, int defaultValue) {
        if (element == null) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(element.getAttribute(name));
        } catch (NumberFormatException exception) {
            return defaultValue;
        }
    }

    private double attrDouble(Element element, String name, double defaultValue) {
        if (element == null) {
            return defaultValue;
        }
        try {
            return Double.parseDouble(element.getAttribute(name));
        } catch (NumberFormatException exception) {
            return defaultValue;
        }
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }

    private String number(double value) {
        return BigDecimal.valueOf(value).stripTrailingZeros().toPlainString();
    }

    private DocumentBuilder newDocumentBuilder() throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setIgnoringComments(true);
        factory.setNamespaceAware(false);
        return factory.newDocumentBuilder();
    }

    private StoreData createDefaultStore() {
        StoreData data = new StoreData();
        data.setNextUserId(3);
        data.setNextProduitId(14);
        data.setNextRecetteId(104);
        data.setNextCommandeId(1);

        List<Produit> produits = new ArrayList<>();
        produits.add(new Produit(1, "Riz a sushi", 8000, "g", 0.02));
        produits.add(new Produit(2, "Vinaigre de riz", 2500, "ml", 0.015));
        produits.add(new Produit(3, "Sucre", 3000, "g", 0.004));
        produits.add(new Produit(4, "Sel", 1500, "g", 0.002));
        produits.add(new Produit(5, "Feuilles de nori", 80, "feuilles", 0.35));
        produits.add(new Produit(6, "Saumon frais", 2500, "g", 0.045));
        produits.add(new Produit(7, "Thon frais", 2000, "g", 0.052));
        produits.add(new Produit(8, "Concombre", 30, "piece", 0.9));
        produits.add(new Produit(9, "Avocat", 24, "piece", 1.2));
        produits.add(new Produit(10, "Wasabi", 400, "g", 0.08));
        produits.add(new Produit(11, "Sauce soja", 3000, "ml", 0.012));
        produits.add(new Produit(12, "Gingembre marine", 1000, "g", 0.02));
        produits.add(new Produit(13, "Graines de sesame", 800, "g", 0.018));
        data.setProduits(produits);

        Map<Integer, Produit> produitsById = new HashMap<>();
        for (Produit produit : produits) {
            produitsById.put(produit.getId(), produit);
        }

        List<Recette> recettes = new ArrayList<>();
        recettes.add(createRecipe(
                101,
                "Maki saumon avocat",
                "1) Cuire et assaisonner le riz.\n2) Etaler le riz sur la feuille de nori.\n3) Ajouter saumon et avocat, rouler puis decouper.",
                12.90,
                ingredient(produitsById.get(1), 250, "g"),
                ingredient(produitsById.get(2), 30, "ml"),
                ingredient(produitsById.get(3), 10, "g"),
                ingredient(produitsById.get(4), 3, "g"),
                ingredient(produitsById.get(5), 2, "feuilles"),
                ingredient(produitsById.get(6), 120, "g"),
                ingredient(produitsById.get(9), 1, "piece")
        ));
        recettes.add(createRecipe(
                102,
                "Nigiri thon",
                "1) Former des boudins de riz.\n2) Deposer le thon sur chaque piece.\n3) Servir avec wasabi et sauce soja.",
                14.50,
                ingredient(produitsById.get(1), 200, "g"),
                ingredient(produitsById.get(2), 25, "ml"),
                ingredient(produitsById.get(3), 8, "g"),
                ingredient(produitsById.get(4), 2, "g"),
                ingredient(produitsById.get(7), 150, "g"),
                ingredient(produitsById.get(10), 5, "g"),
                ingredient(produitsById.get(11), 20, "ml")
        ));
        recettes.add(createRecipe(
                103,
                "California concombre sesame",
                "1) Etaler le riz sur le nori puis retourner.\n2) Garnir avec concombre et rouler.\n3) Parsemer de sesame, decouper et servir.",
                9.50,
                ingredient(produitsById.get(1), 250, "g"),
                ingredient(produitsById.get(2), 30, "ml"),
                ingredient(produitsById.get(3), 10, "g"),
                ingredient(produitsById.get(4), 3, "g"),
                ingredient(produitsById.get(5), 2, "feuilles"),
                ingredient(produitsById.get(8), 0.5, "piece"),
                ingredient(produitsById.get(13), 10, "g")
        ));
        data.setRecettes(recettes);

        List<User> users = new ArrayList<>();
        User admin = new User();
        admin.setId(1);
        admin.setUsername("admin");
        admin.setPasswordHash(SecurityUtil.hashPassword("admin"));
        admin.setAdmin(true);
        users.add(admin);

        User demo = new User();
        demo.setId(2);
        demo.setUsername("demo");
        demo.setPasswordHash(SecurityUtil.hashPassword("demo"));
        demo.setAdmin(false);
        demo.getFavoris().add(101);
        demo.getPanier().add(new PanierItem(103, 1));
        users.add(demo);
        data.setUsers(users);

        data.setCommandes(new ArrayList<>());
        return data;
    }

    private Recette createRecipe(int id, String title, String description, double price, Ingredient... ingredients) {
        Recette recette = new Recette();
        recette.setId(id);
        recette.setTitre(title);
        recette.setDescriptionEtapes(description);
        recette.setPrix(price);
        List<Ingredient> list = new ArrayList<>();
        for (Ingredient ingredient : ingredients) {
            list.add(ingredient);
        }
        recette.setIngredients(list);
        return recette;
    }

    private Ingredient ingredient(Produit produit, double quantity, String unit) {
        Ingredient ingredient = new Ingredient();
        ingredient.setProduit(produit);
        ingredient.setQuantite(quantity);
        ingredient.setUnite(unit);
        return ingredient;
    }
}
