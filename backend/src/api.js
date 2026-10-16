import { readFile } from "node:fs/promises";
import { timingSafeEqual } from "node:crypto";
import {
  bearerToken,
  burnPasswordCheck,
  createSession,
  exchangeAppleCode,
  hashPassword,
  newResetCode,
  requireUser,
  revokeAppleToken,
  revokeSession,
  sha256,
  USER_COLUMNS,
  userFromToken,
  verifyAppleIdentityToken,
  verifyPassword,
} from "./auth.js";
import { config } from "./config.js";
import { one, query, transaction } from "./db.js";
import {
  clientIp,
  corsHeaders,
  HttpError,
  normalizeEmail,
  normalizePhone,
  rateLimit,
  readBody,
  readJson,
  sendJson,
  text,
  validatePassword,
} from "./http.js";
import { canSendMail, mailConfigured, sendMail } from "./mail.js";
import {
  broadcast,
  broadcastChatMessage,
  disconnectUser,
  onlineUsers,
  refreshBlocks,
  refreshUser,
  sendToUser,
} from "./realtime.js";

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const COURSES = {
  "K48-OFFLINE": "Khóa 48 - Offline",
  "K49-ONLINE": "Khóa 49 - Online",
};

let catalogStore;
async function catalog() {
  catalogStore ??= JSON.parse(await readFile(new URL("../data/store.json", import.meta.url), "utf8"));
  return catalogStore;
}

function settingsOf(user) {
  const raw = user.settings || {};
  const minute = Number.isInteger(raw.reminderMinute) ? raw.reminderMinute : 7 * 60;
  return { reminders: raw.reminders === true, reminderMinute: Math.min(Math.max(minute, 0), 1439) };
}

function publicUser(user) {
  return {
    id: user.id,
    email: user.email || "",
    fullName: user.full_name,
    phone: user.phone,
    country: user.country,
    hasPassword: Boolean(user.password_hash),
    appleLinked: Boolean(user.apple_sub),
    avatarUpdatedAt: user.avatar_updated_at,
    settings: settingsOf(user),
    createdAt: user.created_at,
  };
}

const sessionResponse = (token, user, extra = {}) => ({ token, user: publicUser(user), ...extra });

function uuidParam(value, label = "Mã") {
  if (!UUID.test(value)) throw new HttpError(404, `${label} không tồn tại`);
  return value;
}

function profileFields(body, { partial }) {
  const fields = {};
  if (!partial || "fullName" in body) {
    fields.full_name = text(body.fullName, { field: "họ tên", required: true, min: 2, max: 80 });
  }
  if (!partial || "phone" in body) fields.phone = normalizePhone(body.phone);
  if (!partial || "country" in body) fields.country = text(body.country, { field: "quốc gia", max: 60 });
  return fields;
}

const BANNED_WORDS = ["địt", "đụ", "đéo", "lồn", "cặc", "buồi", "fuck", "shit", "bitch", "cunt"];
const bannedPattern = new RegExp(`(?<!\\p{L})(${BANNED_WORDS.join("|")})(?!\\p{L})`, "giu");
const filterText = (value) => value.replace(bannedPattern, (word) => "*".repeat(word.length));

function chatMessage(row, viewerId) {
  return {
    id: String(row.id),
    body: row.body,
    createdAt: row.created_at,
    isMine: row.author_id === viewerId,
    author: { id: row.author_id, fullName: row.full_name || "Thành viên", country: row.country || "" },
  };
}

function notifyAdmin(subject, body) {
  if (!config.adminEmail || !mailConfigured()) return;
  sendMail({ to: config.adminEmail, subject, text: body }).catch((error) =>
    console.warn("Admin notification failed:", error.message),
  );
}

function requireAdmin(req) {
  const provided = Buffer.from(sha256(String(req.headers["x-admin-token"] || "")));
  const expected = Buffer.from(sha256(config.adminToken));
  if (!config.adminToken || !timingSafeEqual(provided, expected)) throw new HttpError(404, "Not found");
}

const NOTIFICATION_KINDS = new Set(["info", "course", "warning", "community"]);

/** Stores a notification for one account, or for everyone when userId is null. */
async function createNotification({ userId = null, kind = "info", title, body = "" }) {
  const row = await one(
    "INSERT INTO notifications (user_id, kind, title, body) VALUES ($1, $2, $3, $4) RETURNING id",
    [userId, kind, title, body],
  );
  const payload = { type: "notification", id: String(row.id) };
  if (userId) sendToUser(userId, payload);
  else broadcast(payload);
  return row;
}

const welcomeNotification = (userId) =>
  createNotification({
    userId,
    title: "Chào mừng bạn đến với Diện Chẩn",
    body: "Tài khoản đã sẵn sàng. Bạn có thể lưu nhật ký day huyệt, huyệt yêu thích và tham gia cộng đồng.",
  });

const routes = [];
function route(method, path, handler, options = {}) {
  const keys = [];
  const pattern = new RegExp(
    `^/api/v1${path.replace(/:(\w+)/g, (_, key) => {
      keys.push(key);
      return "([^/]+)";
    })}$`,
  );
  routes.push({ method, pattern, keys, handler, options });
}

// ---------- Public ----------

route("GET", "/health", async () => {
  await query("SELECT 1");
  return { ok: true, mail: mailConfigured(), apple: config.apple.clientIds.length > 0 };
});

route("GET", "/catalog", async () => (await catalog()).catalog);
for (const [path, key] of Object.entries({
  "/acupoints": "acupoints",
  "/conditions": "conditions",
  "/protocols": "protocols",
  "/reflex-maps": "reflexMaps",
  "/touch-points": "touchPoints",
  "/principles": "principles",
  "/tools": "tools",
})) {
  route("GET", path, async () => (await catalog()).catalog[key] || []);
}

// ---------- Auth ----------

route("POST", "/auth/register", async ({ req, body, ctx }) => {
  rateLimit(`register:${clientIp(req)}`, 10, HOUR);
  const email = normalizeEmail(body.email);
  const password = validatePassword(body.password);
  const fields = profileFields(body, { partial: false });
  const passwordHash = await hashPassword(password);
  let user;
  try {
    user = await one(
      `INSERT INTO users (email, password_hash, full_name, phone, country)
       VALUES ($1, $2, $3, $4, $5) RETURNING ${USER_COLUMNS}`,
      [email, passwordHash, fields.full_name, fields.phone, fields.country],
    );
  } catch (error) {
    if (error.code === "23505") {
      throw new HttpError(409, "Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng Quên mật khẩu.");
    }
    throw error;
  }
  await welcomeNotification(user.id);
  ctx.status = 201;
  return sessionResponse(await createSession(user.id, req.headers["user-agent"]), user);
});

route("POST", "/auth/login", async ({ req, body }) => {
  rateLimit(`login:${clientIp(req)}`, 30, 15 * MINUTE);
  const email = normalizeEmail(body.email);
  rateLimit(`login:${email}`, 10, 15 * MINUTE, "Bạn đã thử quá nhiều lần. Vui lòng đợi 15 phút.");
  const user = await one(`SELECT ${USER_COLUMNS} FROM users WHERE email = $1`, [email]);
  const valid = user?.password_hash
    ? await verifyPassword(String(body.password || ""), user.password_hash)
    : (await burnPasswordCheck(body.password), false);
  if (!valid) throw new HttpError(401, "Email hoặc mật khẩu không đúng");
  return sessionResponse(await createSession(user.id, req.headers["user-agent"]), user);
});

route("POST", "/auth/apple", async ({ req, body }) => {
  rateLimit(`apple:${clientIp(req)}`, 30, 15 * MINUTE);
  const identityToken = text(body.identityToken, { field: "identityToken", required: true, max: 5000 });
  const payload = await verifyAppleIdentityToken(identityToken, typeof body.nonce === "string" ? body.nonce : "");
  const clientId = Array.isArray(payload.aud) ? payload.aud[0] : payload.aud;
  const email = typeof payload.email === "string" ? payload.email.toLowerCase() : null;
  const emailVerified = payload.email_verified === true || payload.email_verified === "true";
  const fullName = text(body.fullName, { field: "họ tên", max: 80 });
  const refreshToken = await exchangeAppleCode(
    typeof body.authorizationCode === "string" ? body.authorizationCode : "",
    clientId,
  );

  const { user, isNewUser } = await transaction(async (db) => {
    let existing = (
      await db.query(`SELECT ${USER_COLUMNS} FROM users WHERE apple_sub = $1 FOR UPDATE`, [payload.sub])
    ).rows[0];
    if (!existing && email && emailVerified) {
      existing = (
        await db.query(`SELECT ${USER_COLUMNS} FROM users WHERE email = $1 AND apple_sub IS NULL FOR UPDATE`, [email])
      ).rows[0];
    }
    if (existing) {
      const updated = await db.query(
        `UPDATE users SET apple_sub = $2, apple_client_id = $3,
           apple_refresh_token = COALESCE($4, apple_refresh_token),
           full_name = CASE WHEN full_name = '' THEN $5 ELSE full_name END,
           updated_at = now()
         WHERE id = $1 RETURNING ${USER_COLUMNS}`,
        [existing.id, payload.sub, clientId, refreshToken, fullName],
      );
      return { user: updated.rows[0], isNewUser: false };
    }
    const emailTaken = email
      ? (await db.query("SELECT 1 FROM users WHERE email = $1", [email])).rowCount > 0
      : true;
    const created = await db.query(
      `INSERT INTO users (email, apple_sub, apple_client_id, apple_refresh_token, full_name)
       VALUES ($1, $2, $3, $4, $5) RETURNING ${USER_COLUMNS}`,
      [emailTaken ? null : email, payload.sub, clientId, refreshToken, fullName],
    );
    return { user: created.rows[0], isNewUser: true };
  });
  if (isNewUser) await welcomeNotification(user.id);
  return sessionResponse(await createSession(user.id, req.headers["user-agent"]), user, { isNewUser });
});

route("POST", "/auth/logout", async ({ req }) => {
  const token = bearerToken(req);
  if (token) await revokeSession(token);
  return { ok: true };
});

route("POST", "/auth/password/forgot", async ({ req, body }) => {
  rateLimit(`forgot:${clientIp(req)}`, 10, HOUR);
  const email = normalizeEmail(body.email);
  rateLimit(`forgot:${email}`, 3, HOUR, "Bạn đã yêu cầu nhiều lần. Vui lòng kiểm tra hộp thư hoặc thử lại sau 1 giờ.");
  if (!canSendMail()) throw new HttpError(503, "Máy chủ chưa cấu hình gửi email");
  const user = await one("SELECT id, email FROM users WHERE email = $1", [email]);
  if (user) {
    const code = newResetCode();
    await transaction(async (db) => {
      await db.query("UPDATE password_resets SET used_at = now() WHERE user_id = $1 AND used_at IS NULL", [user.id]);
      await db.query(
        `INSERT INTO password_resets (user_id, code_hash, expires_at) VALUES ($1, $2, now() + interval '15 minutes')`,
        [user.id, sha256(`${user.id}:${code}`)],
      );
    });
    await sendMail({
      to: user.email,
      subject: `Mã đặt lại mật khẩu ${config.appName}`,
      text: `Mã xác nhận của bạn là: ${code}\n\nMã có hiệu lực trong 15 phút. Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.`,
    });
  }
  return { ok: true };
});

route("POST", "/auth/password/reset", async ({ req, body }) => {
  rateLimit(`reset:${clientIp(req)}`, 20, 15 * MINUTE);
  const email = normalizeEmail(body.email);
  const code = typeof body.code === "string" ? body.code.trim() : "";
  const password = validatePassword(body.password);
  const invalid = new HttpError(400, "Mã xác nhận không đúng hoặc đã hết hạn");
  const user = await one(`SELECT ${USER_COLUMNS} FROM users WHERE email = $1`, [email]);
  if (!user) throw invalid;
  const reset = await one(
    `SELECT * FROM password_resets WHERE user_id = $1 AND used_at IS NULL AND expires_at > now()
     ORDER BY created_at DESC LIMIT 1`,
    [user.id],
  );
  if (!reset || reset.attempts >= 5) throw invalid;
  const expected = Buffer.from(reset.code_hash);
  const actual = Buffer.from(sha256(`${user.id}:${code}`));
  if (!/^\d{6}$/.test(code) || !timingSafeEqual(expected, actual)) {
    await query("UPDATE password_resets SET attempts = attempts + 1 WHERE id = $1", [reset.id]);
    throw invalid;
  }
  const passwordHash = await hashPassword(password);
  const updated = await transaction(async (db) => {
    await db.query("UPDATE password_resets SET used_at = now() WHERE id = $1", [reset.id]);
    await db.query("DELETE FROM sessions WHERE user_id = $1", [user.id]);
    const result = await db.query(
      `UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1 RETURNING ${USER_COLUMNS}`,
      [user.id, passwordHash],
    );
    return result.rows[0];
  });
  disconnectUser(user.id);
  return sessionResponse(await createSession(user.id, req.headers["user-agent"]), updated);
});

route("POST", "/auth/password/change", async ({ req, body, user }) => {
  rateLimit(`change-password:${user.id}`, 10, 15 * MINUTE);
  if (user.password_hash && !(await verifyPassword(String(body.currentPassword || ""), user.password_hash))) {
    throw new HttpError(400, "Mật khẩu hiện tại không đúng");
  }
  const passwordHash = await hashPassword(validatePassword(body.newPassword));
  await transaction(async (db) => {
    await db.query("UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1", [user.id, passwordHash]);
    await db.query("DELETE FROM sessions WHERE user_id = $1 AND token_hash <> $2", [
      user.id,
      sha256(bearerToken(req)),
    ]);
  });
  return { ok: true };
}, { auth: true });

// ---------- Profile ----------

route("GET", "/me", async ({ user }) => {
  const stats = await one(
    `SELECT
       (SELECT count(*)::int FROM bookmarks WHERE user_id = $1) AS bookmarks,
       (SELECT count(*)::int FROM journals WHERE user_id = $1) AS journals,
       (SELECT count(*)::int FROM course_registrations WHERE user_id = $1) AS "courseRegistrations"`,
    [user.id],
  );
  return { user: publicUser(user), stats };
}, { auth: true });

route("PATCH", "/me", async ({ body, user }) => {
  const fields = profileFields(body, { partial: true });
  const keys = Object.keys(fields);
  if (!keys.length) return { user: publicUser(user) };
  const assignments = keys.map((key, index) => `${key} = $${index + 2}`).join(", ");
  const updated = await one(
    `UPDATE users SET ${assignments}, updated_at = now() WHERE id = $1 RETURNING ${USER_COLUMNS}`,
    [user.id, ...keys.map((key) => fields[key])],
  );
  refreshUser(updated);
  return { user: publicUser(updated) };
}, { auth: true });

route("DELETE", "/me", async ({ body, user }) => {
  rateLimit(`delete-account:${user.id}`, 5, 15 * MINUTE);
  if (user.password_hash) {
    if (!(await verifyPassword(String(body.password || ""), user.password_hash))) {
      throw new HttpError(400, "Mật khẩu không đúng");
    }
  } else if (body.confirm !== "DELETE") {
    throw new HttpError(400, "Vui lòng xác nhận xóa tài khoản");
  }
  await revokeAppleToken(user.apple_refresh_token, user.apple_client_id);
  await query("DELETE FROM users WHERE id = $1", [user.id]);
  disconnectUser(user.id);
  broadcast({ type: "chat_user_removed", userId: user.id });
  return { ok: true };
}, { auth: true });

route("GET", "/me/avatar", async ({ res, req, user, ctx }) => {
  const row = await one("SELECT avatar, avatar_type FROM users WHERE id = $1", [user.id]);
  if (!row?.avatar) throw new HttpError(404, "Chưa có ảnh đại diện");
  res.writeHead(200, {
    "Content-Type": row.avatar_type || "image/png",
    "Cache-Control": "private, no-store",
    ...corsHeaders(req),
  });
  res.end(row.avatar);
  ctx.handled = true;
}, { auth: true });

route("PUT", "/me/avatar", async ({ req, user }) => {
  rateLimit(`avatar:${user.id}`, 20, HOUR);
  const bytes = await readBody(req, 2 * 1024 * 1024);
  const isPng = bytes.subarray(0, 4).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47]));
  const isJpeg = bytes.subarray(0, 3).equals(Buffer.from([0xff, 0xd8, 0xff]));
  if (!isPng && !isJpeg) throw new HttpError(400, "Ảnh đại diện cần là PNG hoặc JPEG");
  const updated = await one(
    `UPDATE users SET avatar = $2, avatar_type = $3, avatar_updated_at = now(), updated_at = now()
     WHERE id = $1 RETURNING ${USER_COLUMNS}`,
    [user.id, bytes, isPng ? "image/png" : "image/jpeg"],
  );
  return { user: publicUser(updated) };
}, { auth: true, rawBody: true });

route("DELETE", "/me/avatar", async ({ user }) => {
  const updated = await one(
    `UPDATE users SET avatar = NULL, avatar_type = NULL, avatar_updated_at = NULL, updated_at = now()
     WHERE id = $1 RETURNING ${USER_COLUMNS}`,
    [user.id],
  );
  return { user: publicUser(updated) };
}, { auth: true });

route("GET", "/me/settings", async ({ user }) => settingsOf(user), { auth: true });

route("PUT", "/me/settings", async ({ body, user }) => {
  const next = { ...settingsOf(user) };
  if ("reminders" in body) next.reminders = body.reminders === true;
  if ("reminderMinute" in body) {
    const minute = Number(body.reminderMinute);
    if (!Number.isInteger(minute) || minute < 0 || minute > 1439) throw new HttpError(400, "Giờ nhắc không hợp lệ");
    next.reminderMinute = minute;
  }
  const updated = await one(
    `UPDATE users SET settings = settings || $2::jsonb, updated_at = now() WHERE id = $1 RETURNING ${USER_COLUMNS}`,
    [user.id, JSON.stringify(next)],
  );
  return settingsOf(updated);
}, { auth: true });

// ---------- Bookmarks & journals ----------

const bookmarkJson = (row) => ({
  id: row.id,
  targetType: row.target_type,
  targetId: row.target_id,
  title: row.title,
  createdAt: row.created_at,
});

route("GET", "/me/bookmarks", async ({ user }) => {
  const { rows } = await query("SELECT * FROM bookmarks WHERE user_id = $1 ORDER BY created_at DESC", [user.id]);
  return { bookmarks: rows.map(bookmarkJson) };
}, { auth: true });

route("POST", "/me/bookmarks", async ({ body, user, ctx }) => {
  const targetType = text(body.targetType, { field: "loại mục", required: true, max: 40 });
  const targetId = text(body.targetId, { field: "mã mục", required: true, max: 120 });
  const title = text(body.title, { field: "tiêu đề", max: 200 });
  const row = await one(
    `INSERT INTO bookmarks (user_id, target_type, target_id, title) VALUES ($1, $2, $3, $4)
     ON CONFLICT (user_id, target_type, target_id) DO UPDATE SET title = EXCLUDED.title
     RETURNING *`,
    [user.id, targetType, targetId, title],
  );
  ctx.status = 201;
  return { bookmark: bookmarkJson(row) };
}, { auth: true });

route("DELETE", "/me/bookmarks/:id", async ({ params, user }) => {
  await query("DELETE FROM bookmarks WHERE id = $1 AND user_id = $2", [uuidParam(params.id), user.id]);
  return { ok: true };
}, { auth: true });

const journalJson = (row) => ({
  id: row.id,
  title: row.title,
  note: row.note,
  mood: row.mood,
  relatedType: row.related_type,
  relatedId: row.related_id,
  createdAt: row.created_at,
});

route("GET", "/me/journals", async ({ user }) => {
  const { rows } = await query(
    "SELECT * FROM journals WHERE user_id = $1 ORDER BY created_at DESC LIMIT 500",
    [user.id],
  );
  return { journals: rows.map(journalJson) };
}, { auth: true });

route("POST", "/me/journals", async ({ body, user, ctx }) => {
  rateLimit(`journal:${user.id}`, 60, HOUR);
  const title = text(body.title, { field: "tiêu đề", required: true, max: 120 });
  const note = text(body.note, { field: "ghi chú", max: 4000 });
  const mood = body.mood == null ? null : Number(body.mood);
  if (mood !== null && (!Number.isInteger(mood) || mood < 1 || mood > 5)) {
    throw new HttpError(400, "Mức cảm nhận cần từ 1 đến 5");
  }
  const row = await one(
    `INSERT INTO journals (user_id, title, note, mood, related_type, related_id)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [
      user.id,
      title,
      note,
      mood,
      text(body.relatedType, { field: "loại liên kết", max: 40 }) || null,
      text(body.relatedId, { field: "mã liên kết", max: 120 }) || null,
    ],
  );
  ctx.status = 201;
  return { journal: journalJson(row) };
}, { auth: true });

route("DELETE", "/me/journals/:id", async ({ params, user }) => {
  await query("DELETE FROM journals WHERE id = $1 AND user_id = $2", [uuidParam(params.id), user.id]);
  return { ok: true };
}, { auth: true });

// ---------- Course registrations ----------

const registrationJson = (row) => ({
  id: row.id,
  courseCode: row.course_code,
  courseName: COURSES[row.course_code] || row.course_code,
  fullName: row.full_name,
  phone: row.phone,
  email: row.email,
  note: row.note,
  status: row.status,
  createdAt: row.created_at,
});

route("POST", "/course-registrations", async ({ req, body, ctx }) => {
  rateLimit(`course:${clientIp(req)}`, 8, HOUR);
  const user = await userFromToken(bearerToken(req));
  const courseCode = typeof body.courseCode === "string" ? body.courseCode : "";
  if (!COURSES[courseCode]) throw new HttpError(400, "Vui lòng chọn khóa học");
  const fullName = text(body.fullName, { field: "họ tên học viên", required: true, min: 2, max: 80 });
  const phone = normalizePhone(body.phone, { required: true });
  const email = body.email ? normalizeEmail(body.email) : user?.email || "";
  const note = text(body.note, { field: "ghi chú", max: 1000 });
  const row = await one(
    `INSERT INTO course_registrations (user_id, course_code, full_name, phone, email, note)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    [user?.id || null, courseCode, fullName, phone, email, note],
  );
  notifyAdmin(
    `Đăng ký mới: ${COURSES[courseCode]}`,
    `Khóa: ${COURSES[courseCode]}\nHọ tên: ${fullName}\nSĐT: ${phone}\nEmail: ${email || "-"}\nGhi chú: ${note || "-"}`,
  );
  if (user) {
    await createNotification({
      userId: user.id,
      kind: "course",
      title: `Đã nhận đăng ký ${COURSES[courseCode]}`,
      body: `Trung tâm sẽ liên hệ số ${phone} để xác nhận lịch học.`,
    });
  }
  ctx.status = 201;
  return { registration: registrationJson(row) };
});

route("GET", "/me/course-registrations", async ({ user }) => {
  const { rows } = await query(
    "SELECT * FROM course_registrations WHERE user_id = $1 ORDER BY created_at DESC",
    [user.id],
  );
  return { registrations: rows.map(registrationJson) };
}, { auth: true });

route("GET", "/admin/course-registrations", async ({ req }) => {
  requireAdmin(req);
  const { rows } = await query("SELECT * FROM course_registrations ORDER BY created_at DESC LIMIT 1000");
  return { registrations: rows.map(registrationJson) };
});

// ---------- Support ----------

route("POST", "/support-requests", async ({ req, body, ctx }) => {
  rateLimit(`support:${clientIp(req)}`, 5, HOUR, "Bạn đã gửi nhiều yêu cầu, vui lòng thử lại sau.");
  const user = await userFromToken(bearerToken(req));
  const message = text(body.message, { field: "nội dung", required: true, min: 10, max: 2000 });
  const contact = user
    ? [user.email, user.phone].filter(Boolean).join(" · ")
    : text(body.contact, { field: "thông tin liên hệ", required: true, min: 5, max: 120 });
  await query("INSERT INTO support_requests (user_id, contact, message) VALUES ($1, $2, $3)", [
    user?.id || null,
    contact,
    message,
  ]);
  notifyAdmin(
    "Yêu cầu hỗ trợ mới",
    `Người gửi: ${user?.full_name || "Khách"}\nLiên hệ: ${contact || "-"}\n\n${message}`,
  );
  if (user) {
    await createNotification({
      userId: user.id,
      title: "Đã nhận yêu cầu hỗ trợ",
      body: "Bộ phận hỗ trợ sẽ liên hệ lại với bạn sớm.",
    });
  }
  ctx.status = 201;
  return { ok: true };
});

// ---------- Notifications ----------

const NOTIFICATION_SELECT = `SELECT n.id, n.kind, n.title, n.body, n.created_at, (r.user_id IS NOT NULL) AS read
  FROM notifications n
  LEFT JOIN notification_reads r ON r.notification_id = n.id AND r.user_id = $1
  WHERE n.user_id = $1
     OR (n.user_id IS NULL AND n.created_at >= (SELECT created_at FROM users WHERE id = $1))`;

route("GET", "/me/notifications", async ({ user }) => {
  const { rows } = await query(`${NOTIFICATION_SELECT} ORDER BY n.id DESC LIMIT 100`, [user.id]);
  return {
    notifications: rows.map((row) => ({
      id: String(row.id),
      kind: row.kind,
      title: row.title,
      body: row.body,
      createdAt: row.created_at,
      read: row.read,
    })),
    unread: rows.filter((row) => !row.read).length,
  };
}, { auth: true });

route("POST", "/me/notifications/read", async ({ body, user }) => {
  const ids = Array.isArray(body.ids) ? body.ids.filter((id) => /^\d+$/.test(String(id))).slice(0, 200) : null;
  await query(
    `INSERT INTO notification_reads (user_id, notification_id)
     SELECT $1, visible.id FROM (${NOTIFICATION_SELECT}) AS visible
     WHERE NOT visible.read AND ($2::bigint[] IS NULL OR visible.id = ANY($2::bigint[]))
     ON CONFLICT DO NOTHING`,
    [user.id, ids],
  );
  return { ok: true };
}, { auth: true });

route("POST", "/admin/notifications", async ({ req, body, ctx }) => {
  requireAdmin(req);
  const kind = NOTIFICATION_KINDS.has(body.kind) ? body.kind : "info";
  const title = text(body.title, { field: "tiêu đề", required: true, max: 120 });
  const content = text(body.body, { field: "nội dung", max: 2000 });
  const userId = body.userId ? uuidParam(String(body.userId), "Thành viên") : null;
  const row = await createNotification({ userId, kind, title, body: content });
  ctx.status = 201;
  return { id: String(row.id) };
});

// ---------- Community chat ----------

const CHAT_SELECT = `SELECT m.id, m.body, m.created_at, u.id AS author_id, u.full_name, u.country
  FROM chat_messages m JOIN users u ON u.id = m.user_id`;

route("GET", "/chat/messages", async ({ url, user }) => {
  const limit = Math.min(Math.max(Number(url.searchParams.get("limit")) || 50, 1), 100);
  const beforeParam = url.searchParams.get("before");
  const before = beforeParam && /^\d+$/.test(beforeParam) ? beforeParam : null;
  const { rows } = await query(
    `${CHAT_SELECT}
     WHERE m.hidden_at IS NULL AND ($2::bigint IS NULL OR m.id < $2::bigint)
       AND NOT EXISTS (
         SELECT 1 FROM user_blocks b
         WHERE (b.user_id = $1 AND b.blocked_user_id = m.user_id)
            OR (b.user_id = m.user_id AND b.blocked_user_id = $1))
     ORDER BY m.id DESC LIMIT $3`,
    [user.id, before, limit + 1],
  );
  const hasMore = rows.length > limit;
  return {
    messages: rows
      .slice(0, limit)
      .reverse()
      .map((row) => chatMessage(row, user.id)),
    hasMore,
  };
}, { auth: true });

route("POST", "/chat/messages", async ({ body, user, ctx }) => {
  rateLimit(`chat-burst:${user.id}`, 1, 1000, "Bạn gửi tin quá nhanh.");
  rateLimit(`chat:${user.id}`, 20, MINUTE, "Bạn gửi quá nhiều tin, vui lòng chờ một chút.");
  if (!user.full_name) throw new HttpError(400, "Vui lòng cập nhật họ tên trước khi chat");
  const content = filterText(text(body.body, { field: "nội dung", required: true, max: 1000 }));
  const inserted = await one(
    "INSERT INTO chat_messages (user_id, body) VALUES ($1, $2) RETURNING id, body, created_at",
    [user.id, content],
  );
  const message = chatMessage(
    { ...inserted, author_id: user.id, full_name: user.full_name, country: user.country },
    user.id,
  );
  broadcastChatMessage(message);
  ctx.status = 201;
  return { message };
}, { auth: true });

route("DELETE", "/chat/messages/:id", async ({ params, user }) => {
  if (!/^\d+$/.test(params.id)) throw new HttpError(404, "Tin nhắn không tồn tại");
  const row = await one(
    "UPDATE chat_messages SET hidden_at = now() WHERE id = $1 AND user_id = $2 AND hidden_at IS NULL RETURNING id",
    [params.id, user.id],
  );
  if (!row) throw new HttpError(404, "Tin nhắn không tồn tại");
  broadcast({ type: "chat_hidden", messageId: String(row.id) });
  return { ok: true };
}, { auth: true });

route("POST", "/chat/messages/:id/report", async ({ params, body, user }) => {
  rateLimit(`report:${user.id}`, 30, HOUR);
  if (!/^\d+$/.test(params.id)) throw new HttpError(404, "Tin nhắn không tồn tại");
  const message = await one(
    `${CHAT_SELECT} WHERE m.id = $1 AND m.hidden_at IS NULL`,
    [params.id],
  );
  if (!message) throw new HttpError(404, "Tin nhắn không tồn tại");
  const reason = text(body.reason, { field: "lý do", max: 500 });
  await query(
    `INSERT INTO chat_reports (message_id, reporter_id, reason) VALUES ($1, $2, $3)
     ON CONFLICT (message_id, reporter_id) DO NOTHING`,
    [params.id, user.id, reason],
  );
  const { count } = await one("SELECT count(*)::int AS count FROM chat_reports WHERE message_id = $1", [params.id]);
  if (count >= 3) {
    await query("UPDATE chat_messages SET hidden_at = now() WHERE id = $1", [params.id]);
    broadcast({ type: "chat_hidden", messageId: String(params.id) });
  }
  notifyAdmin(
    "Báo cáo tin nhắn cộng đồng",
    `Người báo cáo: ${user.full_name} (${user.email || user.id})\nTác giả: ${message.full_name} (${message.author_id})\nNội dung: ${message.body}\nLý do: ${reason || "-"}`,
  );
  return { ok: true };
}, { auth: true });

route("GET", "/chat/online", async () => ({ users: onlineUsers() }), { auth: true });

route("GET", "/me/blocks", async ({ user }) => {
  const { rows } = await query(
    `SELECT u.id, u.full_name, u.country FROM user_blocks b JOIN users u ON u.id = b.blocked_user_id
     WHERE b.user_id = $1 ORDER BY b.created_at DESC`,
    [user.id],
  );
  return { users: rows.map((row) => ({ id: row.id, fullName: row.full_name, country: row.country })) };
}, { auth: true });

route("POST", "/me/blocks", async ({ body, user, ctx }) => {
  const blockedId = uuidParam(String(body.userId || ""), "Thành viên");
  if (blockedId === user.id) throw new HttpError(400, "Không thể tự chặn chính mình");
  const target = await one("SELECT id FROM users WHERE id = $1", [blockedId]);
  if (!target) throw new HttpError(404, "Thành viên không tồn tại");
  await query(
    "INSERT INTO user_blocks (user_id, blocked_user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
    [user.id, blockedId],
  );
  await refreshBlocks([user.id, blockedId]);
  ctx.status = 201;
  return { ok: true };
}, { auth: true });

route("DELETE", "/me/blocks/:userId", async ({ params, user }) => {
  const blockedId = uuidParam(params.userId, "Thành viên");
  await query("DELETE FROM user_blocks WHERE user_id = $1 AND blocked_user_id = $2", [user.id, blockedId]);
  await refreshBlocks([user.id, blockedId]);
  return { ok: true };
}, { auth: true });

export async function handleApi(req, res, url) {
  if (req.method === "OPTIONS") {
    res.writeHead(204, corsHeaders(req));
    res.end();
    return;
  }
  try {
    const match = routes.find((entry) => entry.method === req.method && entry.pattern.test(url.pathname));
    if (!match) throw new HttpError(404, "Not found");
    const values = match.pattern.exec(url.pathname).slice(1);
    const params = Object.fromEntries(match.keys.map((key, index) => [key, decodeURIComponent(values[index])]));
    const { options } = match;
    const ctx = { status: 200, handled: false };
    const user = options.auth ? await requireUser(req) : null;
    const body =
      !options.rawBody && ["POST", "PUT", "PATCH", "DELETE"].includes(req.method) ? await readJson(req) : {};
    const result = await match.handler({ req, res, url, params, body, user, ctx });
    if (!ctx.handled) sendJson(req, res, ctx.status, result);
  } catch (error) {
    if (error instanceof HttpError) {
      sendJson(req, res, error.status, { error: error.message, code: error.code });
      return;
    }
    console.error(`${req.method} ${url.pathname} failed:`, error);
    sendJson(req, res, 500, { error: "Máy chủ đang gặp sự cố, vui lòng thử lại sau" });
  }
}
