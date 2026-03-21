"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.cartController = void 0;
const base_controller_1 = require("../../core/controllers/base.controller");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
class cartController extends base_controller_1.GenericController {
    constructor(productService) {
        super(productService);
        this.getByMe = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const response = await this.CartService.getMyCartPopulated(id);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.updateProductToMyCart = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const response = await this.CartService.updateProductToMyCart(id, req.body);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.CartService = productService;
    }
}
exports.cartController = cartController;
