"use strict";
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.MailController = void 0;
const mail_service_1 = require("./mail.service");
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
class MailController {
}
exports.MailController = MailController;
_a = MailController;
MailController.sendTokenMail = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email || email.trim() === "") {
            return res.status(400).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Email is required"));
        }
        const token = await mail_service_1.MailService.generateAndSendToken(String(email));
        return res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Token sent successfully", { token }));
    }
    catch (error) {
        return res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Internal Server Error"));
    }
};
