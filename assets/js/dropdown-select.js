export const initializeDropdownSelect = (root) => {
  const valueInput = root.querySelector("input[type='hidden']");
  const trigger = root.querySelector("[data-dropdown-trigger]");
  const label = root.querySelector("[data-dropdown-label]");
  const panel = root.querySelector("[data-dropdown-panel]");
  const search = root.querySelector("[data-dropdown-search]");
  const listbox = root.querySelector("[role='listbox']");
  const focusTarget = search || listbox;
  const empty = root.querySelector("[data-dropdown-empty]");
  const options = Array.from(root.querySelectorAll("[data-dropdown-option]"));
  let visibleOptions = options;
  let activeIndex = -1;

  const markSelected = (option) => {
    label.textContent = option.textContent.trim();
    options.forEach((item) => item.setAttribute("aria-selected", String(item === option)));
  };

  if (!valueInput.value && root.dataset.suggestBrowser === "true") {
    try {
      const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
      const option = options.find((item) => item.dataset.value === timezone);
      if (option) {
        valueInput.value = timezone;
        markSelected(option);
      }
    } catch {
      valueInput.value = "";
    }
  }

  const setActive = (index) => {
    activeIndex = index;
    options.forEach((option) => delete option.dataset.active);
    const option = visibleOptions[index];
    if (option) {
      option.dataset.active = "true";
      focusTarget.setAttribute("aria-activedescendant", option.id);
      option.scrollIntoView({block: "nearest"});
    } else {
      focusTarget.removeAttribute("aria-activedescendant");
    }
  };

  const filter = () => {
    const query = search?.value.trim().toLowerCase() || "";
    visibleOptions = options.filter((option) => {
      const matches = option.textContent.toLowerCase().includes(query);
      option.hidden = !matches;
      return matches;
    });
    if (empty) empty.hidden = visibleOptions.length !== 0;
    setActive(visibleOptions.length ? 0 : -1);
  };

  const close = (restoreFocus = false) => {
    panel.hidden = true;
    trigger.setAttribute("aria-expanded", "false");
    search?.setAttribute("aria-expanded", "false");
    if (restoreFocus) trigger.focus();
  };

  const open = () => {
    panel.hidden = false;
    trigger.setAttribute("aria-expanded", "true");
    if (search) {
      search.setAttribute("aria-expanded", "true");
      search.value = "";
    }
    filter();
    const selectedIndex = visibleOptions.findIndex(
      (option) => option.dataset.value === valueInput.value,
    );
    if (selectedIndex >= 0) setActive(selectedIndex);
    focusTarget.focus();
  };

  const select = (option) => {
    valueInput.value = option.dataset.value;
    markSelected(option);
    valueInput.dispatchEvent(new Event("change", {bubbles: true}));
    close(true);
  };

  trigger.addEventListener("click", () => panel.hidden ? open() : close());
  trigger.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      open();
    } else if (search && event.key.length === 1 && !event.ctrlKey && !event.metaKey && event.key !== " ") {
      event.preventDefault();
      open();
      search.value = event.key;
      filter();
    }
  });

  search?.addEventListener("input", filter);
  root.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && !panel.hidden) {
      event.preventDefault();
      close(true);
    }
  });
  focusTarget.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      if (!visibleOptions.length) return;
      const step = event.key === "ArrowDown" ? 1 : -1;
      setActive((activeIndex + step + visibleOptions.length) % visibleOptions.length);
    } else if (event.key === "Home" || event.key === "End") {
      if (search) return;
      event.preventDefault();
      setActive(event.key === "Home" ? 0 : visibleOptions.length - 1);
    } else if (event.key === "Enter" || (!search && event.key === " ")) {
      event.preventDefault();
      if (visibleOptions[activeIndex]) select(visibleOptions[activeIndex]);
    }
  });
  panel.addEventListener("click", (event) => {
    const option = event.target.closest("[data-dropdown-option]");
    if (option && root.contains(option)) select(option);
  });
  document.addEventListener("pointerdown", (event) => {
    if (!root.contains(event.target)) close();
  });
  root.addEventListener("focusout", (event) => {
    if (!root.contains(event.relatedTarget)) close();
  });
};