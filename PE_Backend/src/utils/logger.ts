import { createLogger, format, transports } from "winston";
import "winston-mongodb";

const { combine, timestamp, printf, colorize } = format;

const logFormat = printf(({ level, message, timestamp }) => {
  return `${timestamp} [${level}]: ${message}`;
});

const logger = createLogger({
  level: "info",
  format: combine(timestamp({ format: "YYYY-MM-DD HH:mm:ss" }), logFormat),
  transports: [
    new transports.Console({
      format: combine(colorize(), timestamp(), logFormat),
    }),

    // Log File COMMENT IF ON PRODUCTION
    // new transports.File({ filename: "logs/error.log", level: "error" }),
    // new transports.File({ filename: "logs/combined.log" }),

    // MongoDB Log
    new transports.MongoDB({
      db: process.env.MONGO_URI as string,
      options: { useUnifiedTopology: true },
      collection: "app_logs",
      level: "info",
      metaKey: "meta",
      tryReconnect: true,
    }),
  ],
});

export default logger;
