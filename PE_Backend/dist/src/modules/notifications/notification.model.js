"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationSchema = void 0;
const mongoose_1 = __importDefault(require("mongoose"));
exports.NotificationSchema = new mongoose_1.default.Schema({
    message: { type: String, required: true },
    createAt: { type: Date, required: true },
    interactId: { type: String, required: false },
    artworkId: { type: String, ref: "artworks", required: false },
    profileNotifyId: { type: String, ref: "users", required: false },
    followId: { type: String, required: false },
    isRead: { type: Number, required: true, default: 0 },
    amount: { type: Number, required: false },
    profileReceiveId: { type: String, ref: "users", required: true },
});
exports.default = mongoose_1.default.model("notifications", exports.NotificationSchema);
