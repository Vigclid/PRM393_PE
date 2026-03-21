"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authMiddleware_1 = require("../../middlewares/authMiddleware");
const roleMiddleware_1 = require("../../middlewares/roleMiddleware");
const message_controller_1 = require("./message.controller");
const message_service_1 = require("./message.service");
const router = (0, express_1.Router)();
const MessageController = new message_controller_1.messageController(new message_service_1.messageService());
router.route("/").post(MessageController.create).get(MessageController.getAll);
router
    .route("/me")
    .get(authMiddleware_1.authenticate, MessageController.getMessagesSelf)
    .post(authMiddleware_1.authenticate, MessageController.createMessageByMe);
router
    .route("/:id")
    .get(MessageController.getById)
    .put(authMiddleware_1.authenticate, MessageController.update)
    .delete(authMiddleware_1.authenticate, (0, roleMiddleware_1.authorize)(["Admin"]), MessageController.delete);
exports.default = router;
