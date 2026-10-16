import { config } from "./config.js";
import { HttpError } from "./http.js";

export const mailConfigured = () => Boolean(config.mail.resendApiKey);

/** Without RESEND_API_KEY, local development prints emails to the console instead of sending. */
export const canSendMail = () => mailConfigured() || !config.isProduction;

export async function sendMail({ to, subject, text }) {
  if (!mailConfigured()) {
    if (config.isProduction) throw new HttpError(503, "Máy chủ chưa cấu hình gửi email");
    console.log(`\n[mail:dev] To: ${to}\nSubject: ${subject}\n${text}\n`);
    return;
  }
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${config.mail.resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from: config.mail.from, to: [to], subject, text }),
  });
  if (!response.ok) {
    console.error("Resend error:", response.status, await response.text().catch(() => ""));
    throw new HttpError(502, "Không gửi được email, vui lòng thử lại sau");
  }
}
