import { createServer } from "node:http";
import { createReadStream } from "node:fs";
import { readFile } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { handleApi } from "./src/api.js";
import { config } from "./src/config.js";
import { closeDb, migrate } from "./src/db.js";
import { attachRealtime } from "./src/realtime.js";

const rootDir = resolve(fileURLToPath(new URL("..", import.meta.url)));
const webDir = join(rootDir, "mobile", "web");
const legalDir = join(rootDir, "backend", "public");

// Linked from the App Store / Google Play listings, so they must stay at these paths.
const legalPages = {
  "/privacy": "privacy.html",
  "/terms": "terms.html",
  "/delete-account": "delete-account.html",
  "/support": "support.html",
};

const escapeHtml = (value) =>
  value.replace(/[&<>"']/g, (char) => `&#${char.charCodeAt(0)};`);

async function serveLegalPage(res, file) {
  const hotline = 'hotline <a href="tel:0903888397">0903.888.397</a>';
  const email = escapeHtml(config.adminEmail);
  const contact = email ? `email <a href="mailto:${email}">${email}</a> hoặc ${hotline}` : hotline;
  const html = (await readFile(join(legalDir, file), "utf8"))
    .replaceAll("{{APP_NAME}}", escapeHtml(config.appName))
    .replaceAll("{{CONTACT}}", contact);
  res.writeHead(200, { "Content-Type": mimeTypes[".html"], "Cache-Control": "public, max-age=300" });
  res.end(html);
}

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
};

function serveStatic(res, pathname) {
  const requestedPath = pathname === "/" ? "/index.html" : pathname;
  const filePath = normalize(join(webDir, requestedPath));
  if (!filePath.startsWith(webDir)) {
    res.writeHead(403).end();
    return;
  }
  const stream = createReadStream(filePath);
  stream.on("open", () => {
    res.writeHead(200, { "Content-Type": mimeTypes[extname(filePath)] || "application/octet-stream" });
    stream.pipe(res);
  });
  stream.on("error", () => {
    res.writeHead(200, { "Content-Type": mimeTypes[".html"] });
    createReadStream(join(webDir, "index.html")).on("error", () => res.end()).pipe(res);
  });
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url || "/", "http://localhost");
  if (url.pathname.startsWith("/api/")) {
    await handleApi(req, res, url);
    return;
  }
  const legalPage = legalPages[url.pathname.replace(/\/$/, "")];
  if (legalPage && req.method === "GET") {
    await serveLegalPage(res, legalPage);
    return;
  }
  if (config.serveWeb) {
    serveStatic(res, url.pathname);
    return;
  }
  res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" }).end(`${config.appName} API`);
});

attachRealtime(server);

try {
  await migrate();
} catch (error) {
  console.error(`Không kết nối được Postgres (${config.databaseUrl.replace(/:[^:@/]+@/, ":***@")}):`, error.message);
  process.exit(1);
}

server.listen(config.port, config.host, () => {
  console.log(`${config.appName} API running at http://${config.host}:${config.port}`);
});

function shutdown() {
  server.close(() => closeDb().finally(() => process.exit(0)));
  setTimeout(() => process.exit(0), 5000).unref();
}
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
