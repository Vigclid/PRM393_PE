import rateLimit from "express-rate-limit";
import { Request, Response } from "express";
import jwt from "jsonwebtoken";

/**
 * Rate limiter for message sending: 10 messages per minute per user
 * Validates: Requirements 8.4
 */
export const messageRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 requests per minute
  message: {
    status: "error",
    message: "Too many messages sent. Please try again later.",
    data: null,
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Use user ID from JWT token as the key
  keyGenerator: (req: Request): string => {
    try {
      const token = req.headers["authorization"]?.split(" ")[1];
      if (token) {
        const decoded = jwt.decode(token) as { id: string };
        return decoded.id || "unknown";
      }
      return "unknown";
    } catch {
      return "unknown";
    }
  },
  handler: (_req: Request, res: Response) => {
    res.status(429).json({
      status: "error",
      message: "Rate limit exceeded: Maximum 10 messages per minute allowed",
      data: null,
    });
  },
  // Skip IP-based rate limiting since we're using user ID
  skip: (req: Request) => {
    const token = req.headers["authorization"]?.split(" ")[1];
    return !token; // Skip rate limiting if no token (will be handled by auth middleware)
  },
});
