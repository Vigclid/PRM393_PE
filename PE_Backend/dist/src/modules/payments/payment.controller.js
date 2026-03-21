"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentController = void 0;
const user_service_1 = require("../users/user.service");
const base_controller_1 = require("../../core/controllers/base.controller");
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const axios_1 = __importDefault(require("axios"));
const crypto_1 = __importDefault(require("crypto"));
const qrcode_1 = __importDefault(require("qrcode"));
class PaymentController extends base_controller_1.GenericController {
    constructor(paymentService) {
        super(paymentService);
        this.getQrCode = async (req, res) => {
            const IQrInfor = req.body;
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const deposite = 25000;
                const orderCode = Number(Date.now().toString().slice(4, 9).concat(IQrInfor.description));
                const cancelUrl = "https://example.com/payment/cancel";
                const returnUrl = "https://example.com/payment/success";
                const dataToSign = `amount=${IQrInfor.amount}&cancelUrl=${cancelUrl}&description=${IQrInfor.description}&orderCode=${orderCode}&returnUrl=${returnUrl}`;
                const signature = crypto_1.default
                    .createHmac("sha256", process.env.PAYOS_CHECKSUM_KEY)
                    .update(dataToSign)
                    .digest("hex");
                const response = await axios_1.default.post("https://api-merchant.payos.vn/v2/payment-requests", {
                    orderCode,
                    amount: IQrInfor.amount,
                    description: IQrInfor.description,
                    cancelUrl,
                    returnUrl,
                    signature,
                }, {
                    headers: {
                        "x-client-id": process.env.PAYOS_CLIENT_ID,
                        "x-api-key": process.env.PAYOS_API_KEY,
                        "Content-Type": "application/json",
                    },
                });
                if (response.data.data == null) {
                    return res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Server error", response.data));
                }
                else {
                    await this.PaymentService.create({
                        userId: id,
                        orderCode,
                        amount: IQrInfor.amount / deposite,
                        status: false,
                    });
                    const qrCodeDataURL = await qrcode_1.default.toDataURL(response.data.data.qrCode);
                    response.data.data.qrCode = qrCodeDataURL;
                    return res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Success", response.data.data));
                }
            }
            catch (err) {
                return res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Server error"));
            }
        };
        this.acceptPayment = async (req, res) => {
            try {
                const { orderCode } = req.body;
                if (!orderCode)
                    return res.status(400).json({ message: "Missing orderCode" });
                const response = await axios_1.default.get(`https://api-merchant.payos.vn/v2/payment-requests/${orderCode}`, {
                    headers: {
                        "x-client-id": process.env.PAYOS_CLIENT_ID,
                        "x-api-key": process.env.PAYOS_API_KEY,
                    },
                });
                if (response.data.data.status === "PAID") {
                    const payment = (await this.PaymentService.acceptPayment(Number(orderCode)));
                    await new user_service_1.userService().updateCoinForPayment(payment.userId, payment.amount);
                    return res.status(200).json({ status: "success", message: "Payment accepted" });
                }
                else {
                    return res.status(200).json({ status: "pending", message: "Payment pending" });
                }
            }
            catch (error) {
                res.status(500).json({ message: "Error checking order" });
            }
        };
        this.PaymentService = paymentService;
    }
}
exports.PaymentController = PaymentController;
