import { Router } from "express";
import { MailController } from "./mail.controller";

const router = Router();
router.route("/token").post(MailController.sendTokenMail);

export default router;
