"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.messageService = void 0;
const base_service_1 = require("../../core/services/base.service");
const message_model_1 = __importDefault(require("./message.model"));
class messageService extends base_service_1.GenericService {
    constructor() {
        super(message_model_1.default);
        this.getMessagesSelf = async (id) => {
            return message_model_1.default.find({ $or: [{ senderId: id }, { receiverId: id }] });
        };
        this.getSelftChatWithUserId = async (user1Id, user2Id) => {
            return message_model_1.default
                .find({
                $or: [
                    { senderId: user1Id, receiverId: user2Id },
                    { senderId: user2Id, receiverId: user1Id },
                ],
            })
                .populate("senderId")
                .populate("receiverId");
        };
    }
}
exports.messageService = messageService;
