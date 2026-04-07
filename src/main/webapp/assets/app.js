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
        const prevButtons = Array.from(player.querySelectorAll("[data-step-prev]"));
        const nextButtons = Array.from(player.querySelectorAll("[data-step-next]"));
        const indicator = player.parentElement ? player.parentElement.querySelector("[data-step-indicator]") : null;
        const jumpButtons = Array.from(player.querySelectorAll("[data-step-jump]"));

        if (slides.length === 0) {
            return;
        }

        let index = slides.findIndex((slide) => slide.classList.contains("is-active") && !slide.hidden);
        if (index < 0) {
            index = 0;
        }

        const update = () => {
            slides.forEach((slide, currentIndex) => {
                slide.hidden = currentIndex !== index;
                slide.classList.toggle("is-active", currentIndex === index);
            });

            prevButtons.forEach((button) => {
                button.disabled = index === 0;
            });
            nextButtons.forEach((button) => {
                button.disabled = index === slides.length - 1;
            });

            if (indicator) {
                indicator.textContent = `${index + 1} / ${slides.length}`;
            }
        };

        prevButtons.forEach((button) => {
            button.addEventListener("click", () => {
                if (index > 0) {
                    index -= 1;
                    update();
                }
            });
        });

        nextButtons.forEach((button) => {
            button.addEventListener("click", () => {
                if (index < slides.length - 1) {
                    index += 1;
                    update();
                }
            });
        });

        jumpButtons.forEach((button) => {
            button.addEventListener("click", () => {
                const nextIndex = Number.parseInt(button.getAttribute("data-step-jump") || "", 10);
                if (!Number.isNaN(nextIndex) && nextIndex >= 0 && nextIndex < slides.length) {
                    index = nextIndex;
                    update();
                }
            });
        });

        update();
    });
}
