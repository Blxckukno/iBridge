/*
  Runtime compatibility fixes:
  - Robust mobile menu toggle across page variants
  - Auto clear localhost service workers/cache once
*/
(function () {
  "use strict";

  function isMainSitePage() {
    var path = (window.location.pathname || "").toLowerCase();
    return path.indexOf("/ticketingsystem/") === -1 && path.indexOf("/intranet/") === -1;
  }

  function getRequiredMainTabs() {
    return [
      { href: "index.html", label: "Home" },
      { href: "about.html", label: "About" },
      { href: "services.html", label: "Services" },
      { href: "team.html", label: "Our Team" },
      { href: "careers.html", label: "Careers" },
      { href: "contact.html", label: "Contact" },
      { href: "staff-login.html", label: "Staff Portal" }
    ];
  }

  function currentPageFile() {
    var path = (window.location.pathname || "").replace(/\\/g, "/").toLowerCase();
    var parts = path.split("/");
    var file = parts[parts.length - 1] || "index.html";
    if (!file || file === "") return "index.html";
    return file;
  }

  function isHomeFile(fileName) {
    return fileName === "index.html" || fileName === "home.html" || fileName === "";
  }

  function enforceMainSiteTabs() {
    if (!isMainSitePage()) return;
    var requiredTabs = getRequiredMainTabs();

    var current = currentPageFile();
    var candidates = document.querySelectorAll("header ul, .header ul, nav ul, .nav-menu, .main-menu");

    candidates.forEach(function (list) {
      if (!list || list.classList.contains("sidebar-nav")) return;
      if (list.closest(".sidebar, aside, .dashboard-container")) return;
      if (!(list.closest("header") || list.closest(".header") || list.closest("nav"))) return;

      var existingLinks = Array.prototype.map.call(list.querySelectorAll("a[href]"), function (a) {
        return (a.getAttribute("href") || "").toLowerCase();
      });
      var looksLikeMainNav = existingLinks.some(function (href) {
        return /(index|home|about|services|team|careers|contact|staff|portal|login)/.test(href);
      });
      if (!looksLikeMainNav) return;

      list.innerHTML = "";
      requiredTabs.forEach(function (tab) {
        var li = document.createElement("li");
        var a = document.createElement("a");
        a.href = tab.href;
        a.textContent = tab.label;
        a.className = "nav-link";

        li.appendChild(a);
        list.appendChild(li);
      });
    });
  }

  function ensureMainSiteFallbackNav() {
    if (!isMainSitePage()) return;
    if (document.getElementById("runtime-main-tabs")) return;

    var tabs = getRequiredMainTabs();
    var linkHrefs = Array.prototype.map.call(document.querySelectorAll("a[href]"), function (a) {
      return (a.getAttribute("href") || "").toLowerCase();
    });
    var hasMainTabs = tabs.filter(function (tab) {
      return linkHrefs.indexOf(tab.href.toLowerCase()) !== -1;
    }).length >= 4;
    if (hasMainTabs) return;

    var current = currentPageFile();
    var nav = document.createElement("nav");
    nav.id = "runtime-main-tabs";
    nav.setAttribute("aria-label", "Main site navigation");
    nav.innerHTML = [
      "<ul>",
      tabs.map(function (tab) {
        return '<li><a href="' + tab.href + '">' + tab.label + "</a></li>";
      }).join(""),
      "</ul>"
    ].join("");

    var style = document.createElement("style");
    style.textContent = [
      "#runtime-main-tabs {",
      "  position: fixed;",
      "  top: 0;",
      "  left: 0;",
      "  right: 0;",
      "  z-index: 2500;",
      "  background: #ffffff;",
      "  border-bottom: 1px solid #dbe3ec;",
      "  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.08);",
      "}",
      "#runtime-main-tabs ul {",
      "  list-style: none;",
      "  margin: 0;",
      "  padding: 10px 12px;",
      "  display: flex;",
      "  gap: 8px;",
      "  justify-content: center;",
      "  flex-wrap: wrap;",
      "}",
      "#runtime-main-tabs a {",
      "  display: inline-block;",
      "  text-decoration: none;",
      "  color: #243b53;",
      "  font-weight: 600;",
      "  padding: 6px 10px;",
      "  border-radius: 8px;",
      "}",
      "#runtime-main-tabs a:hover { background: #f1f5f9; }",
      "body { padding-top: 58px !important; }",
      "@media (max-width: 480px) {",
      "  #runtime-main-tabs ul { justify-content: flex-start; overflow-x: auto; white-space: nowrap; flex-wrap: nowrap; }",
      "  #runtime-main-tabs li { flex: 0 0 auto; }",
      "}"
    ].join("\n");
    document.head.appendChild(style);

    if (document.body.firstChild) {
      document.body.insertBefore(nav, document.body.firstChild);
    } else {
      document.body.appendChild(nav);
    }
  }

  function setupMobileMenu() {
    var menuToggle =
      document.getElementById("mobile-menu-toggle") ||
      document.getElementById("mobileMenuBtn") ||
      document.querySelector(".mobile-menu-toggle") ||
      document.querySelector(".mobile-menu-btn");

    var menu =
      document.getElementById("nav-menu") ||
      document.getElementById("mainMenu") ||
      document.querySelector(".nav-menu") ||
      document.querySelector(".mobile-nav");

    if (!menuToggle || !menu) return;

    if (!menu.id) menu.id = "runtime-mobile-menu";
    menuToggle.setAttribute("aria-controls", menu.id);
    if (!menuToggle.hasAttribute("aria-expanded")) menuToggle.setAttribute("aria-expanded", "false");

    // Ensure mobile panel is visible when active on small screens.
    var style = document.createElement("style");
    style.textContent = [
      "@media (max-width: 900px) {",
      "  .nav-menu.active, #mainMenu.show, .mobile-nav.show, #runtime-mobile-menu.active {",
      "    display: flex !important;",
      "    visibility: visible !important;",
      "    opacity: 1 !important;",
      "    z-index: 2000 !important;",
      "  }",
      "}",
    ].join("\n");
    document.head.appendChild(style);

    function openMenu() {
      menu.classList.add("active");
      menu.classList.add("show");
      menuToggle.classList.add("active");
      menuToggle.setAttribute("aria-expanded", "true");
    }

    function closeMenu() {
      menu.classList.remove("active");
      menu.classList.remove("show");
      menuToggle.classList.remove("active");
      menuToggle.setAttribute("aria-expanded", "false");
    }

    menuToggle.addEventListener("click", function (e) {
      e.preventDefault();
      e.stopPropagation();
      var expanded = menuToggle.getAttribute("aria-expanded") === "true";
      if (expanded) closeMenu();
      else openMenu();
    });

    document.addEventListener("click", function (e) {
      if (!menu.contains(e.target) && !menuToggle.contains(e.target)) closeMenu();
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") closeMenu();
    });

    window.addEventListener("resize", function () {
      if (window.innerWidth > 900) closeMenu();
    });
  }

  function normalizeNavbarUI() {
    var style = document.createElement("style");
    style.textContent = [
      ":root { --nav-height: 76px; }",
      "header, .header {",
      "  min-height: var(--nav-height) !important;",
      "  background: #ffffff !important;",
      "  border-bottom: 1px solid #e2e8f0 !important;",
      "  box-shadow: 0 6px 20px rgba(15, 23, 42, 0.08) !important;",
      "}",
      ".header .container, header .container, .header-container {",
      "  display: flex !important;",
      "  align-items: center !important;",
      "  justify-content: space-between !important;",
      "  gap: 18px !important;",
      "}",
      ".logo img, .brand-logo img, .logo-image {",
      "  height: 44px !important;",
      "  width: auto !important;",
      "  max-width: 180px !important;",
      "  object-fit: contain !important;",
      "  background: transparent !important;",
      "  padding: 0 !important;",
      "  border-radius: 0 !important;",
      "  border: 0 !important;",
      "  display: block !important;",
      "}",
      ".nav-menu, .main-menu, .mobile-nav {",
      "  list-style: none !important;",
      "  margin: 0 !important;",
      "  padding: 0 !important;",
      "}",
      ".nav-link, .nav-menu a, .main-menu a, .mobile-nav a {",
      "  font-weight: 600 !important;",
      "  color: #243b53 !important;",
      "  text-decoration: none !important;",
      "}",
      ".mobile-menu-toggle, .mobile-menu-btn {",
      "  width: 44px !important;",
      "  height: 44px !important;",
      "  border: 1px solid #cbd5e1 !important;",
      "  border-radius: 10px !important;",
      "  background: #ffffff !important;",
      "}",
      "@media (max-width: 900px) {",
      "  .nav-menu, .main-menu, .mobile-nav {",
      "    position: absolute !important;",
      "    top: calc(var(--nav-height) - 2px) !important;",
      "    left: 12px !important;",
      "    right: 12px !important;",
      "    background: #ffffff !important;",
      "    border: 1px solid #dbe3ec !important;",
      "    border-radius: 12px !important;",
      "    box-shadow: 0 16px 34px rgba(15, 23, 42, 0.18) !important;",
      "    padding: 8px !important;",
      "    z-index: 2100 !important;",
      "    max-height: min(72vh, 520px) !important;",
      "    overflow-y: auto !important;",
      "  }",
      "  .nav-menu li, .main-menu li, .mobile-nav li { width: 100% !important; }",
      "  .nav-link, .nav-menu a, .main-menu a, .mobile-nav a {",
      "    display: block !important;",
      "    padding: 12px 14px !important;",
      "    border-radius: 8px !important;",
      "  }",
      "  .nav-link:hover, .nav-menu a:hover, .main-menu a:hover, .mobile-nav a:hover {",
      "    background: #f1f5f9 !important;",
      "  }",
      "  .nav-menu:not(.active):not(.show), .main-menu:not(.active):not(.show), .mobile-nav:not(.active):not(.show) {",
      "    display: none !important;",
      "  }",
      "}",
    ].join("\n");
    document.head.appendChild(style);
  }

  function enforceLogoFallback() {
    var logoPath = window.location.pathname.includes("/TicketingSystem/frontend/")
      ? "../../images/iBridge_Logo-removebg-preview.png"
      : "images/iBridge_Logo-removebg-preview.png";

    var logos = document.querySelectorAll("img[src*='logo'], .logo img, .brand-logo img");
    logos.forEach(function (img) {
      img.addEventListener("error", function () {
        img.src = logoPath;
      });
      if (img.complete && img.naturalWidth === 0) {
        img.src = logoPath;
      }
    });
  }

  function enforceFaviconLogo() {
    var cacheBust = "?v=20260224-favicon-transparent";
    var base = window.location.pathname.includes("/TicketingSystem/frontend/")
      ? "../../images/"
      : window.location.pathname.includes("/intranet/")
        ? "../images/"
        : "images/";

    var iconSpecs = [
      { rel: "icon", href: base + "favicon.png" + cacheBust, type: "image/png" },
      { rel: "shortcut icon", href: base + "favicon.ico" + cacheBust, type: "image/x-icon" },
      { rel: "apple-touch-icon", href: base + "apple-touch-icon.png" + cacheBust, type: "image/png" }
    ];

    iconSpecs.forEach(function (spec) {
      var selector = "link[rel='" + spec.rel + "']";
      var link = document.querySelector(selector);
      if (!link) {
        link = document.createElement("link");
        link.rel = spec.rel;
        document.head.appendChild(link);
      }
      link.href = spec.href;
      if (spec.type) link.type = spec.type;
    });
  }

  function ensureImageOptimizationCss() {
    var hrefs = Array.prototype.map.call(document.querySelectorAll("link[rel='stylesheet']"), function (l) {
      return l.getAttribute("href") || "";
    });
    var already = hrefs.some(function (h) { return h.indexOf("image-optimization.css") !== -1; });
    if (already) return;
    var path = window.location.pathname.includes("/TicketingSystem/frontend/")
      ? "../../css/image-optimization.css"
      : window.location.pathname.includes("/intranet/")
        ? "../css/image-optimization.css"
        : "css/image-optimization.css";
    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = path;
    document.head.appendChild(link);
  }

  function ensureFontAwesomeAndFallback() {
    var cssBase = window.location.pathname.includes("/TicketingSystem/frontend/")
      ? "../../css/"
      : window.location.pathname.includes("/intranet/")
        ? "../css/"
        : "css/";

    var fallbackHref = cssBase + "icon-fallback.css";
    var faHref = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css";

    function addFallbackCss() {
      if (!document.querySelector("link[data-icon-fallback='1']")) {
        var fallback = document.createElement("link");
        fallback.rel = "stylesheet";
        fallback.href = fallbackHref;
        fallback.setAttribute("data-icon-fallback", "1");
        document.head.appendChild(fallback);
      }
      document.documentElement.classList.add("no-fa-icons");
    }

    var faLink = Array.prototype.find.call(
      document.querySelectorAll("link[rel='stylesheet']"),
      function (l) {
        return (l.href || "").indexOf("font-awesome") !== -1;
      }
    );

    if (!faLink) {
      faLink = document.createElement("link");
      faLink.rel = "stylesheet";
      faLink.href = faHref;
      faLink.setAttribute("data-fa-runtime", "1");
      document.head.appendChild(faLink);
    }

    var done = false;
    function verifyAndFallback() {
      if (done) return;
      done = true;
      var probe = document.createElement("i");
      probe.className = "fas fa-bars";
      probe.style.position = "absolute";
      probe.style.left = "-9999px";
      probe.style.top = "-9999px";
      document.body.appendChild(probe);
      var family = "";
      try {
        family = window.getComputedStyle(probe, "::before").fontFamily || "";
      } catch (e) {
        family = "";
      }
      probe.remove();
      if (!/Font Awesome/i.test(family)) addFallbackCss();
    }

    faLink.addEventListener("error", addFallbackCss);
    faLink.addEventListener("load", function () {
      setTimeout(verifyAndFallback, 100);
    });
    setTimeout(verifyAndFallback, 2500);
  }

  function getImagesBasePath() {
    if (window.location.pathname.includes("/TicketingSystem/frontend/")) return "../../images/";
    if (window.location.pathname.includes("/intranet/")) return "../images/";
    return "images/";
  }

  function buildImageFallbackCandidates(src) {
    if (!src || /^(https?:|data:|blob:|\/\/)/i.test(src)) return [];
    var normalized = src.replace(/\\/g, "/");
    var noLeading = normalized.replace(/^\.?\//, "");
    var noWebsitePrefix = noLeading.replace(/^website\//i, "");
    var onlyAfterImages = noWebsitePrefix.indexOf("images/") >= 0
      ? noWebsitePrefix.substring(noWebsitePrefix.indexOf("images/") + "images/".length)
      : noWebsitePrefix;

    var list = [
      normalized,
      "./" + noLeading,
      "/" + noLeading,
      "/Website/" + noWebsitePrefix,
      "images/" + onlyAfterImages,
      "/images/" + onlyAfterImages,
      "/Website/images/" + onlyAfterImages
    ];

    return list.filter(function (value, index, arr) {
      return value && arr.indexOf(value) === index;
    });
  }

  function replaceLowQualityImages() {
    var base = getImagesBasePath();
    var map = {
      "about-image.jpg": "generated-hq/about-team-african.png",
      "service-1.jpg": "generated-hq/bpo-operations-african.png",
      "service-2.jpg": "generated-hq/client-interaction-african.png",
      "service-3.jpg": "generated-hq/it-support-african.png",
      "team-member-1.jpg": "generated-hq/team-member-1-african.png",
      "team-member-2.jpg": "generated-hq/team-member-2-african.png",
      "team-member-3.jpg": "generated-hq/team-member-3-african.png",
      "team-member-4.jpg": "generated-hq/team-member-4-african.png",
      "team-member-5.jpg": "generated-hq/team-member-5-african.png",
      "team-member-6.jpg": "generated-hq/team-member-6-african.png",
      "placeholder1.jpg": "generated-hq/contact-agent-african.png",
      "placeholder2.jpg": "generated-hq/lms-learning-african.png",
      "placeholder3.jpg": "generated-hq/intranet-collab-african.png",
      "gallery/team-1.jpg": "generated-hq/team-member-1-african.png",
      "gallery/team-2.jpg": "generated-hq/team-member-2-african.png",
      "gallery/culture-1.jpg": "generated-hq/about-team-african.png",
      "gallery/culture-2.jpg": "generated-hq/client-interaction-african.png",
      "gallery/workspace-1.jpg": "generated-hq/intranet-collab-african.png",
      "gallery/workspace-2.jpg": "generated-hq/ai-automation-african.png",
      "ibridge-og-image.jpg": "generated-hq/og-african-customer-support.png"
    };

    var images = document.querySelectorAll("img[src]");
    images.forEach(function (img) {
      var src = img.getAttribute("src") || "";
      var normalized = src.replace(/\\/g, "/");
      Object.keys(map).forEach(function (key) {
        if (normalized.endsWith(key) || normalized.indexOf("/" + key) !== -1) {
          img.src = base + map[key];
          img.loading = img.loading || "lazy";
          img.decoding = "async";
          img.fetchPriority = img.fetchPriority || "auto";
        }
      });
    });
  }

  function forceRefreshManagedImages() {
    var images = document.querySelectorAll("img[src]");
    var stamp = "v=20260220a";
    images.forEach(function (img) {
      var src = img.getAttribute("src") || "";
      if (!src) return;
      if (
        src.indexOf("images/generated/") === -1 &&
        src.indexOf("images/generated-hq/") === -1 &&
        src.indexOf("iBridge_Logo-removebg-preview.png") === -1
      ) {
        return;
      }
      if (src.indexOf("v=") !== -1) return;
      img.setAttribute("src", src + (src.indexOf("?") === -1 ? "?" : "&") + stamp);
    });
  }

  function forceLazyImagesVisible() {
    var lazyImages = document.querySelectorAll("img.lazy-image");
    lazyImages.forEach(function (img) {
      img.classList.add("loaded");
      img.style.opacity = "1";
      img.style.visibility = "visible";
      img.style.display = img.style.display || "block";
      if (img.complete && img.naturalWidth === 0) {
        img.dispatchEvent(new Event("error"));
      }
      img.addEventListener("load", function () {
        img.classList.add("loaded");
        img.style.opacity = "1";
      });
    });
  }
  function enforceImageAttributes() {
    var allImages = document.querySelectorAll("img");
    allImages.forEach(function (img) {
      if (!img.getAttribute("decoding")) img.setAttribute("decoding", "async");
      if (!img.getAttribute("loading")) img.setAttribute("loading", "lazy");
      if (img.closest(".hero, .above-fold, .header, .main-banner")) {
        img.setAttribute("fetchpriority", "high");
      }
      if (!img.style.objectFit && img.classList.contains("logo-optimized")) {
        img.style.objectFit = "contain";
      }
    });
  }

  function enforceImageFallbackPaths() {
    var allImages = document.querySelectorAll("img[src]");
    allImages.forEach(function (img) {
      var originalSrc = img.getAttribute("src") || "";
      var candidates = buildImageFallbackCandidates(originalSrc);
      if (!candidates.length) return;

      var attempts = 0;
      img.addEventListener("error", function () {
        attempts += 1;
        if (attempts >= candidates.length) return;
        var next = candidates[attempts];
        if (next && img.getAttribute("src") !== next) {
          img.setAttribute("src", next);
        }
      });
    });
  }

  function applyResponsiveSrcset() {
    var allImages = document.querySelectorAll("img[src*='generated-hq/']");
    allImages.forEach(function (img) {
      if (img.getAttribute("srcset")) return;
      var src = img.getAttribute("src") || "";
      if (!/\.png($|\?)/i.test(src)) return;

      var base = src.replace(/\.png($|\?)/i, "");
      var srcset = [
        base + "-480w.png 480w",
        base + "-640w.png 640w",
        base + "-960w.png 960w",
        src + " 1024w",
      ].join(", ");
      img.setAttribute("srcset", srcset);
      if (!img.getAttribute("sizes")) {
        img.setAttribute("sizes", "(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 1024px");
      }
    });
  }

  function applyGeneratedImagePolish() {
    var style = document.createElement("style");
    style.textContent = [
      ".image-container::before { content: none !important; display: none !important; }",
      ".image-container img { position: relative !important; top: auto !important; left: auto !important; }",
      "img { position: relative !important; z-index: 1; }",
      ".lazy-image { opacity: 1 !important; visibility: visible !important; animation: none !important; background: none !important; }",
      ".lazy-image.loaded { opacity: 1 !important; }",
      "img[src*='images/generated/'], img[src*='images/generated-hq/'] {",
      "  display: block !important;",
      "  max-width: 100% !important;",
      "  height: auto !important;",
      "  border: 0 !important;",
      "  border-radius: 14px !important;",
      "  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.16) !important;",
      "  background: transparent !important;",
      "  object-fit: cover !important;",
      "  image-rendering: auto !important;",
      "  -webkit-transform: translateZ(0);",
      "  transform: translateZ(0);",
      "  -webkit-backface-visibility: hidden;",
      "  backface-visibility: hidden;",
    "}",
      ".image-container,",
      ".about-image,",
      ".service-card {",
      "  overflow: hidden;",
      "  border-radius: 14px;",
      "}",
      ".service-item img, .service-card img, .about-image img, .gallery-item img, .blog-post img {",
      "  width: 100% !important;",
      "  height: auto !important;",
      "  max-height: 100% !important;",
      "  object-fit: cover !important;",
      "}",
      ".team-member img {",
      "  width: 100% !important;",
      "  max-width: 220px !important;",
      "  aspect-ratio: 1 / 1 !important;",
      "  height: auto !important;",
      "  object-fit: cover !important;",
      "}",
      "@media (max-width: 768px) {",
      "  img[src*='images/generated/'], img[src*='images/generated-hq/'] {",
      "    border-radius: 12px !important;",
      "  }",
      "}",
    ].join("\n");
    document.head.appendChild(style);
  }

  function upgradeHeroBackground() {
    var hero = document.querySelector(".hero");
    if (!hero) return;
    var computed = window.getComputedStyle(hero).backgroundImage || "";
    if (computed.indexOf("hero-bg.jpg") === -1) return;
    var base = getImagesBasePath();
    var fallback = base + "generated-hq/og-african-customer-support.png";
    hero.style.backgroundImage =
      "linear-gradient(rgba(11, 31, 51, 0.72), rgba(11, 31, 51, 0.72)), url('" + fallback + "')";
    hero.style.backgroundSize = "cover";
    hero.style.backgroundPosition = "center";
  }

  async function clearLocalhostCachesOnce() {
    var host = window.location.hostname || "";
    var isLocal =
      host === "localhost" ||
      host === "127.0.0.1" ||
      /^192\.168\./.test(host) ||
      /^10\./.test(host) ||
      /^172\.(1[6-9]|2\d|3[0-1])\./.test(host);
    if (!isLocal) return;

    var markKey = "ibridge_runtime_cache_fix_v1";
    if (sessionStorage.getItem(markKey) === "1") return;
    sessionStorage.setItem(markKey, "1");

    try {
      if ("serviceWorker" in navigator) {
        var regs = await navigator.serviceWorker.getRegistrations();
        await Promise.all(regs.map(function (r) { return r.unregister(); }));
      }
      if ("caches" in window) {
        var keys = await caches.keys();
        await Promise.all(keys.map(function (k) { return caches.delete(k); }));
      }
      // Single reload after cleanup.
      if (!window.location.search.includes("cachefix=1")) {
        var joiner = window.location.search ? "&" : "?";
        window.location.replace(window.location.href + joiner + "cachefix=1");
      }
    } catch (err) {
      console.warn("runtime-fix cache cleanup warning:", err);
    }
  }

  document.addEventListener("DOMContentLoaded", function () {
    normalizeNavbarUI();
    enforceMainSiteTabs();
    ensureMainSiteFallbackNav();
    ensureImageOptimizationCss();
    ensureFontAwesomeAndFallback();
    setupMobileMenu();
    enforceLogoFallback();
    enforceFaviconLogo();
    replaceLowQualityImages();
    forceRefreshManagedImages();
    enforceImageAttributes();
    forceLazyImagesVisible();
    enforceImageFallbackPaths();
    applyResponsiveSrcset();
    applyGeneratedImagePolish();
    upgradeHeroBackground();
    clearLocalhostCachesOnce();
  });
})();








