<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="sushi.Ingredient, sushi.Recette, sushi.Produit" %>

<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Résultat - Recette</title>
  <link rel="stylesheet" href="./recetteResult.css"/>
</head>
<body>

<%
  Recette r = (Recette) request.getAttribute("recette");
%>

<div class="card">
  <h1>Recette reçue</h1>

  <% if (r == null) { %>
      <p class="muted">Aucune recette à afficher.</p>
  <% } else { %>

      <h2><%= r.getTitre() %></h2>

      <h3>Étapes</h3>
      <p><%= r.getDescriptionEtapes() %></p>

      <h3>Ingrédients</h3>
      <ul>
        <% for (Ingredient ing : r.getIngredients()) {
             String pNom = (ing.getProduit().getNom() != null) ? ing.getProduit().getNom()
                                                              : ("Produit#" + ing.getProduit().getId());
             String u = (ing.getUnite() != null && !ing.getUnite().isEmpty()) ? (" " + ing.getUnite()) : "";
        %>
          <li><%= pNom %> : <%= ing.getQuantite() %><%= u %></li>
        <% } %>
      </ul>

  <% } %>
  <% String xmlPath = (String) request.getAttribute("xmlPath");
   String xmlError = (String) request.getAttribute("xmlError");
%>

<p><b>Fichier XML utilisé :</b> <%= xmlPath %></p>

<% if (xmlError != null) { %>
  <p style="color:red"><b>Erreur XML :</b> <%= xmlError %></p>
<% } else { %>
  <p style="color:green"><b>Sauvegarde XML :</b> OK</p>
<% } %>

  <a class="btn" href="<%= request.getContextPath() %>/recette.jsp">↩ Retour au formulaire</a>
</div>

</body>
</html>
