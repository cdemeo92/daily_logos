// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/daily_logos";
import topbar from "../vendor/topbar";
import { initCookieConsent } from "./cookieconsent-config";

initCookieConsent();

window.addEventListener("pageshow", (event) => {
  if (event.persisted) window.location.reload();
});

document.addEventListener("click", (event) => {
  const button = event.target.closest("button[data-dismiss-flash]");
  if (!button) return;

  const flash = document.getElementById(button.dataset.dismissFlash);
  if (!flash) return;

  flash.hidden = true;
  flash.classList.add("hidden");
});

document.addEventListener("click", (event) => {
  const button = event.target.closest("button[data-password-target]");
  if (!button) return;

  const input = document.getElementById(button.dataset.passwordTarget);
  if (!input) return;

  const visible = input.type === "password";
  input.type = visible ? "text" : "password";
  const label = visible ? button.dataset.hideLabel : button.dataset.showLabel;
  button.setAttribute("aria-label", label);
  button.setAttribute("title", label);
  button.setAttribute("aria-pressed", String(visible));
  button.querySelector(".hero-eye").classList.toggle("hidden", visible);
  button.querySelector(".hero-eye-slash").classList.toggle("hidden", !visible);
});

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const setMobileMenuOpen = (open, trigger = null) => {
  const menu = document.getElementById("mobile-menu");
  const overlay = document.getElementById("mobile-menu-overlay");
  const appShell = document.getElementById("app-shell");
  const toggle = document.getElementById("menu-toggle");
  if (!menu || !overlay || !appShell || !toggle) return;

  if (open) {
    menu.classList.remove("translate-x-full");
    menu.inert = false;
    menu.removeAttribute("aria-hidden");
    overlay.classList.remove("hidden");
    overlay.removeAttribute("aria-hidden");
    appShell.inert = true;
    toggle.setAttribute("aria-expanded", "true");
    toggle.setAttribute("aria-label", toggle.dataset.closeLabel);
    menu.querySelector("#menu-close").focus();
    return;
  }

  menu.classList.add("translate-x-full");
  menu.inert = true;
  menu.setAttribute("aria-hidden", "true");
  overlay.classList.add("hidden");
  overlay.setAttribute("aria-hidden", "true");
  appShell.inert = false;
  toggle.setAttribute("aria-expanded", "false");
  toggle.setAttribute("aria-label", toggle.dataset.openLabel);
  (trigger || toggle).focus();
};

// Modal navigation drawer hooks
const HamburgerMenu = {
  mounted() {
    this.el.addEventListener("click", () => setMobileMenuOpen(true));
  },
};

const MobileMenuOverlay = {
  mounted() {
    this.el.addEventListener("click", () => setMobileMenuOpen(false));
  },
};

const MobileMenuClose = {
  mounted() {
    this.el.addEventListener("click", () => setMobileMenuOpen(false));
  },
};

const ThemeToggle = {
  mounted() {
    this.updateSelection(localStorage.getItem("phx:theme") || "system");
    this.handleThemeChange = (event) => {
      const button = event.target.closest?.("button[data-phx-theme]");
      if (button && this.el.contains(button))
        this.updateSelection(button.dataset.phxTheme);
    };
    this.el.addEventListener("phx:set-theme", this.handleThemeChange);
  },
  updateSelection(theme) {
    this.el.querySelectorAll("button[data-phx-theme]").forEach((button) => {
      button.setAttribute(
        "aria-pressed",
        String(button.dataset.phxTheme === theme),
      );
    });
  },
  destroyed() {
    this.el.removeEventListener("phx:set-theme", this.handleThemeChange);
  },
};

document.addEventListener("click", async (event) => {
  const button = event.target.closest("button[data-phx-locale]");
  const localeToggle = button?.closest("[data-locale]");
  if (!button || !localeToggle) return;

  event.preventDefault();
  const locale = button.dataset.phxLocale;
  localeToggle.dataset.locale = locale;
  localeToggle
    .querySelectorAll("button[data-phx-locale]")
    .forEach((localeButton) => {
      localeButton.setAttribute(
        "aria-pressed",
        String(localeButton === button),
      );
    });

  try {
    const response = await fetch(`/locale/${locale}`, {
      method: "POST",
      headers: { "x-csrf-token": localeToggle.dataset.csrf },
      credentials: "same-origin",
      redirect: "follow",
    });

    if (response.redirected) {
      window.location.assign(response.url);
    } else {
      window.location.reload();
    }
  } catch (_error) {
    window.location.reload();
  }
});

document.addEventListener("keydown", (event) => {
  const menu = document.getElementById("mobile-menu");
  if (menu && !menu.inert) {
    if (event.key === "Escape") {
      event.preventDefault();
      setMobileMenuOpen(false);
      return;
    }

    if (event.key === "Tab") {
      const focusable = [
        ...menu.querySelectorAll("a[href], button:not(:disabled)"),
      ];
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }
  }

  if (event.key === "Escape") {
    const openAccount = [
      ...document.querySelectorAll("details.account-menu[open]"),
    ].find((details) => details.contains(document.activeElement));
    if (openAccount) {
      openAccount.open = false;
      openAccount.querySelector("summary").focus();
    }
  }
});

document.addEventListener("click", (event) => {
  if (event.target.closest("details.account-menu")) return;
  document.querySelectorAll("details.account-menu[open]").forEach((details) => {
    details.open = false;
  });
});

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: {
    ...colocatedHooks,
    HamburgerMenu,
    MobileMenuOverlay,
    MobileMenuClose,
    ThemeToggle,
  },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (_e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );

      window.liveReloader = reloader;
    },
  );
}
