import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";
import { feedbackController } from "./feedback.controller";
import { feedbackService } from "./feedback.service";

const router = Router()
const FeedbackController = new feedbackController(new feedbackService());

router.route("/")
    .post(authenticate, FeedbackController.createNewFeedback);
    
router.route("/:id")
    .get(authenticate, FeedbackController.getAvarageRatingByProductId);
export default router