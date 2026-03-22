import { Router } from "express";
import { ReportController } from "./report.controller";
import { authenticate } from "../../middlewares/authMiddleware";
import { authorize } from "../../middlewares/roleMiddleware";

const router = Router();
const reportController = new ReportController();

router
  .route("/")
  .get(authenticate, reportController.getMyReports)
  .post(authenticate, reportController.create);

router.get("/all", authenticate, authorize(["Admin", "Staff"]), reportController.getAllReports);

router.get("/:id", authenticate, reportController.getReportById);

router.post("/:id/reply", authenticate, reportController.addReply);

router.patch("/:id/status", authenticate, authorize(["Admin", "Staff"]), reportController.updateStatus);

export default router;
