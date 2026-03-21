"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.billController = void 0;
const base_controller_1 = require("../../core/controllers/base.controller");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
const cart_model_1 = __importDefault(require("../cart/cart.model"));
const cart_service_1 = require("../cart/cart.service");
const chat_service_1 = require("../chats/chat.service");
const clientManager_1 = require("../../sockets/clientManager");
const message_service_1 = require("../messages/message.service");
class billController extends base_controller_1.GenericController {
    constructor(billService) {
        super(billService);
        this.checkout = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const cart = await cart_model_1.default.findOne({ userId: id });
                await this.autoSentMessage(req, res, next);
                const response = await this.BillService.checkout(id, cart);
                await cart_model_1.default.findOneAndUpdate({ userId: id }, { items: [], totalPrice: 0 });
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.getRevenueStatistics = async (req, res, next) => {
            try {
                const { type } = req.query;
                const response = await this.BillService.getRevenueStatistics(type);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.autoSentMessage = async (req, _res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const cart = await new cart_service_1.cartService().getMyCartPopulated(id);
                if (!cart || !cart.items.length)
                    return;
                const productOwners = [
                    ...new Set(cart.items.map((item) => item.productId.userId.toString())),
                ];
                const ChatService = new chat_service_1.chatService();
                for (const ownerId of productOwners) {
                    if (ownerId === id)
                        continue;
                    let chat = await ChatService.checkExistChatUser1AndUser2(id, ownerId);
                    if (!chat) {
                        chat = await ChatService.createChatSelf({
                            user1Id: id,
                            user2Id: ownerId,
                            status: 0,
                        });
                        const populatedChat = await ChatService.getChatByIdPopulate(chat._id.toString());
                        (0, clientManager_1.sendToUser)(id, { type: "NEW_CHAT", chat: populatedChat });
                    }
                    else {
                        chat.status = 0;
                        await chat.save();
                    }
                    const messageText = `Xin chào, Cám ơn vì đã mua sản phẩm của tôi! Hãy liên hệ với tôi khi có vấn đề nhé.`;
                    const message = await new message_service_1.messageService().create({
                        senderId: ownerId,
                        receiverId: id,
                        message: messageText,
                    });
                    (0, clientManager_1.sendToUser)(id, { type: "MESSAGE", message });
                }
                return;
            }
            catch (error) {
                next(error);
            }
        };
        this.BillService = billService;
    }
}
exports.billController = billController;
