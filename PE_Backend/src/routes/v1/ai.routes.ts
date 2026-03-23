import { Router } from "express";
import aiRoutes from "../../modules/ai/ai.routes";

const router = Router();

router.use("/ai", aiRoutes);

export default router;