import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";
import { authorize } from "../../middlewares/roleMiddleware";
import { notificationController } from "./notification.controller";
import { notificationService } from "./notification.service";
const router = Router();
const NotificationConroller = new notificationController(new notificationService());

router.route("/").post(NotificationConroller.create).get(NotificationConroller.getAll);
router.get("/me", authenticate, NotificationConroller.getNotificationByUserId);
router.put("/me/read", authenticate, NotificationConroller.updateReadNotifications);
router
  .route("/:id")
  .get(NotificationConroller.getById)
  .put(authenticate, NotificationConroller.update)
  .delete(authenticate, authorize(["Admin"]), NotificationConroller.delete);

export default router;
