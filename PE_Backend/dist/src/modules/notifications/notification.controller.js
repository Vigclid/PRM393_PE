"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.notificationController = void 0;
const base_controller_1 = require("../../core/controllers/base.controller");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
class notificationController extends base_controller_1.GenericController {
    constructor(notificationService) {
        super(notificationService);
        this.getNotificationByUserId = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const response = await this.notificationService.getNotificationsByUserId(id);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.updateReadNotifications = async (req, res) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                await this.notificationService.setReadNotificationByUserId(id);
                return res.status(200).json((0, ApiResponseWrapper_1.responseWrapper)("success", "Notifications updated successfully"));
            }
            catch (error) {
                res.status(500).json((0, ApiResponseWrapper_1.responseWrapper)("error", "Internal Server Error"));
            }
        };
        this.notificationService = notificationService;
    }
}
exports.notificationController = notificationController;
