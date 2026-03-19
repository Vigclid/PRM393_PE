import { commentService } from "./comment.service";
import { CommentController } from "./comment.controller";
import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";

const router = Router();

const commentController = new CommentController(new commentService());

router.route("/").get(commentController.getAll).post(authenticate, commentController.saveComment);

router.route("/:artworkId").get(commentController.getCommentByArtworkId);

export default router;
