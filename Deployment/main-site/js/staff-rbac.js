(function () {
  "use strict";

  var SESSION_KEY = "ibridge_staff_session";

  var ROLE_RANK = {
    student: 1,
    agent: 2,
    supervisor: 3,
    admin: 4,
    dev: 5
  };

  function readSession() {
    try {
      return JSON.parse(sessionStorage.getItem(SESSION_KEY) || "null");
    } catch (e) {
      return null;
    }
  }

  function normalizeRole(rawRole) {
    var role = String(rawRole || "").toLowerCase().trim();
    if (!role) return "agent";
    if (["dev", "developer", "devops", "it", "security"].indexOf(role) >= 0) return "dev";
    if (["admin"].indexOf(role) >= 0) return "admin";
    if (["supervisor", "manager", "teamlead", "team-lead", "lead"].indexOf(role) >= 0) return "supervisor";
    if (["student", "learner"].indexOf(role) >= 0) return "student";
    if (["agent", "employee", "staff", "support"].indexOf(role) >= 0) return "agent";
    return "agent";
  }

  function getRoleRank(role) {
    return ROLE_RANK[normalizeRole(role)] || 0;
  }

  function hasMinRole(currentRole, minRole) {
    return getRoleRank(currentRole) >= getRoleRank(minRole);
  }

  function defaultDashboardForRole(role) {
    var r = normalizeRole(role);
    var base = "/TicketingSystem/frontend/";
    if (r === "dev") return base + "dev-dashboard.html";
    if (r === "admin") return base + "admin-dashboard.html";
    if (r === "supervisor") return base + "supervisor-dashboard.html";
    if (r === "student") return base + "student-dashboard.html";
    return base + "agent-dashboard.html";
  }

  function enforcePageAccess(minRole) {
    var session = readSession();
    var role = normalizeRole(session && session.role);
    if (!hasMinRole(role, minRole)) {
      window.location.replace(defaultDashboardForRole(role));
      return false;
    }
    return true;
  }

  function enforceStudentOnlyLms() {
    var session = readSession();
    var role = normalizeRole(session && session.role);
    if (role !== "student") return true;
    var path = window.location.pathname.toLowerCase();
    var allowed = path.indexOf("/lms-platform.html") >= 0 ||
      path.indexOf("/ticketingsystem/frontend/student-dashboard.html") >= 0;
    if (!allowed) {
      window.location.replace(defaultDashboardForRole(role));
      return false;
    }
    return true;
  }

  function roleCapabilities(role) {
    var r = normalizeRole(role);
    var caps = {
      dashboard: true,
      tickets: false,
      reports: false,
      user_management: false,
      export_data: false,
      settings: false,
      security_attacks: false,
      lms: false,
      intranet: false
    };

    if (r === "dev") {
      caps.tickets = true;
      caps.reports = true;
      caps.user_management = true;
      caps.export_data = true;
      caps.settings = true;
      caps.security_attacks = true;
      caps.lms = true;
      caps.intranet = true;
      return caps;
    }
    if (r === "admin") {
      caps.tickets = true;
      caps.reports = true;
      caps.user_management = true;
      caps.export_data = true;
      caps.settings = true;
      caps.lms = true;
      caps.intranet = true;
      return caps;
    }
    if (r === "supervisor") {
      caps.tickets = true;
      caps.reports = true;
      caps.export_data = true;
      caps.lms = true;
      caps.intranet = true;
      return caps;
    }
    if (r === "agent") {
      caps.tickets = true;
      caps.lms = true;
      caps.intranet = true;
      return caps;
    }
    if (r === "student") {
      caps.lms = true;
      return caps;
    }
    return caps;
  }

  window.iBridgeRBAC = {
    readSession: readSession,
    normalizeRole: normalizeRole,
    hasMinRole: hasMinRole,
    getRoleRank: getRoleRank,
    defaultDashboardForRole: defaultDashboardForRole,
    enforcePageAccess: enforcePageAccess,
    enforceStudentOnlyLms: enforceStudentOnlyLms,
    roleCapabilities: roleCapabilities
  };
})();

