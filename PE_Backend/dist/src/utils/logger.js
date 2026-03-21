"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const winston_1 = require("winston");
require("winston-mongodb");
const { combine, timestamp, printf, colorize } = winston_1.format;
const logFormat = printf(({ level, message, timestamp }) => {
    return `${timestamp} [${level}]: ${message}`;
});
const logger = (0, winston_1.createLogger)({
    level: "info",
    format: combine(timestamp({ format: "YYYY-MM-DD HH:mm:ss" }), logFormat),
    transports: [
        new winston_1.transports.Console({
            format: combine(colorize(), timestamp(), logFormat),
        }),
        // Log File COMMENT IF ON PRODUCTION
        // new transports.File({ filename: "logs/error.log", level: "error" }),
        // new transports.File({ filename: "logs/combined.log" }),
        // MongoDB Log
        new winston_1.transports.MongoDB({
            db: process.env.MONGO_URI,
            options: { useUnifiedTopology: true },
            collection: "app_logs",
            level: "info",
            metaKey: "meta",
            tryReconnect: true,
        }),
    ],
});
exports.default = logger;
