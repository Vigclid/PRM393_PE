import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";
import { PostController } from "./post.controller";
import { PostService } from "./post.service";

const router = Router();
const controller = new PostController(new PostService());

router.use(authenticate);

router.route("/").get(controller.getFeed).post(controller.createPost);
router.post("/:postId/reactions", controller.reactToPost);
router.post("/:postId/comments", controller.addComment);
router.post("/:postId/comments/:commentId/replies", controller.addReply);
router.post("/:postId/comments/:commentId/reactions", controller.reactToComment);

export default router;
