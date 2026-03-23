import { Router } from "express";
import { AIController } from "./ai.controller";
import { authenticate } from "../../middlewares/authMiddleware";

const router = Router();

// AI Chat Routes
router.post("/send-message", authenticate, AIController.sendMessage);
router.get("/chat-history", authenticate, AIController.getChatHistory);
router.post("/clear-history", authenticate, AIController.clearChatHistory);

export default router;
