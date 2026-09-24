import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { createReadStream } from "node:fs";
import { extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const rootDir = resolve(fileURLToPath(new URL("..", import.meta.url)));
const webDir = join(rootDir, "mobile", "web");
const storePath = join(rootDir, "backend", "data", "store.json");
const host = process.env.HOST || "127.0.0.1";
const port = Number(process.env.PORT || 5173);

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
};

async function readStore() {
  return JSON.parse(await readFile(storePath, "utf8"));
}

async function writeStore(store) {
  await writeFile(storePath, `${JSON.stringify(store, null, 2)}\n`);
}

async function readJson(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

function sendJson(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

function sendError(res, status, message) {
  sendJson(res, status, { error: message });
}

async function handleApi(req, res, pathname) {
  const store = await readStore();
  const catalogRoutes = {
    "/api/v1/acupoints": "acupoints",
    "/api/v1/conditions": "conditions",
    "/api/v1/protocols": "protocols",
    "/api/v1/reflex-maps": "reflexMaps",
    "/api/v1/touch-points": "touchPoints",
    "/api/v1/principles": "principles",
    "/api/v1/tools": "tools",
  };

  if (req.method === "GET" && pathname === "/api/v1/health") {
    sendJson(res, 200, { ok: true });
    return;
  }

  if (req.method === "GET" && pathname === "/api/v1/catalog") {
    sendJson(res, 200, store.catalog);
    return;
  }

  if (req.method === "GET" && catalogRoutes[pathname]) {
    sendJson(res, 200, store.catalog[catalogRoutes[pathname]] || []);
    return;
  }

  if (req.method === "GET" && pathname === "/api/v1/product-spec") {
    sendJson(res, 200, store.productSpec || {});
    return;
  }

  if (req.method === "GET" && pathname === "/api/v1/settings") {
    sendJson(res, 200, store.settings);
    return;
  }

  if (req.method === "PUT" && pathname === "/api/v1/settings") {
    const body = await readJson(req);
    store.settings = { ...store.settings, ...body };
    await writeStore(store);
    sendJson(res, 200, store.settings);
    return;
  }

  if (req.method === "GET" && pathname === "/api/v1/tracking-records") {
    sendJson(res, 200, store.trackingRecords || []);
    return;
  }

  if (req.method === "POST" && pathname === "/api/v1/tracking-records") {
    const body = await readJson(req);
    if (!body.benh_id) {
      sendError(res, 400, "benh_id is required");
      return;
    }
    const record = {
      id: `tracking_${Date.now()}`,
      benh_id: String(body.benh_id),
      ngay_bat_dau: body.ngay_bat_dau || new Date().toISOString().slice(0, 10),
      nhat_ky: Array.isArray(body.nhat_ky) ? body.nhat_ky : [],
    };
    store.trackingRecords = [record, ...(store.trackingRecords || [])];
    await writeStore(store);
    sendJson(res, 201, record);
    return;
  }

  if (req.method === "GET" && pathname === "/api/v1/bookmarks") {
    sendJson(res, 200, store.bookmarks || []);
    return;
  }

  if (req.method === "POST" && pathname === "/api/v1/bookmarks") {
    const body = await readJson(req);
    if (!body.targetId || !body.targetType) {
      sendError(res, 400, "targetType and targetId are required");
      return;
    }
    const existing = (store.bookmarks || []).find((item) => item.targetType === body.targetType && item.targetId === body.targetId);
    if (existing) {
      sendJson(res, 200, existing);
      return;
    }
    const bookmark = {
      id: `bookmark_${Date.now()}`,
      targetType: String(body.targetType),
      targetId: String(body.targetId),
      createdAt: new Date().toISOString(),
    };
    store.bookmarks = [bookmark, ...(store.bookmarks || [])];
    await writeStore(store);
    sendJson(res, 201, bookmark);
    return;
  }

  if (req.method === "GET" && pathname === "/api/v1/journals") {
    sendJson(res, 200, store.journals || []);
    return;
  }

  if (req.method === "POST" && pathname === "/api/v1/journals") {
    const body = await readJson(req);
    if (!body.protocolId || !Number(body.mood)) {
      sendError(res, 400, "protocolId and mood are required");
      return;
    }

    const journal = {
      id: `journal_${Date.now()}`,
      protocolId: String(body.protocolId),
      mood: Number(body.mood),
      note: String(body.note || ""),
      createdAt: new Date().toISOString(),
    };
    store.journals = [journal, ...(store.journals || [])];

    if (body.conditionId) {
      const record = (store.trackingRecords || []).find((item) => item.benh_id === body.conditionId);
      const entry = {
        ngay: journal.createdAt.slice(0, 10),
        phac_do_id: journal.protocolId,
        cam_nhan: journal.mood,
        ghi_chu: journal.note,
      };
      if (record) {
        record.nhat_ky = [entry, ...(record.nhat_ky || [])];
      } else {
        store.trackingRecords = [
          {
            id: `tracking_${Date.now()}`,
            benh_id: String(body.conditionId),
            ngay_bat_dau: journal.createdAt.slice(0, 10),
            nhat_ky: [entry],
          },
          ...(store.trackingRecords || []),
        ];
      }
    }

    await writeStore(store);
    sendJson(res, 201, journal);
    return;
  }

  sendError(res, 404, "Not found");
}

function serveStatic(req, res, pathname) {
  const requestedPath = pathname === "/" ? "/index.html" : pathname;
  const filePath = normalize(join(webDir, requestedPath));

  if (!filePath.startsWith(webDir)) {
    sendError(res, 403, "Forbidden");
    return;
  }

  const stream = createReadStream(filePath);
  stream.on("open", () => {
    res.writeHead(200, { "Content-Type": mimeTypes[extname(filePath)] || "application/octet-stream" });
    stream.pipe(res);
  });
  stream.on("error", () => {
    const fallback = createReadStream(join(webDir, "index.html"));
    res.writeHead(200, { "Content-Type": mimeTypes[".html"] });
    fallback.pipe(res);
  });
}

const server = createServer(async (req, res) => {
  try {
    const { pathname } = new URL(req.url || "/", `http://${req.headers.host}`);
    if (pathname.startsWith("/api/")) {
      await handleApi(req, res, pathname);
      return;
    }
    serveStatic(req, res, pathname);
  } catch (error) {
    sendError(res, 500, error.message || "Internal server error");
  }
});

server.listen(port, host, () => {
  console.log(`Dien Chan App running at http://${host}:${port}`);
});
