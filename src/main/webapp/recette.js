function addIngredient() {
    const container = document.getElementById("ingredients");

    const div = document.createElement("div");
    div.className = "ingredient";

    div.innerHTML = `
        <label>ID produit</label>
        <input type="number" name="produitId" required>

        <label>Nom produit</label>
        <input type="text" name="produitNom">

        <label>Quantité</label>
        <input type="number" step="0.01" name="quantite" required>

        <label>Unité</label>
        <input type="text" name="unite">

        <div class="actions">
            <button type="button" class="remove" onclick="removeIngredient(this)">Supprimer</button>
        </div>
    `;
    container.appendChild(div);
}

function removeIngredient(button) {
    const container = document.getElementById("ingredients");
    if (container.children.length <= 1) {
        alert("Au moins un ingrédient est requis.");
        return;
    }
    button.closest(".ingredient").remove();
}