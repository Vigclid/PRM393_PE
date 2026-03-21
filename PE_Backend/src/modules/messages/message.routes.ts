import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";
import { authorize } from "../../middlewares/roleMiddleware";
import { validateMessage } from "../../middlewares/messageValidationMiddleware";
import { messageRateLimiter } from "../../middlewares/rateLimitMiddleware";
import { messageController } from "./message.controller";
import { messageService } from "./message.service";
const router = Router();
const MessageController = new messageController(new messageService());

router.route("/").post(validateMessage, MessageController.create).get(MessageController.getAll);
router
  .route("/me")
  .get(authenticate, MessageController.getMessagesSelf)
  .post(authenticate, messageRateLimiter, validateMessage, MessageController.createMessageByMe);
router.route("/unread-count").get(authenticate, MessageController.getUnreadCount);
router.route("/chat/:chatId").get(authenticate, MessageController.getMessagesByChatId);
router.route("/:messageId/read").put(authenticate, MessageController.markAsRead);
router
  .route("/:id")
  .get(MessageController.getById)
  .put(authenticate, MessageController.update)
  .delete(authenticate, authorize(["Admin"]), MessageController.delete);

export default router;
