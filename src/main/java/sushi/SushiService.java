package sushi;

import java.nio.file.Path;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class SushiService {
    private final XmlStoreRepository repository;
    private final Object lock = new Object();

    public SushiService(Path storePath) {
        this.repository = new XmlStoreRepository(storePath);
        this.repository.ensureInitialized();
    }

    public Path getStorePath() {
        return repository.getStorePath();
    }

    public DashboardData getDashboardData(Integer currentUserId, Integer editedRecipeId) {
        synchronized (lock) {
            StoreData data = repository.load();
            sortData(data);

            User currentUser = findUser(data, currentUserId);
            Recette editedRecipe = findRecipe(data, editedRecipeId);
            List<Commande> userOrders = new ArrayList<>();
            List<Commande> allOrders = new ArrayList<>(data.getCommandes());

            if (currentUser != null) {
                for (Commande commande : data.getCommandes()) {
                    if (commande.getUserId() == currentUser.getId()) {
                        userOrders.add(commande);
                    }
                }
            }

            Map<Integer, Integer> availability = buildAvailabilityMap(data);

            return new DashboardData(
                    data.getRecettes(),
                    data.getProduits(),
                    currentUser,
                    userOrders,
                    allOrders,
                    availability,
                    editedRecipe,
                    repository.getStorePath()
            );
        }
    }

    public User login(String username, String password) {
        if (isBlank(username) || isBlank(password)) {
            throw new SushiException("Nom d'utilisateur et mot de passe obligatoires.");
        }

        synchronized (lock) {
            StoreData data = repository.load();
            User user = findUserByUsername(data, username.trim());
            if (user != null && SecurityUtil.matches(password, user.getPasswordHash())) {
                return user;
            }
            throw new SushiException("Identifiants invalides.");
        }
    }

    public User register(String username, String password, String confirmPassword) {
        if (isBlank(username) || isBlank(password) || isBlank(confirmPassword)) {
            throw new SushiException("Tous les champs d'inscription sont obligatoires.");
        }

        String normalizedUsername = username.trim();
        if (!normalizedUsername.matches("^[A-Za-z0-9._-]{3,30}$")) {
            throw new SushiException("Le nom d'utilisateur doit contenir entre 3 et 30 caracteres (lettres, chiffres, . _ -).");
        }
        if (password.length() < 4) {
            throw new SushiException("Le mot de passe doit contenir au moins 4 caracteres.");
        }
        if (!password.equals(confirmPassword)) {
            throw new SushiException("La confirmation du mot de passe ne correspond pas.");
        }

        synchronized (lock) {
            StoreData data = repository.load();
            if (findUserByUsername(data, normalizedUsername) != null) {
                throw new SushiException("Ce nom d'utilisateur existe deja.");
            }

            User user = new User();
            user.setId(data.getNextUserId());
            data.setNextUserId(data.getNextUserId() + 1);
            user.setUsername(normalizedUsername);
            user.setPasswordHash(SecurityUtil.hashPassword(password));
            user.setAdmin(false);
            data.getUsers().add(user);

            repository.save(data);
            return user;
        }
    }

    public void toggleFavorite(int userId, int recipeId) {
        synchronized (lock) {
            StoreData data = repository.load();
            User user = requireUser(data, userId);
            requireRecipe(data, recipeId);

            if (user.getFavoris().contains(recipeId)) {
                user.getFavoris().removeIf(currentId -> currentId == recipeId);
            } else {
                user.getFavoris().add(recipeId);
            }
            repository.save(data);
        }
    }

    public void addToCart(int userId, int recipeId, int quantity) {
        if (quantity <= 0) {
            throw new SushiException("La quantite doit etre strictement positive.");
        }

        synchronized (lock) {
            StoreData data = repository.load();
            User user = requireUser(data, userId);
            Recette recette = requireRecipe(data, recipeId);

            int available = getAvailability(recette, buildProductMap(data));
            PanierItem item = findCartItem(user, recipeId);
            int existingQuantity = item == null ? 0 : item.getQuantite();

            if (existingQuantity + quantity > available) {
                throw new SushiException("Stock insuffisant pour ajouter cette recette au panier.");
            }

            if (item == null) {
                user.getPanier().add(new PanierItem(recipeId, quantity));
            } else {
                item.setQuantite(existingQuantity + quantity);
            }

            repository.save(data);
        }
    }

    public void removeFromCart(int userId, int recipeId, int quantity) {
        synchronized (lock) {
            StoreData data = repository.load();
            User user = requireUser(data, userId);
            PanierItem item = findCartItem(user, recipeId);
            if (item == null) {
                throw new SushiException("Cette recette n'est pas dans le panier.");
            }

            if (quantity <= 0 || quantity >= item.getQuantite()) {
                user.getPanier().remove(item);
            } else {
                item.setQuantite(item.getQuantite() - quantity);
            }

            repository.save(data);
        }
    }

    public Commande checkout(int userId) {
        synchronized (lock) {
            StoreData data = repository.load();
            User user = requireUser(data, userId);
            if (user.getPanier().isEmpty()) {
                throw new SushiException("Le panier est vide.");
            }

            Map<Integer, Produit> productsById = buildProductMap(data);
            Map<Integer, Recette> recipesById = buildRecipeMap(data);
            Map<Integer, Double> remainingStock = new HashMap<>();
            for (Produit produit : data.getProduits()) {
                remainingStock.put(produit.getId(), produit.getStock());
            }

            Commande commande = new Commande();
            commande.setId(data.getNextCommandeId());
            data.setNextCommandeId(data.getNextCommandeId() + 1);
            commande.setUserId(user.getId());
            commande.setUsername(user.getUsername());
            commande.setDateCreation(OffsetDateTime.now().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME));

            double total = 0D;
            List<CommandeItem> items = new ArrayList<>();

            for (PanierItem panierItem : user.getPanier()) {
                Recette recette = recipesById.get(panierItem.getRecetteId());
                if (recette == null) {
                    throw new SushiException("Une recette du panier n'existe plus.");
                }

                for (Ingredient ingredient : recette.getIngredients()) {
                    Produit produit = productsById.get(ingredient.getProduit().getId());
                    if (produit == null) {
                        throw new SushiException("Une recette reference un produit inexistant.");
                    }

                    double needed = ingredient.getQuantite() * panierItem.getQuantite();
                    double nextStock = remainingStock.get(produit.getId()) - needed;
                    if (nextStock < -0.0001D) {
                        throw new SushiException("Stock insuffisant pour finaliser la commande.");
                    }
                    remainingStock.put(produit.getId(), nextStock);
                }

                CommandeItem item = new CommandeItem();
                item.setRecetteId(recette.getId());
                item.setRecetteTitre(recette.getTitre());
                item.setQuantite(panierItem.getQuantite());
                item.setPrixUnitaire(recette.getPrix());
                items.add(item);
                total += recette.getPrix() * panierItem.getQuantite();
            }

            for (Produit produit : data.getProduits()) {
                Double stock = remainingStock.get(produit.getId());
                if (stock != null) {
                    produit.setStock(Math.max(0D, stock));
                }
            }

            commande.setItems(items);
            commande.setTotal(total);
            data.getCommandes().add(commande);
            user.getPanier().clear();
            repository.save(data);
            return commande;
        }
    }

    public Recette saveRecipe(int userId, Integer recipeId, String title, String description, double price, List<IngredientForm> ingredientForms) {
        synchronized (lock) {
            StoreData data = repository.load();
            requireAdmin(data, userId);

            if (isBlank(title) || isBlank(description)) {
                throw new SushiException("Titre et description sont obligatoires.");
            }
            if (price < 0D) {
                throw new SushiException("Le prix ne peut pas etre negatif.");
            }
            if (ingredientForms == null || ingredientForms.isEmpty()) {
                throw new SushiException("La recette doit contenir au moins un ingredient.");
            }

            Map<Integer, Produit> productsById = buildProductMap(data);
            List<Ingredient> ingredients = new ArrayList<>();
            for (IngredientForm form : ingredientForms) {
                Produit produit = productsById.get(form.productId());
                if (produit == null) {
                    throw new SushiException("Un ingredient reference un produit inconnu.");
                }
                if (form.quantity() <= 0D) {
                    throw new SushiException("Les quantites d'ingredients doivent etre positives.");
                }
                Ingredient ingredient = new Ingredient();
                ingredient.setProduit(produit);
                ingredient.setQuantite(form.quantity());
                ingredient.setUnite(isBlank(form.unit()) ? produit.getUnite() : form.unit().trim());
                ingredients.add(ingredient);
            }

            Recette recette = recipeId == null ? null : findRecipe(data, recipeId);
            if (recette == null) {
                recette = new Recette();
                recette.setId(data.getNextRecetteId());
                data.setNextRecetteId(data.getNextRecetteId() + 1);
                data.getRecettes().add(recette);
            }

            recette.setTitre(title.trim());
            recette.setDescriptionEtapes(description.trim());
            recette.setPrix(price);
            recette.setIngredients(ingredients);

            repository.save(data);
            return recette;
        }
    }

    public void deleteRecipe(int userId, int recipeId) {
        synchronized (lock) {
            StoreData data = repository.load();
            requireAdmin(data, userId);
            Recette recette = requireRecipe(data, recipeId);
            data.getRecettes().remove(recette);

            for (User user : data.getUsers()) {
                user.getFavoris().removeIf(currentId -> currentId == recipeId);
                user.getPanier().removeIf(item -> item.getRecetteId() == recipeId);
            }

            repository.save(data);
        }
    }

    public Produit saveProduct(int userId, Integer productId, String name, double stock, String unit, double price) {
        synchronized (lock) {
            StoreData data = repository.load();
            requireAdmin(data, userId);

            if (isBlank(name) || isBlank(unit)) {
                throw new SushiException("Nom, unite et stock produit sont obligatoires.");
            }
            if (stock < 0D || price < 0D) {
                throw new SushiException("Stock et prix doivent etre positifs.");
            }

            Produit produit = productId == null ? null : findProduct(data, productId);
            if (produit == null) {
                produit = new Produit();
                produit.setId(data.getNextProduitId());
                data.setNextProduitId(data.getNextProduitId() + 1);
                data.getProduits().add(produit);
            }

            produit.setNom(name.trim());
            produit.setStock(stock);
            produit.setUnite(unit.trim());
            produit.setPrixUnitaire(price);

            repository.save(data);
            return produit;
        }
    }

    public Map<Integer, Integer> getAvailabilityMap() {
        synchronized (lock) {
            StoreData data = repository.load();
            return buildAvailabilityMap(data);
        }
    }

    private Map<Integer, Integer> buildAvailabilityMap(StoreData data) {
        Map<Integer, Produit> productsById = buildProductMap(data);
        Map<Integer, Integer> availability = new HashMap<>();
        for (Recette recette : data.getRecettes()) {
            availability.put(recette.getId(), getAvailability(recette, productsById));
        }
        return availability;
    }

    private int getAvailability(Recette recette, Map<Integer, Produit> productsById) {
        if (recette == null || recette.getIngredients().isEmpty()) {
            return 0;
        }

        int min = Integer.MAX_VALUE;
        for (Ingredient ingredient : recette.getIngredients()) {
            if (ingredient.getProduit() == null || ingredient.getQuantite() <= 0D) {
                return 0;
            }

            Produit produit = productsById.get(ingredient.getProduit().getId());
            if (produit == null) {
                return 0;
            }

            int available = (int) Math.floor(produit.getStock() / ingredient.getQuantite());
            min = Math.min(min, available);
        }

        return min == Integer.MAX_VALUE ? 0 : Math.max(0, min);
    }

    private Map<Integer, Produit> buildProductMap(StoreData data) {
        Map<Integer, Produit> products = new HashMap<>();
        for (Produit produit : data.getProduits()) {
            products.put(produit.getId(), produit);
        }
        return products;
    }

    private Map<Integer, Recette> buildRecipeMap(StoreData data) {
        Map<Integer, Recette> recipes = new HashMap<>();
        for (Recette recette : data.getRecettes()) {
            recipes.put(recette.getId(), recette);
        }
        return recipes;
    }

    private User requireUser(StoreData data, Integer userId) {
        User user = findUser(data, userId);
        if (user == null) {
            throw new SushiException("Connexion requise.");
        }
        return user;
    }

    private User requireAdmin(StoreData data, int userId) {
        User user = requireUser(data, userId);
        if (!user.isAdmin()) {
            throw new SushiException("Acces reserve a l'administrateur.");
        }
        return user;
    }

    private Recette requireRecipe(StoreData data, int recipeId) {
        Recette recette = findRecipe(data, recipeId);
        if (recette == null) {
            throw new SushiException("Recette introuvable.");
        }
        return recette;
    }

    private Produit requireProduct(StoreData data, int productId) {
        Produit produit = findProduct(data, productId);
        if (produit == null) {
            throw new SushiException("Produit introuvable.");
        }
        return produit;
    }

    private User findUser(StoreData data, Integer userId) {
        if (userId == null) {
            return null;
        }
        for (User user : data.getUsers()) {
            if (user.getId() == userId) {
                return user;
            }
        }
        return null;
    }

    private User findUserByUsername(StoreData data, String username) {
        if (isBlank(username)) {
            return null;
        }
        for (User user : data.getUsers()) {
            if (user.getUsername() != null && user.getUsername().equalsIgnoreCase(username.trim())) {
                return user;
            }
        }
        return null;
    }

    private Recette findRecipe(StoreData data, Integer recipeId) {
        if (recipeId == null) {
            return null;
        }
        for (Recette recette : data.getRecettes()) {
            if (recette.getId() == recipeId) {
                return recette;
            }
        }
        return null;
    }

    private Produit findProduct(StoreData data, Integer productId) {
        if (productId == null) {
            return null;
        }
        for (Produit produit : data.getProduits()) {
            if (produit.getId() == productId) {
                return produit;
            }
        }
        return null;
    }

    private PanierItem findCartItem(User user, int recipeId) {
        for (PanierItem item : user.getPanier()) {
            if (item.getRecetteId() == recipeId) {
                return item;
            }
        }
        return null;
    }

    private void sortData(StoreData data) {
        data.getProduits().sort(Comparator.comparing(Produit::getNom, String.CASE_INSENSITIVE_ORDER));
        data.getRecettes().sort(Comparator.comparingInt(Recette::getId));
        data.getCommandes().sort(Comparator.comparing(Commande::getDateCreation).reversed());
        for (User user : data.getUsers()) {
            user.getPanier().sort(Comparator.comparingInt(PanierItem::getRecetteId));
            user.getFavoris().sort(Integer::compareTo);
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    public record IngredientForm(int productId, double quantity, String unit) {
    }

    public record DashboardData(
            List<Recette> recettes,
            List<Produit> produits,
            User currentUser,
            List<Commande> userCommandes,
            List<Commande> allCommandes,
            Map<Integer, Integer> disponibilites,
            Recette recetteEdition,
            Path dataPath
    ) {
    }
}

