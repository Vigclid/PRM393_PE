"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const logger_1 = __importDefault(require("../utils/logger"));
const loggerMiddleware = (req, res, next) => {
    const start = Date.now(); // thời gian bắt đầu request
    const hasBody = ["POST", "PUT", "PATCH"].includes(req.method);
    let safeBody = {};
    if (hasBody && req.body && Object.keys(req.body).length > 0) {
        safeBody = { ...req.body };
        const sensitiveFields = ["password", "token", "otp", "secret", "privateKey"];
        for (const field of sensitiveFields) {
            if (safeBody[field])
                safeBody[field] = "***hidden***";
        }
    }
    res.on("finish", () => {
        const duration = Date.now() - start;
        const clientIp = req.headers["x-forwarded-for"]?.toString().split(",")[0] ||
            req.socket.remoteAddress ||
            req.ip;
        const origin = req.headers.origin || "unknown";
        const host = req.headers.host || "unknown";
        const userAgent = req.headers["user-agent"] || "unknown";
        logger_1.default.info("HTTP Request", {
            method: req.method,
            url: req.originalUrl,
            status: res.statusCode,
            response_time: duration,
            ip: clientIp,
            origin,
            host,
            userAgent,
            body: hasBody ? safeBody : undefined,
        });
    });
    next();
};
exports.default = loggerMiddleware;
