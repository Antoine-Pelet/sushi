document.addEventListener("DOMContentLoaded", () => {
    initIngredientRows();
    initStepPlayers();
});

function initIngredientRows() {
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
                    row.querySelectorAll("input").forEach((input) => {
                        input.value = "";
                    });
                    if (select) {
                        select.value = "";
                    }
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

    if (rows) {
        rows.querySelectorAll(".ingredient-row").forEach(bindRow);
    }

    if (rows && template && addButton) {
        addButton.addEventListener("click", () => {
            const fragment = template.content.cloneNode(true);
            rows.appendChild(fragment);
            bindRow(rows.lastElementChild);
        });
    }
}

function initStepPlayers() {
    document.querySelectorAll("[data-step-player]").forEach((player) => {
        const slides = Array.from(player.querySelectorAll("[data-step-slide]"));
        const prevButton = player.querySelector("[data-step-prev]");
        const nextButton = player.querySelector("[data-step-next]");
        const indicator = player.parentElement ? player.parentElement.querySelector("[data-step-indicator]") : null;

        if (slides.length === 0) {
            return;
        }

        let index = 0;

        const update = () => {
            slides.forEach((slide, currentIndex) => {
                slide.hidden = currentIndex !== index;
                slide.classList.toggle("is-active", currentIndex === index);
            });

            if (prevButton) {
                prevButton.disabled = index === 0;
            }
            if (nextButton) {
                nextButton.disabled = index === slides.length - 1;
            }
            if (indicator) {
                indicator.textContent = `${index + 1} / ${slides.length}`;
            }
        };

        if (prevButton) {
            prevButton.addEventListener("click", () => {
                if (index > 0) {
                    index -= 1;
                    update();
                }
            });
        }

        if (nextButton) {
            nextButton.addEventListener("click", () => {
                if (index < slides.length - 1) {
                    index += 1;
                    update();
                }
            });
        }

        update();
    });
}

