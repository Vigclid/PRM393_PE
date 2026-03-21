"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const user_routes_1 = __importDefault(require("./v1/user.routes"));
const roles_routes_1 = __importDefault(require("./v1/roles.routes"));
const auth_route_1 = __importDefault(require("../modules/auth/auth.route"));
const chat_routes_1 = __importDefault(require("./v1/chat.routes"));
const message_routes_1 = __importDefault(require("./v1/message.routes"));
const product_routes_1 = __importDefault(require("./v1/product.routes"));
const cart_routes_1 = __importDefault(require("./v1/cart.routes"));
const bill_routes_1 = __importDefault(require("./v1/bill.routes"));
const post_routes_1 = __importDefault(require("./v1/post.routes"));
const router = (0, express_1.Router)();
router.use(auth_route_1.default);
router.use("/v1", user_routes_1.default, roles_routes_1.default, chat_routes_1.default, message_routes_1.default, product_routes_1.default, cart_routes_1.default, bill_routes_1.default, post_routes_1.default);
exports.default = router;
