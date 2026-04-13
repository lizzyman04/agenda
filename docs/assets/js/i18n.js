/**
 * AGENDA – PT/EN i18n module
 * Reads locale from localStorage ("agenda-lang"), defaults to "pt".
 * Applies translations to all [data-i18n] elements.
 * Language toggle button (#lang-toggle) switches and persists locale.
 */

const translations = {
  pt: {
    "nav-home": "Início",
    "nav-terms": "Termos",
    "nav-github": "GitHub",
    "nav-contact": "Contato",

    "hero-subtitle": "Seu HQ pessoal para tarefas e finanças — 100% no seu dispositivo.",
    "hero-cta": "Em breve na Play Store",
    "hero-privacy-badge": "\uD83D\uDD12 Privacidade em primeiro lugar",

    "features-title": "Funcionalidades",

    "feat-tasks-title": "Gerenciamento de Tarefas",
    "feat-tasks-desc": "GTD, Regra 1-3-5 e Matriz de Eisenhower integrados. Organize seu dia sem esforço.",

    "feat-finance-title": "Finanças Pessoais",
    "feat-finance-desc": "Acompanhe receitas, despesas, orçamentos e metas de economia em um só lugar.",

    "feat-privacy-title": "Privacidade em Primeiro Lugar",
    "feat-privacy-desc": "Nenhum dado sai do seu dispositivo. Sem servidores, sem nuvem, sem rastreamento.",

    "stack-title": "Tecnologia",

    "footer-terms": "Termos e Privacidade",
    "footer-github": "GitHub",
    "footer-contact": "Contato",

    "lang-toggle-label": "EN",

    // Terms page keys
    "terms-page-title": "Termos de Uso e Políticas de Privacidade",
    "terms-h-what": "O que é?",
    "terms-h-why": "Por que eu devo usar?",
    "terms-h-diff": "Qual é o diferencial desta agenda?",
    "terms-h-cost": "Quanto custa? Tem alguma desvantagem?",
    "terms-h-notif": "Como faço para receber notificações?",
    "terms-h-storage": "Onde são armazenados os meus dados?",
    "terms-h-support": "Sobre o projecto, como apoiar?"
  },

  en: {
    "nav-home": "Home",
    "nav-terms": "Terms",
    "nav-github": "GitHub",
    "nav-contact": "Contact",

    "hero-subtitle": "Your personal HQ for tasks and finances — 100% on your device.",
    "hero-cta": "Coming soon on the Play Store",
    "hero-privacy-badge": "\uD83D\uDD12 Privacy first",

    "features-title": "Features",

    "feat-tasks-title": "Task Management",
    "feat-tasks-desc": "GTD, 1-3-5 Rule, and Eisenhower Matrix built in. Organise your day effortlessly.",

    "feat-finance-title": "Personal Finance",
    "feat-finance-desc": "Track income, expenses, budgets, and savings goals all in one place.",

    "feat-privacy-title": "Privacy First",
    "feat-privacy-desc": "No data leaves your device. No servers, no cloud, no tracking.",

    "stack-title": "Technology",

    "footer-terms": "Terms & Privacy",
    "footer-github": "GitHub",
    "footer-contact": "Contact",

    "lang-toggle-label": "PT",

    // Terms page keys
    "terms-page-title": "Terms of Use and Privacy Policy",
    "terms-h-what": "What is it?",
    "terms-h-why": "Why should I use it?",
    "terms-h-diff": "What makes this app different?",
    "terms-h-cost": "How much does it cost? Are there any drawbacks?",
    "terms-h-notif": "How do I receive notifications?",
    "terms-h-storage": "Where is my data stored?",
    "terms-h-support": "About the project — how to support?"
  }
};

/**
 * Applies the given locale to all [data-i18n] elements on the page.
 * @param {string} locale - "pt" or "en"
 */
function applyLocale(locale) {
  const dict = translations[locale];
  if (!dict) return;

  document.querySelectorAll("[data-i18n]").forEach(function (el) {
    const key = el.getAttribute("data-i18n");
    if (dict[key] !== undefined) {
      el.textContent = dict[key];
    }
  });

  // Update html lang attribute for accessibility
  document.documentElement.setAttribute("lang", locale === "pt" ? "pt" : "en");
}

document.addEventListener("DOMContentLoaded", function () {
  const saved = localStorage.getItem("agenda-lang") || "pt";
  applyLocale(saved);

  const toggleBtn = document.getElementById("lang-toggle");
  if (toggleBtn) {
    toggleBtn.addEventListener("click", function () {
      const current = localStorage.getItem("agenda-lang") || "pt";
      const next = current === "pt" ? "en" : "pt";
      localStorage.setItem("agenda-lang", next);
      applyLocale(next);
    });
  }
});
