"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authMiddleware_1 = require("../../middlewares/authMiddleware");
const roleMiddleware_1 = require("../../middlewares/roleMiddleware");
const notification_controller_1 = require("./notification.controller");
const notification_service_1 = require("./notification.service");
const router = (0, express_1.Router)();
const NotificationConroller = new notification_controller_1.notificationController(new notification_service_1.notificationService());
router.route("/").post(NotificationConroller.create).get(NotificationConroller.getAll);
router
    .route("/:id")
    .get(NotificationConroller.getById)
    .put(authMiddleware_1.authenticate, NotificationConroller.update)
    .delete(authMiddleware_1.authenticate, (0, roleMiddleware_1.authorize)(["Admin"]), NotificationConroller.delete);
exports.default = router;
