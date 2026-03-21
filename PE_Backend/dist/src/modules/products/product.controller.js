"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.productController = void 0;
const base_controller_1 = require("../../core/controllers/base.controller");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
const imageUtils_1 = require("../../utils/imageUtils");
class productController extends base_controller_1.GenericController {
    constructor(productService) {
        super(productService);
        this.createProductByMe = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                req.body.userId = id;
                req.body.imageUrl = (await (0, imageUtils_1.uploadImage)(req.body.image, 3, false)).image.secure_url;
                const response = await this.ProductService.create(req.body);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Created successfully", response));
            }
            catch (error) {
                console.log(error);
                next(error);
            }
        };
        this.getProductPopulated = async (_req, res, next) => {
            try {
                const response = await this.ProductService.getProductPopulated();
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.getMyProducts = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const response = await this.ProductService.getMyProducts(id);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.updateProduct = async (req, res, next) => {
            try {
                const product = await this.ProductService.getById(req.params.id);
                if (product?.imageUrl !== req.body.image) {
                    await (0, imageUtils_1.deleteImageByUrl)(product?.imageUrl);
                    req.body.imageUrl = (await (0, imageUtils_1.uploadImage)(req.body.image, 3, false)).image.secure_url;
                }
                const response = await this.ProductService.update(req.params.id, req.body);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Updated successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.deleteProduct = async (req, res, next) => {
            try {
                const product = await this.ProductService.getById(req.params.id);
                if (product?.imageUrl)
                    await (0, imageUtils_1.deleteImageByUrl)(product?.imageUrl);
                const response = await this.ProductService.delete(req.params.id);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Deleted successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.ProductService = productService;
    }
}
exports.productController = productController;
