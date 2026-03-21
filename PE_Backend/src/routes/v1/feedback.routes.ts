import { Router } from "express";
import feedbackRoute from "../../modules/feedback/feedback.routes";

const router = Router();
router.use("/feedbacks", feedbackRoute);
export default router;