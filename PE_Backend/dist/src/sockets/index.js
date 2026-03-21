"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.initSocketServer = void 0;
const sockjs_1 = __importDefault(require("sockjs"));
const socketHandler_1 = require("./socketHandler");
const initSocketServer = (server) => {
    const sockServer = sockjs_1.default.createServer({
        prefix: "/ws",
        log: (severity, message) => {
            if (severity === "error")
                console.error(message);
        },
    });
    sockServer.on("connection", socketHandler_1.handleSocketConnection);
    sockServer.installHandlers(server, { prefix: "/ws" });
};
exports.initSocketServer = initSocketServer;
