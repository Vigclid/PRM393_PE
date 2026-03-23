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

/**
 * Rate limiter for comment creation: 10 comments per minute per user
 * Validates: Requirements 11.1
 */
export const commentRateLimiterPerMinute = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 requests per minute
  message: {
    status: "error",
    message: "Too many comments created. Please try again later.",
    data: null,
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req: Request): string => {
    try {
      const token = req.headers["authorization"]?.split(" ")[1];
      if (token) {
        const decoded = jwt.decode(token) as { id: string };
        return `comment-minute-${decoded.id || "unknown"}`;
      }
      return "comment-minute-unknown";
    } catch {
      return "comment-minute-unknown";
    }
  },
  handler: (_req: Request, res: Response) => {
    res.status(429).json({
      status: "error",
      message: "Rate limit exceeded: Maximum 10 comments per minute allowed",
      data: null,
    });
  },
  skip: (req: Request) => {
    const token = req.headers["authorization"]?.split(" ")[1];
    return !token;
  },
});

/**
 * Rate limiter for comment creation: 50 comments per hour per user
 * Validates: Requirements 11.2
 */
export const commentRateLimiterPerHour = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 50, // 50 requests per hour
  message: {
    status: "error",
    message: "Too many comments created. Please try again later.",
    data: null,
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req: Request): string => {
    try {
      const token = req.headers["authorization"]?.split(" ")[1];
      if (token) {
        const decoded = jwt.decode(token) as { id: string };
        return `comment-hour-${decoded.id || "unknown"}`;
      }
      return "comment-hour-unknown";
    } catch {
      return "comment-hour-unknown";
    }
  },
  handler: (_req: Request, res: Response) => {
    res.status(429).json({
      status: "error",
      message: "Rate limit exceeded: Maximum 50 comments per hour allowed",
      data: null,
    });
  },
  skip: (req: Request) => {
    const token = req.headers["authorization"]?.split(" ")[1];
    return !token;
  },
});

/**
 * Rate limiter for reply creation: 20 replies per minute per user
 * Validates: Requirements 11.3
 */
export const replyRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 20, // 20 requests per minute
  message: {
    status: "error",
    message: "Too many replies created. Please try again later.",
    data: null,
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req: Request): string => {
    try {
      const token = req.headers["authorization"]?.split(" ")[1];
      if (token) {
        const decoded = jwt.decode(token) as { id: string };
        return `reply-${decoded.id || "unknown"}`;
      }
      return "reply-unknown";
    } catch {
      return "reply-unknown";
    }
  },
  handler: (_req: Request, res: Response) => {
    res.status(429).json({
      status: "error",
      message: "Rate limit exceeded: Maximum 20 replies per minute allowed",
      data: null,
    });
  },
  skip: (req: Request) => {
    const token = req.headers["authorization"]?.split(" ")[1];
    return !token;
  },
});
