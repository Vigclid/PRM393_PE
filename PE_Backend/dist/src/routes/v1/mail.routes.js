"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const mail_routes_1 = __importDefault(require("../../modules/mail/mail.routes"));
const route = (0, express_1.Router)();
route.use("/mail", mail_routes_1.default);
exports.default = route;
