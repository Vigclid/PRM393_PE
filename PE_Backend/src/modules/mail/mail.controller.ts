import { MailService } from "./mail.service";
import { Request, Response } from "express";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";

export class MailController {
  static sendTokenMail = async (req: Request, res: Response) => {
    try {
      const { email } = req.body;
      if (!email || email.trim() === "") {
        return res.status(400).json(responseWrapper("error", "Email is required"));
      }
      const token = await MailService.generateAndSendToken(String(email));
      return res.status(200).json(responseWrapper("success", "Token sent successfully", { token }));
    } catch (error) {
      return res.status(500).json(responseWrapper("error", "Internal Server Error"));
    }
  };
}
