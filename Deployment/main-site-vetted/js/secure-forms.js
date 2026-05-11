"use strict";

// Basic input hardening for front-end forms.
(function () {
  function sanitizeValue(value) {
    return String(value)
      .replace(/<\s*script/gi, "")
      .replace(/javascript:/gi, "")
      .replace(/\son\w+\s*=/gi, "");
  }

  document.addEventListener("submit", function (event) {
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;

    const fields = form.querySelectorAll("input, textarea");
    fields.forEach(function (field) {
      if ("value" in field && typeof field.value === "string") {
        field.value = sanitizeValue(field.value);
      }
    });
  });
})();
