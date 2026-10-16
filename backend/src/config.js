const list = (value) =>
  (value || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);

const onRailway = Boolean(process.env.RAILWAY_ENVIRONMENT_NAME || process.env.RAILWAY_ENVIRONMENT);

export const config = {
  appName: "Sổ tay điện tử Diện Chẩn",
  host: process.env.HOST || (onRailway ? "0.0.0.0" : "127.0.0.1"),
  port: Number(process.env.PORT || 5173),
  isProduction: process.env.NODE_ENV === "production" || onRailway,
  databaseUrl: process.env.DATABASE_URL || "postgres://localhost:5432/dien_chan",
  // Railway Postgres requires TLS; allow override with PGSSL=false for local tunnels.
  databaseSsl:
    process.env.PGSSL === "true" ||
    (onRailway && process.env.PGSSL !== "false"),
  corsOrigins: list(process.env.CORS_ORIGINS || "*"),
  sessionDays: Number(process.env.SESSION_DAYS || 90),
  adminToken: process.env.ADMIN_TOKEN || "",
  adminEmail: process.env.ADMIN_EMAIL || "",
  serveWeb: process.env.SERVE_WEB !== "false" && !onRailway,
  mail: {
    resendApiKey: process.env.RESEND_API_KEY || "",
    from: process.env.MAIL_FROM || "Diện Chẩn <onboarding@resend.dev>",
  },
  apple: {
    // Bundle ID (iOS) and/or Services ID (web/Android), comma separated.
    clientIds: list(process.env.APPLE_CLIENT_IDS),
    teamId: process.env.APPLE_TEAM_ID || "",
    keyId: process.env.APPLE_KEY_ID || "",
    privateKey: (process.env.APPLE_PRIVATE_KEY || "").replace(/\\n/g, "\n"),
  },
};
