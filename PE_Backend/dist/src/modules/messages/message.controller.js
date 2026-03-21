"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.messageController = void 0;
const base_controller_1 = require("../../core/controllers/base.controller");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
const clientManager_1 = require("../../sockets/clientManager");
const chat_service_1 = require("../chats/chat.service");
class messageController extends base_controller_1.GenericController {
    constructor(messageService) {
        super(messageService);
        this.getMessagesSelf = async (_req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(_req.headers["authorization"]?.split(" ")[1]);
                const response = await this.MessageService.getMessagesSelf(id);
                res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.createMessageByMe = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                req.body.senderId = id;
                const chat = await new chat_service_1.chatService().checkExistChatUser1AndUser2(req.body.senderId, req.body.receiverId);
                if (chat) {
                    chat.status = 0;
                    await chat.save();
                }
                const message = await this.MessageService.create(req.body);
                (0, clientManager_1.sendToUser)(req.body.receiverId, { type: "MESSAGE", message });
                res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", message));
            }
            catch (error) {
                next(error);
            }
        };
        this.getSelftChatWithUserId = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const response = await this.MessageService.getSelftChatWithUserId(id, req.params.userId);
                res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.MessageService = messageService;
    }
}
exports.messageController = messageController;
