/* Dynamic main-site blocks: case studies, testimonials, trust metrics */
(function () {
  "use strict";

  function createEl(tag, className, html) {
    var el = document.createElement(tag);
    if (className) el.className = className;
    if (typeof html === "string") el.innerHTML = html;
    return el;
  }

  function buildApiCandidates(path) {
    var cleanPath = String(path || "");
    if (cleanPath.indexOf("http://") === 0 || cleanPath.indexOf("https://") === 0) return [cleanPath];
    var out = [cleanPath];
    try {
      var loc = window.location;
      if (loc && String(loc.port || "") !== "5000") {
        out.push(loc.protocol + "//" + loc.hostname + ":5000" + cleanPath);
      }
    } catch (e) {}
    out.push("http://localhost:5000" + cleanPath);
    return out;
  }

  async function fetchJson(path) {
    var candidates = buildApiCandidates(path);
    var lastErr = null;
    for (var i = 0; i < candidates.length; i += 1) {
      try {
        var res = await fetch(candidates[i], { headers: { Accept: "application/json" } });
        if (!res.ok) throw new Error("HTTP " + res.status);
        return await res.json();
      } catch (err) {
        lastErr = err;
      }
    }
    throw lastErr || new Error("API unavailable");
  }

  function ensureDynamicRoot() {
    var root = document.getElementById("dynamic-professional-sections");
    if (root) return root;

    var main = document.querySelector("main") || document.body;
    root = createEl("section", "section dynamic-professional-sections");
    root.id = "dynamic-professional-sections";
    main.appendChild(root);
    return root;
  }

  function renderStats(root) {
    var section = createEl("div", "dynamic-block");
    section.innerHTML =
      '<div class="section-header">' +
      '<h2>Operational Trust Signals</h2>' +
      "<p>Visible reliability measures built into delivery and support operations.</p>" +
      "</div>" +
      '<div class="dynamic-grid dynamic-grid-4">' +
      '<article class="dynamic-card"><h3>24/7</h3><p>Support coverage windows</p></article>' +
      '<article class="dynamic-card"><h3>10+</h3><p>Years operational experience</p></article>' +
      '<article class="dynamic-card"><h3>SLA</h3><p>Measured and reportable response targets</p></article>' +
      '<article class="dynamic-card"><h3>Secure</h3><p>Hardened API and audit endpoints</p></article>' +
      "</div>";
    root.appendChild(section);
  }

  function renderCaseStudies(root, items) {
    if (!items || !items.length) return;
    var published = items.filter(function (x) { return x && x.published !== false; }).slice(0, 3);
    if (!published.length) return;

    var section = createEl("div", "dynamic-block");
    section.innerHTML =
      '<div class="section-header">' +
      "<h2>Case Studies</h2>" +
      "<p>Measured outcomes from service improvement programs.</p>" +
      "</div>";

    var grid = createEl("div", "dynamic-grid dynamic-grid-3");
    published.forEach(function (item) {
      var card = createEl(
        "article",
        "dynamic-card",
        "<h3>" + (item.title || "Case Study") + "</h3>" +
          '<p class="meta">' + (item.client || "") + (item.industry ? " | " + item.industry : "") + "</p>" +
          "<p><strong>Challenge:</strong> " + (item.challenge || "N/A") + "</p>" +
          "<p><strong>Solution:</strong> " + (item.solution || "N/A") + "</p>" +
          "<p><strong>Result:</strong> " + (item.result || "N/A") + "</p>" +
          (item.metric_value
            ? '<div class="metric-chip">' + (item.metric_label || "Metric") + ": " + item.metric_value + "</div>"
            : "")
      );
      grid.appendChild(card);
    });
    section.appendChild(grid);
    root.appendChild(section);
  }

  function renderTestimonials(root, items) {
    if (!items || !items.length) return;
    var published = items.filter(function (x) { return x && x.published !== false; }).slice(0, 3);
    if (!published.length) return;

    var section = createEl("div", "dynamic-block");
    section.innerHTML =
      '<div class="section-header">' +
      "<h2>Client Testimonials</h2>" +
      "<p>Feedback from teams using iBridge delivery services.</p>" +
      "</div>";

    var grid = createEl("div", "dynamic-grid dynamic-grid-3");
    published.forEach(function (item) {
      var rating = Math.max(1, Math.min(5, Number(item.rating || 5)));
      var stars = "★★★★★".slice(0, rating);
      var card = createEl(
        "article",
        "dynamic-card",
        '<p class="quote">"' + (item.quote || "Excellent service execution.") + '"</p>' +
          '<p class="meta">' + (item.name || "Client") + " | " + (item.role || "") + "</p>" +
          '<p class="meta">' + (item.company || "") + "</p>" +
          '<p class="stars" aria-label="Rating">' + stars + "</p>"
      );
      grid.appendChild(card);
    });
    section.appendChild(grid);
    root.appendChild(section);
  }

  async function initDynamicMainSections() {
    try {
      var root = ensureDynamicRoot();
      renderStats(root);

      var [caseStudies, testimonials] = await Promise.all([
        fetchJson("/api/cms/case-studies"),
        fetchJson("/api/cms/testimonials")
      ]);

      renderCaseStudies(root, caseStudies.items || []);
      renderTestimonials(root, testimonials.items || []);
    } catch (err) {
      // Keep site functional even if API is unavailable.
      console.warn("Dynamic sections unavailable:", err && err.message ? err.message : err);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initDynamicMainSections);
  } else {
    initDynamicMainSections();
  }
})();
