import { Router } from "express";
import v1UserRoutes from "./v1/user.routes";
import v1RoleRoutes from "./v1/roles.routes";
import authRouter from "../modules/auth/auth.route";
import v1Chat from "./v1/chat.routes";
import v1Message from "./v1/message.routes";
import v1Product from "./v1/product.routes";
import v1Cart from "./v1/cart.routes";
import v1Bill from "./v1/bill.routes";
import v1Feedback from "./v1/feedback.routes";
import v1Post from "./v1/post.routes";
import v1Notification from "./v1/notification.routes";

const router = Router();

router.use(authRouter);
router.use(
  "/v1",
  v1UserRoutes,
  v1RoleRoutes,
  v1Chat,
  v1Message,
  v1Product,
  v1Cart,
  v1Bill,
  v1Post,
  v1Feedback,
  v1Notification
);
export default router;
