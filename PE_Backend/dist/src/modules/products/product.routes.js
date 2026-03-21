"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const product_controller_1 = require("./product.controller");
const product_service_1 = require("./product.service");
const authMiddleware_1 = require("../../middlewares/authMiddleware");
const router = (0, express_1.Router)();
const ProductController = new product_controller_1.productController(new product_service_1.productService());
router.route("/").post(ProductController.create).get(ProductController.getAll);
router
    .route("/me")
    .post(authMiddleware_1.authenticate, ProductController.createProductByMe)
    .get(authMiddleware_1.authenticate, ProductController.getMyProducts);
router.route("/populated").get(ProductController.getProductPopulated);
router
    .route("/:id")
    .put(authMiddleware_1.authenticate, ProductController.updateProduct)
    .delete(authMiddleware_1.authenticate, ProductController.deleteProduct);
// SELF CHAT
exports.default = router;
