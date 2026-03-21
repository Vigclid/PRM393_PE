"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const cart_controller_1 = require("./cart.controller");
const cart_service_1 = require("./cart.service");
const authMiddleware_1 = require("../../middlewares/authMiddleware");
const router = (0, express_1.Router)();
const CartController = new cart_controller_1.cartController(new cart_service_1.cartService());
router.route("/").post(CartController.create).get(CartController.getAll);
router
    .route("/me")
    .get(authMiddleware_1.authenticate, CartController.getByMe)
    .post(authMiddleware_1.authenticate, CartController.updateProductToMyCart);
exports.default = router;
