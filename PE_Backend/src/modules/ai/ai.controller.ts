import { Request, Response } from "express";
import { AIService } from "./ai.service";
import { responseWrapper } from "../../interfaces/wrapper/ApiResponseWrapper";

const aiService = new AIService();

export class AIController {
  static async sendMessage(req: Request, res: Response): Promise<void> {
    try {
      const { message, productId } = req.body;
      const userId = (req as any).user?.id;

      if (!userId) {
        res.status(401).json(
          responseWrapper(false, "Unauthorized", null)
        );
        return;
      }

      if (!message) {
        res.status(400).json(
          responseWrapper(false, "Message is required", null)
        );
        return;
      }

      const result = await aiService.sendMessage(userId, message, productId);
      const wrappedResponse = responseWrapper(true, "Message sent successfully", result);
      res.status(200).json(wrappedResponse);
    } catch (error) {
      res.status(500).json(
        responseWrapper(false, `Error: ${error}`, null)
      );
    }
  }

  static async getChatHistory(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      const { productId } = req.query;

      if (!userId) {
        res.status(401).json(
          responseWrapper(false, "Unauthorized", null)
        );
        return;
      }

      const history = await aiService.getChatHistory(
        userId,
        productId as string
      );

      res.status(200).json(
        responseWrapper(true, "Chat history retrieved", history)
      );
    } catch (error) {
      res.status(500).json(
        responseWrapper(false, `Error: ${error}`, null)
      );
    }
  }

  static async clearChatHistory(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.id;
      const { productId } = req.body;

      if (!userId) {
        res.status(401).json(
          responseWrapper(false, "Unauthorized", null)
        );
        return;
      }

      await aiService.clearChatHistory(userId, productId);

      res.status(200).json(
        responseWrapper(true, "Chat history cleared", null)
      );
    } catch (error) {
      res.status(500).json(
        responseWrapper(false, `Error: ${error}`, null)
      );
    }
  }
}
