"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authMiddleware_1 = require("../../middlewares/authMiddleware");
const chat_controller_1 = require("./chat.controller");
const chat_service_1 = require("./chat.service");
const message_controller_1 = require("../messages/message.controller");
const message_service_1 = require("../messages/message.service");
const router = (0, express_1.Router)();
const ChatController = new chat_controller_1.chatController(new chat_service_1.chatService());
const MessageController = new message_controller_1.messageController(new message_service_1.messageService());
router.route("/").post(ChatController.create).get(ChatController.getAll);
router
    .route("/me")
    .get(authMiddleware_1.authenticate, ChatController.getChatSelf)
    .post(authMiddleware_1.authenticate, ChatController.createChatSelf)
    .put(authMiddleware_1.authenticate, ChatController.markAsReadByUserId);
router.route("/me/other/:id").get(authMiddleware_1.authenticate, ChatController.getChatByMeAndOther);
router
    .route("/:id")
    .get(ChatController.getById)
    .put(authMiddleware_1.authenticate, ChatController.update)
    .delete(authMiddleware_1.authenticate, ChatController.delete);
router.route("/:userId/messages").get(MessageController.getSelftChatWithUserId);
exports.default = router;
