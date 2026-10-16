import { WebSocketServer } from "ws";
import { userFromToken } from "./auth.js";
import { query } from "./db.js";

export const REALTIME_PATH = "/api/v1/realtime";

/** ws -> { user, blocked: Set<userId>, blockedBy: Set<userId> } */
const clients = new Map();

const send = (ws, payload) => {
  if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(payload));
};

export function presenceUser(user) {
  return { id: user.id, fullName: user.full_name || "Thành viên", country: user.country || "" };
}

export function onlineUsers() {
  const unique = new Map();
  for (const { user } of clients.values()) unique.set(user.id, presenceUser(user));
  return [...unique.values()].sort((a, b) => a.fullName.localeCompare(b.fullName, "vi"));
}

let presenceTimer;
function broadcastPresence() {
  clearTimeout(presenceTimer);
  presenceTimer = setTimeout(() => {
    const users = onlineUsers();
    for (const ws of clients.keys()) send(ws, { type: "presence", users });
  }, 250);
}

async function loadBlocks(userId) {
  const { rows } = await query(
    `SELECT user_id, blocked_user_id FROM user_blocks WHERE user_id = $1 OR blocked_user_id = $1`,
    [userId],
  );
  return {
    blocked: new Set(rows.filter((row) => row.user_id === userId).map((row) => row.blocked_user_id)),
    blockedBy: new Set(rows.filter((row) => row.blocked_user_id === userId).map((row) => row.user_id)),
  };
}

export function broadcastChatMessage(message) {
  for (const [ws, client] of clients) {
    const authorId = message.author.id;
    if (client.blocked.has(authorId) || client.blockedBy.has(authorId)) continue;
    send(ws, { type: "chat", message: { ...message, isMine: authorId === client.user.id } });
  }
}

export function broadcast(payload) {
  for (const ws of clients.keys()) send(ws, payload);
}

export function sendToUser(userId, payload) {
  for (const [ws, client] of clients) {
    if (client.user.id === userId) send(ws, payload);
  }
}

export async function refreshBlocks(userIds) {
  for (const [, client] of clients) {
    if (userIds.includes(client.user.id)) Object.assign(client, await loadBlocks(client.user.id));
  }
}

export function refreshUser(user) {
  for (const client of clients.values()) {
    if (client.user.id === user.id) client.user = user;
  }
  broadcastPresence();
}

export function disconnectUser(userId) {
  for (const [ws, client] of clients) {
    if (client.user.id === userId) ws.close(4401, "signed out");
  }
}

export function attachRealtime(server) {
  const wss = new WebSocketServer({ noServer: true, maxPayload: 8 * 1024 });

  server.on("upgrade", (req, socket, head) => {
    const { pathname } = new URL(req.url || "/", "http://localhost");
    if (pathname !== REALTIME_PATH) {
      socket.destroy();
      return;
    }
    wss.handleUpgrade(req, socket, head, (ws) => wss.emit("connection", ws, req));
  });

  wss.on("connection", (ws) => {
    ws.isAlive = true;
    ws.on("pong", () => {
      ws.isAlive = true;
    });
    // The token travels in the first message, not the URL, so it never lands in proxy logs.
    const authTimer = setTimeout(() => ws.close(4401, "auth timeout"), 10_000);

    ws.on("message", async (raw) => {
      let message;
      try {
        message = JSON.parse(raw.toString());
      } catch {
        return;
      }
      if (message?.type === "auth" && !clients.has(ws)) {
        try {
          const user = await userFromToken(String(message.token || ""));
          if (!user) {
            ws.close(4401, "unauthorized");
            return;
          }
          if (ws.readyState !== ws.OPEN) return;
          clearTimeout(authTimer);
          clients.set(ws, { user, ...(await loadBlocks(user.id)) });
          send(ws, { type: "ready", userId: user.id });
          send(ws, { type: "presence", users: onlineUsers() });
          broadcastPresence();
        } catch (error) {
          console.error("Realtime auth failed:", error.message);
          ws.close(1011, "server error");
        }
        return;
      }
      if (message?.type === "ping") send(ws, { type: "pong" });
    });

    ws.on("close", () => {
      clearTimeout(authTimer);
      if (clients.delete(ws)) broadcastPresence();
    });
    ws.on("error", () => {});
  });

  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) {
      if (!ws.isAlive) {
        ws.terminate();
        continue;
      }
      ws.isAlive = false;
      ws.ping();
    }
  }, 30_000);
  wss.on("close", () => clearInterval(heartbeat));
  return wss;
}
