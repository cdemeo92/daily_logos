import * as CookieConsent from "vanilla-cookieconsent";

const DENIED = "denied";
const GRANTED = "granted";

function gtag() {
  window.dataLayer = window.dataLayer || [];
  window.dataLayer.push(arguments);
}

function gtmContainerId() {
  const meta = document.querySelector('meta[name="gtm-container-id"]');
  return meta?.getAttribute("content") || "";
}

function syncConsentEmbeds() {
  const enabled = CookieConsent.acceptedCategory("functionality");
  const embeds = document.querySelectorAll(
    'iframe[data-consent-category="functionality"]',
  );

  embeds.forEach((embed) => {
    const source = embed.dataset.src;
    const placeholder = document.querySelector(
      `[data-consent-placeholder-for="${embed.id}"]`,
    );

    if (enabled && source) {
      if (embed.getAttribute("src") !== source) {
        embed.setAttribute("src", source);
      }
      embed.classList.remove("hidden");
      placeholder?.classList.add("hidden");
    } else {
      embed.removeAttribute("src");
      embed.classList.add("hidden");
      placeholder?.classList.remove("hidden");
    }
  });
}

function openCookiePreferences() {
  CookieConsent.showPreferences();
}

function bindCookiePreferenceTriggers() {
  if (window.__cookiePreferencesBound) return;
  window.__cookiePreferencesBound = true;

  document.addEventListener("click", (event) => {
    const trigger = event.target.closest("[data-open-cookie-preferences]");
    if (!trigger) return;

    event.preventDefault();
    openCookiePreferences();
  });
}

function loadGtmIfConsented() {
  if (!CookieConsent.acceptedCategory("analytics")) return;

  const containerId = gtmContainerId();
  if (!containerId || window.__gtmLoaded) return;

  window.__gtmLoaded = true;
  window.dataLayer = window.dataLayer || [];
  window.dataLayer.push({ "gtm.start": new Date().getTime(), event: "gtm.js" });

  const script = document.createElement("script");
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtm.js?id=${encodeURIComponent(containerId)}`;
  document.head.appendChild(script);
}

function setDefaultGoogleConsent() {
  gtag("consent", "default", {
    analytics_storage: DENIED,
    functionality_storage: DENIED,
    ad_storage: DENIED,
    ad_user_data: DENIED,
    ad_personalization: DENIED,
    personalization_storage: DENIED,
    security_storage: GRANTED,
  });
}

function updateGoogleConsent() {
  gtag("consent", "update", {
    analytics_storage: CookieConsent.acceptedCategory("analytics")
      ? GRANTED
      : DENIED,
    functionality_storage: CookieConsent.acceptedCategory("functionality")
      ? GRANTED
      : DENIED,
    ad_storage: DENIED,
    ad_user_data: DENIED,
    ad_personalization: DENIED,
    personalization_storage: DENIED,
    security_storage: GRANTED,
  });

  loadGtmIfConsented();
}

export function initCookieConsent() {
  setDefaultGoogleConsent();
  bindCookiePreferenceTriggers();

  CookieConsent.run({
    mode: "opt-in",
    autoShow: true,
    manageScriptTags: true,
    autoClearCookies: true,
    revision: 1,
    cookie: {
      name: "cc_cookie",
      sameSite: "Lax",
      secure: true,
      expiresAfterDays: 182,
    },
    onFirstConsent: () => {
      updateGoogleConsent();
      syncConsentEmbeds();
    },
    onConsent: () => {
      updateGoogleConsent();
      syncConsentEmbeds();
    },
    onChange: ({ changedCategories }) => {
      if (
        changedCategories.includes("analytics") ||
        changedCategories.includes("functionality")
      ) {
        updateGoogleConsent();
      }

      if (changedCategories.includes("functionality")) {
        syncConsentEmbeds();
      }
    },
    categories: {
      necessary: {
        enabled: true,
        readOnly: true,
      },
      analytics: {
        autoClear: {
          cookies: [{ name: /^_ga/ }, { name: "_gid" }, { name: "_gat" }],
        },
        services: {
          analytics_storage: {
            label: "Google Analytics",
          },
        },
      },
      functionality: {
        services: {
          functionality_storage: {
            label: "Embedded content (Google Forms)",
          },
        },
      },
    },
    language: {
      default: "en",
      autoDetect: "document",
      translations: {
        en: {
          consentModal: {
            title: "Cookie notice",
            description:
              "Technical cookies are required for site operation. Analytics and embedded-content cookies are set only after consent.",
            acceptAllBtn: "Accept all",
            acceptNecessaryBtn: "Reject optional",
            showPreferencesBtn: "Manage preferences",
            footer: '<a href="/privacy">Privacy & Cookie Policy</a>',
          },
          preferencesModal: {
            title: "Cookie preferences",
            acceptAllBtn: "Accept all",
            acceptNecessaryBtn: "Reject optional",
            savePreferencesBtn: "Save preferences",
            closeIconLabel: "Close",
            sections: [
              {
                title: "Strictly necessary",
                description:
                  "_daily_logos_key stores session and locale state until the browser session ends. __phoenix_flash__ carries redirect flash messages for up to 60 seconds. _daily_logos_web_user_remember_me keeps you signed in for up to 14 days only if you choose to stay signed in. cc_cookie stores consent choices for 182 days.",
                linkedCategory: "necessary",
              },
              {
                title: "Analytics",
                description:
                  "Optional Google Analytics cookies such as _ga, _ga_<container-id>, _gid, and _gat are set only after analytics consent. Retention may vary by service.",
                linkedCategory: "analytics",
              },
              {
                title: "Functionality",
                description:
                  "This category enables third-party embedded content, such as Google Forms, after consent. The provider may set its own cookies.",
                linkedCategory: "functionality",
              },
              {
                title: "More information",
                description:
                  'Read our <a href="/privacy">Privacy & Cookie Policy</a>.',
              },
            ],
          },
        },
        it: {
          consentModal: {
            title: "Informativa cookie",
            description:
              "I cookie tecnici sono necessari al funzionamento del sito. I cookie di analytics e per contenuti incorporati vengono impostati solo dopo il consenso.",
            acceptAllBtn: "Accetta tutto",
            acceptNecessaryBtn: "Rifiuta opzionali",
            showPreferencesBtn: "Gestisci preferenze",
            footer: '<a href="/it/privacy">Privacy & Cookie Policy</a>',
          },
          preferencesModal: {
            title: "Preferenze cookie",
            acceptAllBtn: "Accetta tutto",
            acceptNecessaryBtn: "Rifiuta opzionali",
            savePreferencesBtn: "Salva preferenze",
            closeIconLabel: "Chiudi",
            sections: [
              {
                title: "Strettamente necessari",
                description:
                  "_daily_logos_key conserva sessione e lingua fino alla chiusura del browser. __phoenix_flash__ trasporta messaggi dei redirect per un massimo di 60 secondi. _daily_logos_web_user_remember_me mantiene l'accesso fino a 14 giorni solo se scegli di restare connesso. cc_cookie memorizza le preferenze di consenso per 182 giorni.",
                linkedCategory: "necessary",
              },
              {
                title: "Analytics",
                description:
                  "Cookie facoltativi di Google Analytics come _ga, _ga_<container-id>, _gid e _gat vengono impostati solo dopo il consenso analytics. La durata può variare in base al servizio.",
                linkedCategory: "analytics",
              },
              {
                title: "Funzionalità",
                description:
                  "Questa categoria abilita contenuti esterni incorporati, come Google Forms, dopo il consenso. Il fornitore può impostare propri cookie.",
                linkedCategory: "functionality",
              },
              {
                title: "Maggiori informazioni",
                description:
                  'Leggi la nostra <a href="/it/privacy">Privacy & Cookie Policy</a>.',
              },
            ],
          },
        },
      },
    },
  });

  window.openCookiePreferences = openCookiePreferences;
}
