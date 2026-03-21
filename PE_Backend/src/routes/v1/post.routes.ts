import { Router } from "express";
import postRoutes from "../../modules/posts/post.routes";

const router = Router();
router.use("/posts", postRoutes);

export default router;
