const nodemailer = require("nodemailer");

function randomInt(min: number, max?: number): number {
  if (max === undefined) {
    max = min;
    min = 0;
  }
  return Math.floor(Math.random() * (max - min)) + min;
}

export class MailService {
  /**
   * @param email
   * @returns
   */
  static async generateAndSendToken(email: string): Promise<string> {
    const token = String(100000 + randomInt(900000));

    const host = process.env.SMTP_HOST || process.env.SMTP_HOSTNAME || "smtp.gmail.com";
    const port = Number(process.env.SMTP_PORT || 587);
    const user = process.env.SMTP_USER || process.env.SMTP_USERNAME || "";
    const pass = process.env.SMTP_PASS || process.env.SMTP_PASSWORD || "";

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: {
        user,
        pass,
      },
      tls: {
        rejectUnauthorized: false,
      },
    });

    const subject = "Your Verification Token";
    const html = MailService.buildEmailContent(token);

    try {
      await transporter.sendMail({
        from: `"Arthub" <${user}>`,
        to: email,
        subject,
        html,
      });
    } catch (err) {
      throw err;
    }

    return token;
  }

  private static buildEmailContent(token: string): string {
    return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <style>
      body { font-family: Arial, sans-serif; text-align: center; padding: 0; margin: 0; }
      .container { padding: 20px; max-width: 600px; margin: 24px auto; border: 1px solid #eee; border-radius: 8px; }
      .logo { width: 96px; margin: 8px auto; display:block; }
      .token { font-size: 28px; font-weight: 700; color: #d9534f; margin: 12px 0; }
      .footer { margin-top: 18px; font-size: 12px; color: #777; }
      .banner { width: 100%; border-radius: 6px; margin-top: 8px; }
    </style>
  </head>
  <body>
    <div class="container">
      <img class="logo" src="https://res.cloudinary.com/dx8iuner7/image/upload/Union_w8qgub.png" alt="logo" />
      <img class="banner" src="https://res.cloudinary.com/dx8iuner7/image/upload/ArtHubBanner_jpncuk.png" alt="banner" />
      <h2>Your Verification Token</h2>
      <p>Use the following code to verify your email:</p>
      <p class="token">${token}</p>
      <p>This token is valid for 10 minutes.</p>
      <div class="footer">
        <p>Follow us on:</p>
        <div>
          <a href="https://facebook.com/namson03"><img src="https://upload.wikimedia.org/wikipedia/commons/c/cd/Facebook_logo_%28square%29.png" alt="Facebook" width="28" /></a>
          <a href="https://instagram.com/namson.10"><img src="https://upload.wikimedia.org/wikipedia/commons/a/a5/Instagram_icon.png" alt="Instagram" width="28" /></a>
          
        </div>
      </div>
    </div>
  </body>
</html>`;
  }
}

export default MailService;
