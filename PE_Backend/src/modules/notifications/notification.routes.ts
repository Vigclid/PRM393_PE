import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";
import { authorize } from "../../middlewares/roleMiddleware";
import { notificationController } from "./notification.controller";
import { notificationService } from "./notification.service";
const router = Router();
const NotificationConroller = new notificationController(new notificationService());

router.route("/").post(NotificationConroller.create).get(NotificationConroller.getAll);
router
  .route("/:id")
  .get(NotificationConroller.getById)
  .put(authenticate, NotificationConroller.update)
  .delete(authenticate, authorize(["Admin"]), NotificationConroller.delete);

export default router;
