"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TodoSchema = void 0;
const mongoose_1 = __importDefault(require("mongoose"));
exports.TodoSchema = new mongoose_1.default.Schema({
    text: { type: String, required: true },
    done: { type: Boolean, required: true, default: false },
    userId: { type: String, ref: "users", required: false },
    createdAt: { type: Date, required: false, default: new Date() },
});
exports.default = mongoose_1.default.model("todos", exports.TodoSchema);
