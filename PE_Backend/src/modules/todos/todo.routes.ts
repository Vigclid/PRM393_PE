import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";
import { todoController } from "./todo.controller";
import { todoService } from "./todo.service";
const router = Router();
const TodoController = new todoController(new todoService());

router.route("/").post(TodoController.create).get(TodoController.getAll);
router
  .route("/me")
  .get(authenticate, TodoController.getMyTodos)
  .post(authenticate, TodoController.createByMe);
router.route("/toggle/:id").put(authenticate, TodoController.toggleMyTodos);
router
  .route("/:id")
  .get(TodoController.getById)
  .put(authenticate, TodoController.update)
  .delete(authenticate, TodoController.delete);

export default router;
