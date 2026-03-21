"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatSchema = void 0;
const mongoose_1 = __importDefault(require("mongoose"));
exports.ChatSchema = new mongoose_1.default.Schema({
    user1Id: { type: String, ref: "users", required: true },
    user2Id: { type: String, ref: "users", required: true },
    status: { type: Number, required: true },
});
exports.default = mongoose_1.default.model("chats", exports.ChatSchema);
