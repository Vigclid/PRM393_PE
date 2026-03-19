import { Router } from "express";
import todoRouter from "../../modules/todos/todo.routes";

const router = Router();
router.use("/todos", todoRouter);

export default router;
