import { Router } from "express";
import { roleController } from "./role.controller";
const router = Router();

router.route("/").post(roleController.create).get(roleController.getAll);

router
  .route("/:id")
  .get(roleController.getById)
  .put(roleController.update)
  .delete(roleController.delete);
export default router;
