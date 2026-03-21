"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const notification_routes_1 = __importDefault(require("../../modules/notifications/notification.routes"));
const route = (0, express_1.Router)();
route.use("/notifications", notification_routes_1.default);
exports.default = route;
