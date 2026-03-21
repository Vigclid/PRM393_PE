"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const cart_routes_1 = __importDefault(require("../../modules/cart/cart.routes"));
const route = (0, express_1.Router)();
route.use("/carts", cart_routes_1.default);
exports.default = route;
