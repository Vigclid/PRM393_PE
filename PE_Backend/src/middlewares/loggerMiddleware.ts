import { NextFunction, Request, Response } from "express";
import logger from "../utils/logger";

const loggerMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const start = Date.now(); // thời gian bắt đầu request
  const hasBody = ["POST", "PUT", "PATCH"].includes(req.method);

  let safeBody: any = {};
  if (hasBody && req.body && Object.keys(req.body).length > 0) {
    safeBody = { ...req.body };
    const sensitiveFields = ["password", "token", "otp", "secret", "privateKey"];
    for (const field of sensitiveFields) {
      if (safeBody[field]) safeBody[field] = "***hidden***";
    }
  }

  res.on("finish", () => {
    const duration = Date.now() - start;
    const clientIp =
      req.headers["x-forwarded-for"]?.toString().split(",")[0] ||
      req.socket.remoteAddress ||
      req.ip;

    const origin = req.headers.origin || "unknown";
    const host = req.headers.host || "unknown";
    const userAgent = req.headers["user-agent"] || "unknown";

    logger.info("HTTP Request", {
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

export default loggerMiddleware;
