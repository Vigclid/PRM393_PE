import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";
import { authorize } from "../../middlewares/roleMiddleware";
import { messageController } from "./message.controller";
import { messageService } from "./message.service";
const router = Router();
const MessageController = new messageController(new messageService());

router.route("/").post(MessageController.create).get(MessageController.getAll);
router
  .route("/me")
  .get(authenticate, MessageController.getMessagesSelf)
  .post(authenticate, MessageController.createMessageByMe);
router
  .route("/:id")
  .get(MessageController.getById)
  .put(authenticate, MessageController.update)
  .delete(authenticate, authorize(["Admin"]), MessageController.delete);

export default router;
