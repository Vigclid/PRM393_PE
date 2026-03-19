import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";
import { billController } from "./bill.controller";
import { billService } from "./bill.service";

const router = Router();
const BillController = new billController(new billService());

router.route("/").post(BillController.create).get(BillController.getAll);
router.route("/me").post(authenticate, BillController.checkout);
router.route("/revenue").get(BillController.getRevenueStatistics);
export default router;
