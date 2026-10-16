import { config } from "./config.js";

export class HttpError extends Error {
  constructor(status, message, code = undefined) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export async function readBody(req, limit) {
  const declared = Number(req.headers["content-length"] || 0);
  if (declared > limit) throw new HttpError(413, "Dữ liệu gửi lên quá lớn");
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > limit) throw new HttpError(413, "Dữ liệu gửi lên quá lớn");
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

export async function readJson(req, limit = 64 * 1024) {
  const body = await readBody(req, limit);
  if (!body.length) return {};
  try {
    const parsed = JSON.parse(body.toString("utf8"));
    if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
      throw new Error("not an object");
    }
    return parsed;
  } catch {
    throw new HttpError(400, "Dữ liệu JSON không hợp lệ");
  }
}

export function corsHeaders(req) {
  const origin = req.headers.origin;
  const allowAll = config.corsOrigins.includes("*");
  const allowed = allowAll || (origin && config.corsOrigins.includes(origin));
  if (!allowed) return {};
  return {
    "Access-Control-Allow-Origin": allowAll ? "*" : origin,
    "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type, X-Admin-Token",
    "Access-Control-Max-Age": "600",
    ...(allowAll ? {} : { Vary: "Origin" }),
  };
}

export function sendJson(req, res, status, body) {
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    ...corsHeaders(req),
  });
  res.end(body === undefined ? "" : JSON.stringify(body));
}

export function clientIp(req) {
  const realIp = req.headers["x-real-ip"];
  if (typeof realIp === "string" && realIp) return realIp;
  return req.socket.remoteAddress || "unknown";
}

const buckets = new Map();

/** Fixed-window limiter; enough for a single Railway instance. */
export function rateLimit(key, max, windowMs, message = "Bạn thao tác quá nhanh, vui lòng thử lại sau.") {
  const now = Date.now();
  const bucket = buckets.get(key);
  if (!bucket || bucket.resetAt <= now) {
    buckets.set(key, { count: 1, resetAt: now + windowMs });
    return;
  }
  bucket.count += 1;
  if (bucket.count > max) throw new HttpError(429, message);
}

setInterval(() => {
  const now = Date.now();
  for (const [key, bucket] of buckets) {
    if (bucket.resetAt <= now) buckets.delete(key);
  }
}, 60_000).unref();

export function text(value, { field, max, required = false, min = 0 }) {
  const result = typeof value === "string" ? value.trim() : "";
  if (required && !result) throw new HttpError(400, `Vui lòng nhập ${field}`);
  if (result && result.length < min) throw new HttpError(400, `${field} cần ít nhất ${min} ký tự`);
  if (result.length > max) throw new HttpError(400, `${field} tối đa ${max} ký tự`);
  return result;
}

export function normalizeEmail(value) {
  const email = typeof value === "string" ? value.trim().toLowerCase() : "";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email) || email.length > 254) {
    throw new HttpError(400, "Email không hợp lệ");
  }
  return email;
}

export function normalizePhone(value, { required = false } = {}) {
  const phone = typeof value === "string" ? value.replace(/[\s().-]/g, "") : "";
  if (!phone) {
    if (required) throw new HttpError(400, "Vui lòng nhập số điện thoại");
    return "";
  }
  if (!/^\+?[0-9]{8,15}$/.test(phone)) throw new HttpError(400, "Số điện thoại chưa đúng định dạng");
  return phone;
}

export function validatePassword(value) {
  if (typeof value !== "string" || value.length < 8) {
    throw new HttpError(400, "Mật khẩu cần ít nhất 8 ký tự");
  }
  if (value.length > 128) throw new HttpError(400, "Mật khẩu tối đa 128 ký tự");
  return value;
}
