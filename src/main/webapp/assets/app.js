document.addEventListener("DOMContentLoaded", () => {
    const rows = document.querySelector("#ingredient-rows");
    const template = document.querySelector("#ingredient-template");
    const addButton = document.querySelector("[data-add-ingredient]");

    const bindRow = (row) => {
        const removeButton = row.querySelector("[data-remove-ingredient]");
        const select = row.querySelector("select[name='ingredientProductId']");
        const unitInput = row.querySelector("input[name='ingredientUnit']");

        if (removeButton) {
            removeButton.addEventListener("click", () => {
                const allRows = rows.querySelectorAll(".ingredient-row");
                if (allRows.length > 1) {
                    row.remove();
                } else {
                    row.querySelectorAll("input").forEach((input) => input.value = "");
                    if (select) select.value = "";
                }
            });
        }

        if (select && unitInput) {
            select.addEventListener("change", () => {
                const option = select.options[select.selectedIndex];
                if (!unitInput.value.trim()) {
                    unitInput.value = option ? option.dataset.unit || "" : "";
                }
            });
        }
    };

    if (rows) rows.querySelectorAll(".ingredient-row").forEach(bindRow);

    if (rows && template && addButton) {
        addButton.addEventListener("click", () => {
            const fragment = template.content.cloneNode(true);
            rows.appendChild(fragment);
            bindRow(rows.lastElementChild);
        });
    }
});
