const http = require("http");
const fs = require("fs");
const path = require("path");
const url = require("url");

const PORT = 8080;
const WEBSITE_ROOT = path.join(__dirname, "Website");

// MIME types for different file extensions
const mimeTypes = {
  ".html": "text/html",
  ".css": "text/css",
  ".js": "application/javascript",
  ".json": "application/json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".gif": "image/gif",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".eot": "application/vnd.ms-fontobject",
};

function setSecurityHeaders(res, contentType = "application/octet-stream") {
  const csp = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com https://www.googletagmanager.com https://www.google-analytics.com",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com",
    "img-src 'self' data: blob: https:",
    "font-src 'self' data: https://fonts.gstatic.com",
    "connect-src 'self' https://www.google-analytics.com https://www.googletagmanager.com https://www.google.com https://maps.googleapis.com https://www.openstreetmap.org",
    "frame-src 'self' https://www.google.com https://maps.google.com https://www.openstreetmap.org",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
  ].join("; ");

  res.setHeader("Content-Type", contentType);
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  res.setHeader(
    "Permissions-Policy",
    "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
  );
  res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
  res.setHeader("Cross-Origin-Resource-Policy", "same-origin");
  res.setHeader("Content-Security-Policy", csp);
}

const server = http.createServer((req, res) => {
  if (!["GET", "HEAD", "OPTIONS"].includes(req.method)) {
    setSecurityHeaders(res, "text/plain; charset=utf-8");
    res.writeHead(405);
    res.end("Method not allowed");
    return;
  }

  if (req.method === "OPTIONS") {
    setSecurityHeaders(res, "text/plain; charset=utf-8");
    res.writeHead(204);
    res.end();
    return;
  }

  let pathname = url.parse(req.url).pathname;
  let decodedPath = "";
  try {
    decodedPath = decodeURIComponent(pathname || "");
  } catch (e) {
    setSecurityHeaders(res, "text/plain; charset=utf-8");
    res.writeHead(400);
    res.end("Bad request");
    return;
  }

  const suspiciousPathPattern =
    /(\.\.|%2e%2e|<script|javascript:|onerror=|onload=)/i;
  if (suspiciousPathPattern.test(decodedPath)) {
    console.warn(
      `[SECURITY] Blocked suspicious path from ${req.socket.remoteAddress}: ${decodedPath}`,
    );
    setSecurityHeaders(res, "text/plain; charset=utf-8");
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  // Default to index.html for root path
  if (pathname === "/") {
    pathname = "/index.html";
  }

  const filePath = path.resolve(WEBSITE_ROOT, `.${pathname}`);

  // Security check - prevent directory traversal
  if (!filePath.startsWith(WEBSITE_ROOT)) {
    setSecurityHeaders(res, "text/plain; charset=utf-8");
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      if (err.code === "ENOENT") {
        setSecurityHeaders(res, "text/plain; charset=utf-8");
        res.writeHead(404);
        res.end("File not found");
      } else {
        setSecurityHeaders(res, "text/plain; charset=utf-8");
        res.writeHead(500);
        res.end("Server error");
      }
      return;
    }

    const ext = path.extname(filePath);
    const contentType = mimeTypes[ext] || "application/octet-stream";

    setSecurityHeaders(res, contentType);
    if (ext === ".html") {
      res.setHeader("Cache-Control", "no-store");
    } else if (
      [
        ".css",
        ".js",
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".svg",
        ".woff",
        ".woff2",
        ".ttf",
        ".ico",
      ].includes(ext)
    ) {
      res.setHeader("Cache-Control", "public, max-age=604800, immutable");
    }
    res.writeHead(200);
    if (req.method === "HEAD") {
      res.end();
      return;
    }
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log(`🚀 iBridge Local Server Running!`);
  console.log(`📍 Local URL: http://localhost:${PORT}`);
  console.log(`📱 Main Site: http://localhost:${PORT}/`);
  console.log(
    `👨‍💼 Staff Portal: http://localhost:${PORT}/TicketingSystem/frontend/professional-dashboard.html`,
  );
  console.log(`🎓 LMS Platform: http://localhost:${PORT}/lms-platform.html`);
  console.log(
    `📊 Security Dashboard: http://localhost:${PORT}/security-dashboard.html`,
  );
  console.log(`\n✨ Press Ctrl+C to stop the server`);
});

server.on("error", (err) => {
  if (err.code === "EADDRINUSE") {
    console.log(
      `❌ Port ${PORT} is already in use. Trying port ${PORT + 1}...`,
    );
    server.listen(PORT + 1);
  } else {
    console.error("Server error:", err);
  }
});
