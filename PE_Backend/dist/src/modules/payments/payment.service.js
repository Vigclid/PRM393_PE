"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.paymentService = void 0;
const base_service_1 = require("../../core/services/base.service");
const payment_model_1 = __importDefault(require("./payment.model"));
class paymentService extends base_service_1.GenericService {
    constructor() {
        super(payment_model_1.default);
        this.purchaseCoins = async (data) => {
            return await payment_model_1.default.create(data);
        };
        this.acceptPayment = async (orderCode) => {
            return await payment_model_1.default.findOneAndUpdate({ orderCode }, { $set: { status: true } }, { new: true });
        };
    }
}
exports.paymentService = paymentService;
