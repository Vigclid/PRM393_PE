"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const mail_controller_1 = require("./mail.controller");
const router = (0, express_1.Router)();
router.route("/token").post(mail_controller_1.MailController.sendTokenMail);
exports.default = router;
