import { spawn } from "node:child_process";
import { once } from "node:events";
import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import WebSocket from "ws";

// Runs against a real Postgres: TEST_DATABASE_URL=postgres://localhost:5432/dien_chan_test npm test
const databaseUrl = process.env.TEST_DATABASE_URL || "postgres://localhost:5432/dien_chan_test";
const port = 18000 + Math.floor(Math.random() * 1000);
const base = `http://127.0.0.1:${port}/api/v1`;
let server;
let resetCode = "";

before(async () => {
  server = spawn(process.execPath, ["backend/server.js"], {
    env: {
      ...process.env,
      PORT: String(port),
      DATABASE_URL: databaseUrl,
      NODE_ENV: "test",
      SERVE_WEB: "false",
      ADMIN_TOKEN: "test-admin",
    },
    stdio: ["ignore", "pipe", "inherit"],
  });
  server.stdout.setEncoding("utf8");
  server.stdout.on("data", (chunk) => {
    const match = /Mã xác nhận của bạn là: (\d{6})/.exec(chunk);
    if (match) resetCode = match[1];
  });
  for (let i = 0; i < 50; i += 1) {
    try {
      if ((await fetch(`${base}/health`)).ok) return;
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error("server did not start");
});

after(async () => {
  server.kill("SIGTERM");
  await once(server, "exit");
});

async function api(method, path, { token, body, raw, headers } = {}) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { "Content-Type": "application/json" } : {}),
      ...headers,
    },
    body: raw ?? (body ? JSON.stringify(body) : undefined),
  });
  const text = await response.text();
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch {}
  return { status: response.status, data };
}

const unique = Date.now().toString(36);
const email = `user-${unique}@example.com`;
const password = "mat-khau-123";

test("register, login, profile, password reset and deletion", async () => {
  const weak = await api("POST", "/auth/register", { body: { email, password: "123", fullName: "An" } });
  assert.equal(weak.status, 400);

  const registered = await api("POST", "/auth/register", {
    body: { email, password, fullName: "Nguyễn Văn An", phone: "0901 234 567", country: "Việt Nam" },
  });
  assert.equal(registered.status, 201, JSON.stringify(registered.data));
  assert.equal(registered.data.user.phone, "0901234567");
  assert.equal(registered.data.user.hasPassword, true);

  const duplicate = await api("POST", "/auth/register", { body: { email, password, fullName: "Khác" } });
  assert.equal(duplicate.status, 409);

  const wrong = await api("POST", "/auth/login", { body: { email, password: "sai-mat-khau" } });
  assert.equal(wrong.status, 401);

  const login = await api("POST", "/auth/login", { body: { email: email.toUpperCase(), password } });
  assert.equal(login.status, 200);
  const token = login.data.token;

  assert.equal((await api("GET", "/me")).status, 401);
  const me = await api("GET", "/me", { token });
  assert.equal(me.data.user.fullName, "Nguyễn Văn An");
  assert.deepEqual(me.data.stats, { bookmarks: 0, journals: 0, courseRegistrations: 0 });

  const patched = await api("PATCH", "/me", { token, body: { country: "Canada" } });
  assert.equal(patched.data.user.country, "Canada");

  const settings = await api("PUT", "/me/settings", { token, body: { reminders: true, reminderMinute: 480 } });
  assert.deepEqual(settings.data, { reminders: true, reminderMinute: 480 });

  const png = Buffer.from("89504e470d0a1a0a0000000d49484452", "hex");
  const avatar = await api("PUT", "/me/avatar", { token, raw: png, headers: { "Content-Type": "image/png" } });
  assert.equal(avatar.status, 200);
  assert.ok(avatar.data.user.avatarUpdatedAt);
  const badAvatar = await api("PUT", "/me/avatar", { token, raw: Buffer.from("hello") });
  assert.equal(badAvatar.status, 400);

  const bookmark = await api("POST", "/me/bookmarks", {
    token,
    body: { targetType: "acupoint", targetId: "26", title: "Huyệt 26" },
  });
  assert.equal(bookmark.status, 201);
  const journal = await api("POST", "/me/journals", { token, body: { title: "Day huyệt 26", note: "Đỡ đau", mood: 4 } });
  assert.equal(journal.status, 201);
  assert.equal((await api("GET", "/me/journals", { token })).data.journals.length, 1);

  const course = await api("POST", "/course-registrations", {
    token,
    body: { courseCode: "K48-OFFLINE", fullName: "Nguyễn Văn An", phone: "0901234567" },
  });
  assert.equal(course.status, 201);
  assert.equal(course.data.registration.email, email);
  const badCourse = await api("POST", "/course-registrations", { body: { courseCode: "X", fullName: "A", phone: "1" } });
  assert.equal(badCourse.status, 400);

  const stats = (await api("GET", "/me", { token })).data.stats;
  assert.deepEqual(stats, { bookmarks: 1, journals: 1, courseRegistrations: 1 });

  resetCode = "";
  assert.equal((await api("POST", "/auth/password/forgot", { body: { email } })).status, 200);
  for (let i = 0; i < 20 && !resetCode; i += 1) await new Promise((resolve) => setTimeout(resolve, 50));
  assert.match(resetCode, /^\d{6}$/);
  const badReset = await api("POST", "/auth/password/reset", {
    body: { email, code: resetCode === "000000" ? "111111" : "000000", password: "mat-khau-moi-1" },
  });
  assert.equal(badReset.status, 400);
  const reset = await api("POST", "/auth/password/reset", { body: { email, code: resetCode, password: "mat-khau-moi-1" } });
  assert.equal(reset.status, 200);
  assert.equal((await api("GET", "/me", { token })).status, 401, "old sessions are revoked");
  const newToken = reset.data.token;

  assert.equal((await api("DELETE", "/me", { token: newToken, body: { password } })).status, 400);
  assert.equal((await api("DELETE", "/me", { token: newToken, body: { password: "mat-khau-moi-1" } })).status, 200);
  assert.equal((await api("POST", "/auth/login", { body: { email, password: "mat-khau-moi-1" } })).status, 401);
});

function connect(token) {
  const ws = new WebSocket(`${base.replace("http", "ws")}/realtime`);
  const events = [];
  ws.on("message", (raw) => events.push(JSON.parse(raw.toString())));
  ws.on("open", () => ws.send(JSON.stringify({ type: "auth", token })));
  const waitFor = async (predicate) => {
    for (let i = 0; i < 60; i += 1) {
      const found = events.find(predicate);
      if (found) return found;
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    throw new Error("event not received");
  };
  return { ws, events, waitFor };
}

test("realtime chat, presence, report and block", async () => {
  const register = async (name, country) =>
    (
      await api("POST", "/auth/register", {
        body: { email: `${name}-${unique}@example.com`, password, fullName: name, country },
      })
    ).data;
  const lan = await register("Lan", "Việt Nam");
  const kenji = await register("Kenji", "Nhật Bản");

  const lanSocket = connect(lan.token);
  const kenjiSocket = connect(kenji.token);
  await lanSocket.waitFor((event) => event.type === "presence" && event.users.length >= 2);
  const presence = await kenjiSocket.waitFor((event) => event.type === "presence" && event.users.length >= 2);
  assert.ok(presence.users.some((user) => user.fullName === "Kenji" && user.country === "Nhật Bản"));

  const sent = await api("POST", "/chat/messages", { token: lan.token, body: { body: "Xin chào, đéo ai online?" } });
  assert.equal(sent.status, 201);
  assert.equal(sent.data.message.body, "Xin chào, *** ai online?");
  const received = await kenjiSocket.waitFor((event) => event.type === "chat");
  assert.equal(received.message.author.fullName, "Lan");
  assert.equal(received.message.isMine, false);

  const history = await api("GET", "/chat/messages?limit=10", { token: kenji.token });
  assert.ok(history.data.messages.some((message) => message.id === sent.data.message.id));

  assert.equal(
    (await api("POST", `/chat/messages/${sent.data.message.id}/report`, { token: kenji.token, body: { reason: "spam" } }))
      .status,
    200,
  );
  assert.equal((await api("POST", "/me/blocks", { token: kenji.token, body: { userId: lan.user.id } })).status, 201);
  const afterBlock = await api("GET", "/chat/messages", { token: kenji.token });
  assert.ok(!afterBlock.data.messages.some((message) => message.author.id === lan.user.id));

  await new Promise((resolve) => setTimeout(resolve, 1100));
  kenjiSocket.events.length = 0;
  await api("POST", "/chat/messages", { token: lan.token, body: { body: "Tin thứ hai" } });
  await lanSocket.waitFor((event) => event.type === "chat" && event.message.body === "Tin thứ hai");
  await new Promise((resolve) => setTimeout(resolve, 200));
  assert.ok(!kenjiSocket.events.some((event) => event.type === "chat"), "blocked author is filtered");

  lanSocket.ws.close();
  kenjiSocket.ws.close();
  await api("DELETE", "/me", { token: lan.token, body: { password } });
  await api("DELETE", "/me", { token: kenji.token, body: { password } });
});

test("notifications: welcome, course confirmation, announcements and read state", async () => {
  const notifEmail = `notif-${unique}@example.com`;
  const { data } = await api("POST", "/auth/register", {
    body: { email: notifEmail, password, fullName: "Trần Mai", country: "Việt Nam" },
  });
  const token = data.token;

  let list = await api("GET", "/me/notifications", { token });
  assert.equal(list.status, 200);
  assert.equal(list.data.unread, 1);
  assert.match(list.data.notifications[0].title, /Chào mừng/);

  await api("POST", "/course-registrations", {
    token,
    body: { courseCode: "K49-ONLINE", fullName: "Trần Mai", phone: "0901234567" },
  });
  assert.equal(
    (await api("POST", "/admin/notifications", { body: { title: "Sai token" }, headers: { "X-Admin-Token": "nope" } }))
      .status,
    404,
  );
  const announced = await api("POST", "/admin/notifications", {
    body: { title: "Khai giảng Khóa 50", body: "Đăng ký trong app." },
    headers: { "X-Admin-Token": "test-admin" },
  });
  assert.equal(announced.status, 201);

  list = await api("GET", "/me/notifications", { token });
  assert.equal(list.data.unread, 3);
  assert.deepEqual(
    list.data.notifications.slice(0, 2).map((item) => item.title),
    ["Khai giảng Khóa 50", "Đã nhận đăng ký Khóa 49 - Online"],
  );

  await api("POST", "/me/notifications/read", { token, body: { ids: [list.data.notifications[0].id] } });
  assert.equal((await api("GET", "/me/notifications", { token })).data.unread, 2);
  await api("POST", "/me/notifications/read", { token, body: {} });
  assert.equal((await api("GET", "/me/notifications", { token })).data.unread, 0);

  await api("DELETE", "/me", { token, body: { password } });
});

test("legal pages are served for store listings", async () => {
  const root = base.replace("/api/v1", "");
  for (const path of ["/privacy", "/terms", "/delete-account", "/support"]) {
    const response = await fetch(`${root}${path}`);
    assert.equal(response.status, 200, path);
    const html = await response.text();
    assert.match(html, /<html lang="vi">/);
    assert.doesNotMatch(html, /\{\{/, `${path} has unreplaced placeholders`);
  }
});

test("support requests from guests and signed-in users", async () => {
  const guestMissingContact = await api("POST", "/support-requests", {
    body: { message: "Tôi không đăng nhập được vào ứng dụng." },
  });
  assert.equal(guestMissingContact.status, 400);
  const guest = await api("POST", "/support-requests", {
    body: { message: "Tôi không đăng nhập được vào ứng dụng.", contact: "0901234567" },
  });
  assert.equal(guest.status, 201);

  const supportEmail = `support-${unique}@example.com`;
  const { data } = await api("POST", "/auth/register", {
    body: { email: supportEmail, password, fullName: "Lê Hà" },
  });
  const sent = await api("POST", "/support-requests", {
    token: data.token,
    body: { message: "Camera không mở được trên máy tôi." },
  });
  assert.equal(sent.status, 201);
  const list = await api("GET", "/me/notifications", { token: data.token });
  assert.equal(list.data.notifications[0].title, "Đã nhận yêu cầu hỗ trợ");
  await api("DELETE", "/me", { token: data.token, body: { password } });
});
