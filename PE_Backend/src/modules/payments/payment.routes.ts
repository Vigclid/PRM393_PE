import { paymentService } from "./payment.service";
import { PaymentController } from "./payment.controller";
import { Router } from "express";
import { authenticate } from "../../middlewares/authMiddleware";

const router = Router();
const paymentController = new PaymentController(new paymentService());

router.route("/qr").post(authenticate, paymentController.getQrCode);
router.route("/accept").put(authenticate, paymentController.acceptPayment);
export default router;
