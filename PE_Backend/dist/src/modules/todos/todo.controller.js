"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.todoController = void 0;
const base_controller_1 = require("../../core/controllers/base.controller");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const ApiResponseWrapper_1 = require("../../interfaces/wrapper/ApiResponseWrapper");
class todoController extends base_controller_1.GenericController {
    constructor(todoService) {
        super(todoService);
        this.getMyTodos = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                const response = await this.todoService.getMyTodos(id);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Fetched successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.createByMe = async (req, res, next) => {
            try {
                const { id } = jsonwebtoken_1.default.decode(req.headers["authorization"]?.split(" ")[1]);
                req.body.userId = id;
                const response = await this.todoService.create(req.body);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Created successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.toggleMyTodos = async (req, res, next) => {
            try {
                const id = req.params.id;
                const response = await this.todoService.toggleMyTodos(id);
                res.json((0, ApiResponseWrapper_1.responseWrapper)("success", "Toggled successfully", response));
            }
            catch (error) {
                next(error);
            }
        };
        this.todoService = todoService;
    }
}
exports.todoController = todoController;
