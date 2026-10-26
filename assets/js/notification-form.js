import { initializeDropdownSelect } from "./dropdown-select";
import { initializeWeekdaySelect } from "./weekday-select";

const initializeNotificationForm = () => {
  const form = document.querySelector("[data-notification-form]");
  if (!form) return;

  const saveButton = form.querySelector("[type='submit']");
  const feedback = form.querySelector("[data-notification-feedback]");
  form
    .querySelectorAll("[data-dropdown-select]")
    .forEach(initializeDropdownSelect);
  form
    .querySelectorAll("[data-weekday-select]")
    .forEach(initializeWeekdaySelect);

  const fieldTargets = {
    weekdays: {
      control: "#notification-weekday",
      container: "#notification-weekday",
    },
    local_hour: {
      control: "#subscription_local_hour-trigger",
      container: "#subscription_local_hour-select",
    },
    timezone: {
      control: "#subscription_timezone-trigger",
      container: "#subscription_timezone-select",
    },
    language: {
      control: "#subscription_language-trigger",
      container: "#subscription_language-select",
    },
    enabled: { control: "#subscription_enabled", container: ".fieldset" },
  };

  const subscriptionValues = () => {
    const values = {};

    for (const [name, value] of new FormData(form)) {
      const match = name.match(/^subscription\[([^\]]+)\](\[\])?$/);
      if (!match) continue;

      const [, field, array] = match;
      if (array) {
        values[field] ||= [];
        if (value !== "") values[field].push(Number(value));
      } else if (field === "enabled") {
        values.enabled = value === "true";
      } else if (field === "local_hour") {
        values.local_hour = value === "" ? null : Number(value);
      } else {
        values[field] = value === "" ? null : value;
      }
    }

    return values;
  };

  let initialValues = JSON.stringify(subscriptionValues());
  let dirty = false;
  let submitting = false;

  const clearFeedback = () => {
    form.querySelectorAll("[data-api-field-error]").forEach((error) => {
      const target = form.querySelector(
        `#${CSS.escape(error.dataset.targetId)}`,
      );
      target?.removeAttribute("aria-invalid");

      if (target && error.dataset.hadDescribedBy === "true") {
        target.setAttribute(
          "aria-describedby",
          error.dataset.previousDescribedBy,
        );
      } else {
        target?.removeAttribute("aria-describedby");
      }

      error.remove();
    });
    feedback.hidden = true;
    feedback.textContent = "";
    feedback.classList.remove("text-error", "text-success");
  };

  const showFeedback = (message, errors = null, unauthorized = false) => {
    clearFeedback();
    feedback.textContent = message;
    feedback.hidden = false;
    feedback.setAttribute("role", "alert");
    feedback.classList.add("text-error");

    if (!errors) return;

    for (const [field, messages] of Object.entries(errors)) {
      const selectors = fieldTargets[field];
      if (!selectors) continue;
      const target = form.querySelector(selectors.control);
      const container = form.querySelector(selectors.container);
      if (!target || !container) continue;

      const error = document.createElement("p");
      error.id = `${target.id}-api-error`;
      error.dataset.apiFieldError = "";
      error.dataset.targetId = target.id;
      error.dataset.hadDescribedBy = String(
        target.hasAttribute("aria-describedby"),
      );
      error.dataset.previousDescribedBy =
        target.getAttribute("aria-describedby") || "";
      error.className = "mt-2 text-sm text-error";
      error.textContent = `${messages.join(" ")}`;

      container?.append(error);
      target.setAttribute("aria-invalid", "true");
      const describedBy = target.getAttribute("aria-describedby");
      target.setAttribute(
        "aria-describedby",
        [describedBy, error.id].filter(Boolean).join(" "),
      );
    }

    if (unauthorized) feedback.textContent = form.dataset.unauthenticatedLabel;
  };

  const setSaving = (saving) => {
    submitting = saving;
    saveButton.disabled = saving || !dirty;
    saveButton.querySelector("[data-notification-save-label]").textContent =
      saving ? form.dataset.savingLabel : form.dataset.saveLabel;
    form.setAttribute("aria-busy", String(saving));
  };

  const updateDirtyState = () => {
    dirty = JSON.stringify(subscriptionValues()) !== initialValues;
    saveButton.disabled = !dirty || submitting;
  };

  const handleEdit = () => {
    if (!feedback.hidden) clearFeedback();
    updateDirtyState();
  };

  form.addEventListener("input", handleEdit);
  form.addEventListener("change", handleEdit);

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (submitting) {
      return;
    }

    const csrfToken = new FormData(form).get("_csrf_token");
    if (!csrfToken) {
      showFeedback(form.dataset.errorLabel);
      return;
    }

    setSaving(true);

    try {
      const response = await fetch(form.action, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "x-csrf-token": csrfToken,
        },
        body: JSON.stringify({ subscription: subscriptionValues() }),
      });
      const result = await response.json();

      if (!response.ok) {
        showFeedback(
          result.error?.message || form.dataset.errorLabel,
          result.error?.fields,
          response.status === 401,
        );
        return;
      }

      if (form.action.endsWith("/notifications")) {
        form.action = `${form.action}/${result.data.id}`;
      }

      clearFeedback();
      feedback.textContent = result.message;
      feedback.hidden = false;
      feedback.setAttribute("role", "status");
      feedback.classList.add("text-success");
      initialValues = JSON.stringify(subscriptionValues());
      dirty = false;
    } catch {
      showFeedback(form.dataset.errorLabel);
    } finally {
      setSaving(false);
    }
  });

  window.addEventListener("beforeunload", (event) => {
    if (!dirty || submitting) return;
    event.preventDefault();
    event.returnValue = "";
  });

  updateDirtyState();
};

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initializeNotificationForm, {
    once: true,
  });
} else {
  initializeNotificationForm();
}
