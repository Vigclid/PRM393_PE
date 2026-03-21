import { Request, Response, NextFunction } from "express";
import { responseWrapper } from "../interfaces/wrapper/ApiResponseWrapper";
import mongoose from "mongoose";

/**
 * Middleware to validate message content and user IDs
 * Validates:
 * - Message content is non-empty and <= 2000 characters
 * - Sanitizes HTML and script tags to prevent XSS
 * - Validates user IDs are valid MongoDB ObjectIds
 */
export function validateMessage(req: Request, res: Response, next: NextFunction) {
  const { message, receiverId } = req.body;

  // Validate message content exists
  if (!message || typeof message !== "string") {
    return res.status(400).json(
      responseWrapper("error", "Message content is required", null)
    );
  }

  // Validate message is non-empty after trimming
  const trimmedMessage = message.trim();
  if (trimmedMessage.length === 0) {
    return res.status(400).json(
      responseWrapper("error", "Message content cannot be empty", null)
    );
  }

  // Validate message length <= 2000 characters
  if (trimmedMessage.length > 2000) {
    return res.status(400).json(
      responseWrapper("error", "Message content cannot exceed 2000 characters", null)
    );
  }

  // Sanitize HTML and script tags to prevent XSS
  // Remove <script> tags and their content
  let sanitizedMessage = trimmedMessage.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, "");
  
  // Remove all HTML tags
  sanitizedMessage = sanitizedMessage.replace(/<[^>]*>/g, "");
  
  // Remove javascript: protocol from any remaining text
  sanitizedMessage = sanitizedMessage.replace(/javascript:/gi, "");
  
  // Remove on* event handlers (onclick, onerror, etc.)
  sanitizedMessage = sanitizedMessage.replace(/on\w+\s*=/gi, "");

  // Trim again after sanitization
  sanitizedMessage = sanitizedMessage.trim();

  // Check if message is empty after sanitization
  if (sanitizedMessage.length === 0) {
    return res.status(400).json(
      responseWrapper("error", "Message content cannot be empty", null)
    );
  }

  // Update the request body with sanitized message
  req.body.message = sanitizedMessage;

  // Validate receiverId if present
  if (receiverId) {
    if (!mongoose.Types.ObjectId.isValid(receiverId)) {
      return res.status(400).json(
        responseWrapper("error", "Invalid receiver ID format", null)
      );
    }
  }

  next();
}
