import { Router } from "express";
import reportRoutes from "../../modules/report/report.routes";

const router = Router();
router.use("/report", reportRoutes);

export default router;
