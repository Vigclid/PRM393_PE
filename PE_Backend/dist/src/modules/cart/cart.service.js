"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.cartService = void 0;
const base_service_1 = require("../../core/services/base.service");
const cart_model_1 = __importDefault(require("./cart.model"));
class cartService extends base_service_1.GenericService {
    constructor() {
        super(cart_model_1.default);
        this.getMyCartPopulated = async (_id) => {
            return cart_model_1.default.findOne({ userId: _id }).populate("items.productId");
        };
        this.updateProductToMyCart = async (userId, data) => {
            const cart = await cart_model_1.default.findOne({ userId });
            if (!cart) {
                const cartItem = {
                    productId: data.productId,
                    quantity: 1,
                    priceAtTime: data.priceAtTime,
                };
                return await cart_model_1.default.create({ userId, items: [cartItem] });
            }
            const existingItem = cart.items.find((item) => item.productId.toString() === data.productId.toString());
            if (existingItem) {
                if (data.quantity === 0) {
                    cart.items = cart.items.filter((item) => item.productId.toString() !== data.productId.toString());
                }
                else {
                    existingItem.quantity = data.quantity;
                }
            }
            else {
                cart.items.push({
                    productId: data.productId,
                    quantity: 1,
                    priceAtTime: data.priceAtTime,
                });
            }
            await cart.save();
            return cart;
        };
    }
}
exports.cartService = cartService;
