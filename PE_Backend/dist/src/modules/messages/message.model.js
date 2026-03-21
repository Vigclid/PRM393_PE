"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MessageSchema = void 0;
const mongoose_1 = __importDefault(require("mongoose"));
exports.MessageSchema = new mongoose_1.default.Schema({
    senderId: { type: String, ref: "users", required: true },
    receiverId: { type: String, ref: "users", required: true },
    message: { type: String, required: true },
    dateSent: { type: Date, required: true, default: Date.now },
    isRead: { type: Number, required: true, default: 0 },
});
exports.default = mongoose_1.default.model("messages", exports.MessageSchema);
