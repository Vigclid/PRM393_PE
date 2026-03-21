"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.productService = void 0;
const base_service_1 = require("../../core/services/base.service");
const product_model_1 = __importDefault(require("./product.model"));
class productService extends base_service_1.GenericService {
    constructor() {
        super(product_model_1.default);
        this.getProductPopulated = async () => {
            return await product_model_1.default.find().populate("userId");
        };
        this.getMyProducts = async (userId) => {
            return await product_model_1.default.find({ userId }).populate("userId");
        };
    }
}
exports.productService = productService;
