"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.connectDB = void 0;
const mongoose_1 = __importDefault(require("mongoose"));
let isConnected = false;
const connectDB = async () => {
    try {
        if (isConnected)
            return;
        await mongoose_1.default.connect(process.env.MONGO_URI, {
            autoIndex: true,
            maxPoolSize: 10,
            serverSelectionTimeoutMS: 5000,
        });
        isConnected = true;
    }
    catch (error) {
        process.exit(1);
    }
};
exports.connectDB = connectDB;
