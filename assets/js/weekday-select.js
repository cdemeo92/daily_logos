export const initializeWeekdaySelect = (root) => {
  root.addEventListener("click", (event) => {
    const button = event.target.closest("[data-weekday-toggle]");
    if (!button || !root.contains(button)) return;

    const value = document.getElementById(button.dataset.weekdayValueId);
    const selected = button.getAttribute("aria-pressed") !== "true";

    button.setAttribute("aria-pressed", String(selected));
    value.disabled = !selected;
    value.dispatchEvent(new Event("change", {bubbles: true}));
  });
};