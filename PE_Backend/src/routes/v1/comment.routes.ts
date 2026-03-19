import { Router } from "express";
import commentRouter from "../../modules/comments/comment.routes";

const router = Router();
router.use("/comments", commentRouter);

export default router;
