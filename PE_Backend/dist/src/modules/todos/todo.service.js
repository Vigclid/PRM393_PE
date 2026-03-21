"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.todoService = void 0;
const base_service_1 = require("../../core/services/base.service");
const todo_model_1 = __importDefault(require("./todo.model"));
class todoService extends base_service_1.GenericService {
    constructor() {
        super(todo_model_1.default);
        this.getMyTodos = async (id) => {
            return todo_model_1.default.find({ userId: id });
        };
        this.toggleMyTodos = async (id) => {
            return todo_model_1.default
                .findById(id)
                .then((doc) => {
                if (doc) {
                    doc.done = !doc.done;
                    return doc.save();
                }
                else {
                    throw new Error("Document not found");
                }
            })
                .catch((error) => {
                console.error(error);
                return null;
            });
        };
    }
}
exports.todoService = todoService;
