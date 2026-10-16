import { createHash, randomBytes, randomInt, scrypt as scryptCallback, timingSafeEqual } from "node:crypto";
import { promisify } from "node:util";
import { createRemoteJWKSet, importPKCS8, jwtVerify, SignJWT } from "jose";
import { config } from "./config.js";
import { one, query } from "./db.js";
import { HttpError } from "./http.js";

const scrypt = promisify(scryptCallback);
const SCRYPT = { N: 16384, r: 8, p: 1 };

export const sha256 = (value) => createHash("sha256").update(value).digest("hex");

export async function hashPassword(password) {
  const salt = randomBytes(16);
  const key = await scrypt(password.normalize("NFKC"), salt, 64, SCRYPT);
  return `scrypt$${SCRYPT.N}$${SCRYPT.r}$${SCRYPT.p}$${salt.toString("base64")}$${key.toString("base64")}`;
}

export async function verifyPassword(password, stored) {
  if (!stored || typeof password !== "string") return false;
  const [scheme, n, r, p, salt, hash] = stored.split("$");
  if (scheme !== "scrypt" || !salt || !hash) return false;
  const expected = Buffer.from(hash, "base64");
  const actual = await scrypt(password.normalize("NFKC"), Buffer.from(salt, "base64"), expected.length, {
    N: Number(n),
    r: Number(r),
    p: Number(p),
  });
  return timingSafeEqual(expected, actual);
}

/** Compared against when the account does not exist, so timing does not reveal registered emails. */
let dummyHash;
export async function burnPasswordCheck(password) {
  dummyHash ??= await hashPassword("dien-chan-placeholder");
  await verifyPassword(String(password || ""), dummyHash);
}

export async function createSession(userId, userAgent = "") {
  const token = randomBytes(32).toString("base64url");
  await query(
    `INSERT INTO sessions (token_hash, user_id, user_agent, expires_at)
     VALUES ($1, $2, $3, now() + make_interval(days => $4))`,
    [sha256(token), userId, String(userAgent).slice(0, 300), config.sessionDays],
  );
  return token;
}

export function bearerToken(req) {
  const header = req.headers.authorization || "";
  const match = /^Bearer\s+(.+)$/i.exec(header);
  return match ? match[1].trim() : "";
}

/** Every user column except the avatar bytes, which are only read by the avatar endpoint. */
export const USER_COLUMNS = `id, email, password_hash, apple_sub, apple_client_id, apple_refresh_token,
  full_name, phone, country, avatar_type, avatar_updated_at, settings, created_at, updated_at`;
const USER_COLUMNS_U = USER_COLUMNS.split(",")
  .map((column) => `u.${column.trim()}`)
  .join(", ");

export async function userFromToken(token) {
  if (!token || token.length > 200) return null;
  return one(
    `UPDATE sessions s SET last_used_at = now(),
       expires_at = GREATEST(s.expires_at, now() + make_interval(days => $2))
     FROM users u
     WHERE s.token_hash = $1 AND s.expires_at > now() AND u.id = s.user_id
     RETURNING ${USER_COLUMNS_U}`,
    [sha256(token), config.sessionDays],
  );
}

export async function requireUser(req) {
  const user = await userFromToken(bearerToken(req));
  if (!user) throw new HttpError(401, "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại", "unauthorized");
  return user;
}

export async function revokeSession(token) {
  await query("DELETE FROM sessions WHERE token_hash = $1", [sha256(token)]);
}

export function newResetCode() {
  return String(randomInt(0, 1_000_000)).padStart(6, "0");
}

const appleJwks = createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys"));

export async function verifyAppleIdentityToken(identityToken, rawNonce) {
  if (!config.apple.clientIds.length) {
    throw new HttpError(503, "Đăng nhập Apple chưa được cấu hình trên máy chủ");
  }
  try {
    const { payload } = await jwtVerify(identityToken, appleJwks, {
      issuer: "https://appleid.apple.com",
      audience: config.apple.clientIds,
    });
    if (rawNonce && payload.nonce !== sha256(rawNonce)) throw new Error("nonce mismatch");
    if (!payload.sub) throw new Error("missing subject");
    return payload;
  } catch {
    throw new HttpError(401, "Không xác thực được tài khoản Apple");
  }
}

const appleRevocationEnabled = () => Boolean(config.apple.teamId && config.apple.keyId && config.apple.privateKey);

async function appleClientSecret(clientId) {
  const key = await importPKCS8(config.apple.privateKey, "ES256");
  return new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: config.apple.keyId })
    .setIssuer(config.apple.teamId)
    .setSubject(clientId)
    .setAudience("https://appleid.apple.com")
    .setIssuedAt()
    .setExpirationTime("5m")
    .sign(key);
}

async function postAppleForm(path, body) {
  return fetch(`https://appleid.apple.com${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(body),
  });
}

/** Refresh token is kept only so the account can be revoked on deletion (App Store 5.1.1(v)). */
export async function exchangeAppleCode(code, clientId) {
  if (!code || !appleRevocationEnabled()) return null;
  try {
    const response = await postAppleForm("/auth/token", {
      client_id: clientId,
      client_secret: await appleClientSecret(clientId),
      code,
      grant_type: "authorization_code",
    });
    if (!response.ok) return null;
    const data = await response.json();
    return data.refresh_token || null;
  } catch (error) {
    console.warn("Apple code exchange failed:", error.message);
    return null;
  }
}

export async function revokeAppleToken(refreshToken, clientId) {
  if (!refreshToken || !clientId || !appleRevocationEnabled()) return;
  try {
    await postAppleForm("/auth/revoke", {
      client_id: clientId,
      client_secret: await appleClientSecret(clientId),
      token: refreshToken,
      token_type_hint: "refresh_token",
    });
  } catch (error) {
    console.warn("Apple token revocation failed:", error.message);
  }
}
