document.addEventListener("DOMContentLoaded", () => {
    initIngredientRows();
    initStepRows();
    initImagePickers(document);
    initStepPlayers();
    initHistoryBackButtons();
});

function resolveAssetPath(path) {
    if (!path) {
        return "";
    }
    if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("data:")) {
        return path;
    }

    const contextPath = window.location.pathname.split("/")[1] ? `/${window.location.pathname.split("/")[1]}` : "";
    return path.startsWith("/") ? `${contextPath}${path}` : `${contextPath}/${path}`;
}

function initImagePickers(root) {
    root.querySelectorAll("[data-image-choice]").forEach((select) => {
        if (select.dataset.imagePickerBound === "true") {
            return;
        }
        select.dataset.imagePickerBound = "true";

        const picker = select.closest(".maker-image-picker");
        const preview = picker ? picker.querySelector("[data-image-preview]") : null;
        const update = () => {
            if (preview) {
                preview.src = resolveAssetPath(select.value || "/assets/img/recipe-step-prep.png");
            }
        };

        select.addEventListener("change", update);
        update();
    });
}

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
            let row = null;
            if (template.content && template.content.firstElementChild) {
                const fragment = template.content.cloneNode(true);
                rows.appendChild(fragment);
                row = rows.lastElementChild;
            } else {
                const wrapper = document.createElement("div");
                wrapper.innerHTML = template.innerHTML.trim();
                row = wrapper.firstElementChild;
                if (row) {
                    rows.appendChild(row);
                }
            }
            if (row) {
                bindRow(row);
                initImagePickers(row);
                const textarea = row.querySelector("textarea[name='stepText']");
                if (textarea) {
                    textarea.focus();
                }
            }
        });
    }
}

function initStepRows() {
    const rows = document.querySelector("#step-rows");
    const template = document.querySelector("#step-template");
    const addButton = document.querySelector("[data-add-step]");

    const bindRow = (row) => {
        const removeButton = row.querySelector("[data-remove-step]");
        if (!removeButton) {
            return;
        }

        removeButton.addEventListener("click", () => {
            const allRows = rows.querySelectorAll(".step-row");
            if (allRows.length > 1) {
                row.remove();
                return;
            }

            row.querySelectorAll("textarea, input").forEach((field) => {
                field.value = "";
            });
        });
    };

    if (rows) {
        rows.querySelectorAll(".step-row").forEach(bindRow);
    }

    if (rows && template && addButton) {
        addButton.addEventListener("click", () => {
            const fragment = template.content.cloneNode(true);
            rows.appendChild(fragment);
            const row = rows.lastElementChild;
            bindRow(row);
            initImagePickers(row);
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

function initHistoryBackButtons() {
    document.querySelectorAll("[data-history-back]").forEach((link) => {
        link.addEventListener("click", (event) => {
            const href = link.getAttribute("href");
            const referrer = document.referrer;

            if (!referrer) {
                return;
            }

            try {
                const previousUrl = new URL(referrer, window.location.href);
                const sameOrigin = previousUrl.origin === window.location.origin;
                const differentPage = previousUrl.href !== window.location.href;

                if (sameOrigin && differentPage && window.history.length > 1) {
                    event.preventDefault();
                    window.history.back();
                } else if (!href || href === "#") {
                    event.preventDefault();
                }
            } catch (_error) {
                if (!href || href === "#") {
                    event.preventDefault();
                }
            }
        });
    });
}
