"use strict";

// Lightweight client-side guardrails. Real enforcement is server-side headers.
(function () {
  if (window.__ibridgeSecurityLoaded) return;
  window.__ibridgeSecurityLoaded = true;

  // Ensure links opened in new tabs are protected.
  document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll("a[target='_blank']").forEach(function (a) {
      const rel = (a.getAttribute("rel") || "").toLowerCase();
      if (!rel.includes("noopener") || !rel.includes("noreferrer")) {
        a.setAttribute("rel", "noopener noreferrer");
      }
    });
  });
})();
