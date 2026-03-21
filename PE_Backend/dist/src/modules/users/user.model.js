"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserSchema = void 0;
const mongoose_1 = __importStar(require("mongoose"));
exports.UserSchema = new mongoose_1.default.Schema({
    coins: { type: String, required: true, default: "0" },
    profilePicture: { type: String, required: false },
    backgroundPicture: { type: String, required: false },
    firstName: { type: String, required: false },
    lastName: { type: String, required: false },
    address: { type: String, required: false },
    phoneNumber: { type: String, required: false },
    lastLogin: { type: String, required: true, default: new Date() },
    CreateAt: { type: String, required: true, default: new Date() },
    dateOfBirth: { type: String, required: false, default: "" },
    allowCommission: { type: Boolean, required: false },
    biography: { type: String, required: false },
    followCounts: { type: Number, required: false, default: 0 },
    followerCount: { type: Number, required: false, default: 0 },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    roleID: {
        type: mongoose_1.Types.ObjectId,
        required: true,
        ref: "roles",
    },
    loginFailedCounts: { type: Number, required: false, default: 0 },
    loginFailedTime: { type: Date || null, required: false, default: null },
    isActive: { type: Boolean, required: true, default: true },
});
exports.default = mongoose_1.default.model("users", exports.UserSchema);
