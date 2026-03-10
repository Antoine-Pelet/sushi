<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Ajouter une recette</title>
	<link rel="stylesheet" href="./recette.css"/>
</head>
<body>
	<h1>Ajouter une recette</h1>
	<form method="post" action="<%= request.getContextPath() %>/recette">
	    <label>Titre</label>
	    <input type="text" name="titre" required>
	
	    <label>Étapes / Description</label>
	    <textarea name="etapes" rows="5" required></textarea>
	    
	    <h2>Ingrédients</h2>
	    <div id="ingredients">
	        <div class="ingredient">
	            <label id="id">ID produit</label>
	            <input type="number" name="produitId" required>
	
	            <label id="nom">Nom produit</label>
	            <input type="text" name="produitNom">
	
	            <label id="quantite">Quantité</label>
	            <input type="number" step="0.01" name="quantite" required>
	
	            <label id="unite">Unité</label>
	            <input type="text" name="unite">
	
	            <div class="actions">
	                <button type="button" class="remove" onclick="removeIngredient(this)">Supprimer</button>
	            </div>
	        </div>
	    </div>
	    <button type="button" class="add" onclick="addIngredient()">+ Ajouter un ingrédient</button>
	    <br>
	    <button type="submit">Créer la recette</button>
	</form>
	<script src="./recette.js"></script>
</body>
</html>
