import { Router } from "express";
import notificationRoute from "../../modules/notifications/notification.routes";
const route = Router();
route.use("/notifications", notificationRoute);
export default route;
