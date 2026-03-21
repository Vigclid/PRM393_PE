"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.roleController = void 0;
const role_model_1 = __importDefault(require("./role.model"));
const base_service_1 = require("../../core/services/base.service");
const base_controller_1 = require("../../core/controllers/base.controller");
const roleService = new base_service_1.GenericService(role_model_1.default);
exports.roleController = new base_controller_1.GenericController(roleService);
