"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.chatService = void 0;
const base_service_1 = require("../../core/services/base.service");
const chat_model_1 = __importDefault(require("./chat.model"));
class chatService extends base_service_1.GenericService {
    constructor() {
        super(chat_model_1.default);
        this.getChatSelf = async (id) => chat_model_1.default
            .find({ $or: [{ user1Id: id }, { user2Id: id }] })
            .populate("user1Id")
            .populate("user2Id");
        this.createChatSelf = async (data) => chat_model_1.default.create(data);
        this.getChatByIdPopulate = async (id) => chat_model_1.default.findById(id).populate("user1Id").populate("user2Id");
        this.checkExistChatUser1AndUser2 = async (user1Id, user2Id) => chat_model_1.default
            .findOne({
            $or: [
                { user1Id, user2Id },
                { user1Id: user2Id, user2Id: user1Id },
            ],
        })
            .populate("user1Id")
            .populate("user2Id");
        this.markAsReadByUserId = async (id) => await chat_model_1.default.updateMany({ $or: [{ user1Id: id }, { user2Id: id }] }, { $set: { status: 1 } });
    }
}
exports.chatService = chatService;
