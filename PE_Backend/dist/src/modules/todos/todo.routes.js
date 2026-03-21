"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authMiddleware_1 = require("../../middlewares/authMiddleware");
const todo_controller_1 = require("./todo.controller");
const todo_service_1 = require("./todo.service");
const router = (0, express_1.Router)();
const TodoController = new todo_controller_1.todoController(new todo_service_1.todoService());
router.route("/").post(TodoController.create).get(TodoController.getAll);
router
    .route("/me")
    .get(authMiddleware_1.authenticate, TodoController.getMyTodos)
    .post(authMiddleware_1.authenticate, TodoController.createByMe);
router.route("/toggle/:id").put(authMiddleware_1.authenticate, TodoController.toggleMyTodos);
router
    .route("/:id")
    .get(TodoController.getById)
    .put(authMiddleware_1.authenticate, TodoController.update)
    .delete(authMiddleware_1.authenticate, TodoController.delete);
exports.default = router;
