import { Router } from "express";
import roleRoutes from "../../modules/roles/role.routes";

const router = Router();
router.use("/roles", roleRoutes);

export default router;
