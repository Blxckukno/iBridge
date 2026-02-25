(function () {
  "use strict";

  var STAFF_SESSION_KEY = "ibridge_staff_session";
  var TTL_HOURS = 12;
  var ALLOWED_ROLES = [
    "dev", "admin", "supervisor", "agent", "student",
    "developer", "devops", "security", "it", "manager",
    "employee", "staff", "learner"
  ];

  function normalizeRole(role) {
    var r = String(role || "").toLowerCase().trim();
    if (!r) return "agent";
    if (["developer", "devops", "it", "security"].indexOf(r) >= 0) return "dev";
    if (r === "manager") return "supervisor";
    if (r === "learner") return "student";
    if (["employee", "staff"].indexOf(r) >= 0) return "agent";
    return r;
  }

  function readSession() {
    try {
      return JSON.parse(sessionStorage.getItem(STAFF_SESSION_KEY) || "null");
    } catch (e) {
      return null;
    }
  }

  function isValidSession(data) {
    if (!data || !data.ts) return false;
    var ageMs = Date.now() - Number(data.ts || 0);
    return ageMs >= 0 && ageMs < TTL_HOURS * 60 * 60 * 1000;
  }

  function hasAllowedRole(data) {
    var role = normalizeRole((data && data.role) || "");
    if (!role) return true;
    return ALLOWED_ROLES.indexOf(role) >= 0;
  }

  function redirectToLogin() {
    var current = window.location.pathname + window.location.search;
    window.location.replace("/staff-login.html?next=" + encodeURIComponent(current));
  }

  window.iBridgeStaffAuth = {
    setSession: function (payload) {
      var safe = payload || {};
      safe.role = normalizeRole(safe.role);
      safe.ts = Date.now();
      sessionStorage.setItem(STAFF_SESSION_KEY, JSON.stringify(safe));
    },
    clearSession: function () {
      sessionStorage.removeItem(STAFF_SESSION_KEY);
    },
    ensureAccess: function () {
      var session = readSession();
      if (!isValidSession(session) || !hasAllowedRole(session)) {
        redirectToLogin();
        return false;
      }
      return true;
    }
  };
})();

