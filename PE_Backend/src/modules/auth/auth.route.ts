import { Router } from "express";
import { AuthController } from "./auth.controller";

const router = Router();

router.post("/login", AuthController.login);
router.post("/refresh", AuthController.refreshAccessToken);
router.post("/logout", AuthController.logout);
router.post("/google", AuthController.loginWithGoogle);

export default router;
