"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.chatController = void 0;
const base_controller_1 = require("../../core/controllers/base.controller");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
const clientManager_1 = require("../../sockets/clientManager");
class chatController extends base_controller_1.GenericController {
    constructor(chatService) {
        super(chatService);
        this.getChatSelf = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const response = await this.ChatService.getChatSelf(id);
                res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.createChatSelf = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                req.body.user1Id = id;
                const exist = (await this.ChatService.checkExistChatUser1AndUser2(req.body.user1Id, req.body.user2Id));
                if (exist) {
                    exist.status = 0;
                    await exist.save();
                    (0, clientManager_1.sendToUser)(id, { type: "UPDATE_CHAT", chat: exist });
                    return res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Chat already exist"));
                }
                const response = (await this.ChatService.createChatSelf(req.body));
                const chat = await this.ChatService.getChatByIdPopulate(response._id);
                (0, clientManager_1.sendToUser)(id, { type: "NEW_CHAT", chat: chat });
                res.status(201).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Created successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.markAsReadByUserId = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                await this.ChatService.markAsReadByUserId(id);
                res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Mark as read successfully"));
            }
            catch (error) {
                next(error);
            }
        };
        this.getChatByMeAndOther = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const response = await this.ChatService.checkExistChatUser1AndUser2(id, req.params.id);
                res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.ChatService = chatService;
    }
}
exports.chatController = chatController;
